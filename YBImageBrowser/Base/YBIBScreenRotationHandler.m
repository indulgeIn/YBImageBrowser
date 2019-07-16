//
//  YBIBScreenRotationHandler.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/8.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBScreenRotationHandler.h"
#import "YBIBUtilities.h"
#import "YBIBCellProtocol.h"
#import "YBImageBrowser+Internal.h"

BOOL YBIBValidDeviceOrientation(UIDeviceOrientation orientation) {
    static NSSet *validSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        validSet = [NSSet setWithObjects:@(UIDeviceOrientationPortrait), @(UIDeviceOrientationPortraitUpsideDown), @(UIDeviceOrientationLandscapeLeft), @(UIDeviceOrientationLandscapeRight), nil];
    });
    return [validSet containsObject:@(orientation)];
}

CGFloat YBIBRotationAngle(UIDeviceOrientation startOrientation, UIDeviceOrientation endOrientation) {
    static NSDictionary<NSNumber*, NSNumber*> *angleMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        angleMap = @{@(UIDeviceOrientationPortrait):@(0), @(UIDeviceOrientationPortraitUpsideDown):@(M_PI), @(UIDeviceOrientationLandscapeLeft):@(M_PI_2), @(UIDeviceOrientationLandscapeRight): @(-M_PI_2)};
    });
    NSNumber *start = angleMap[@(startOrientation)], *end = angleMap[@(endOrientation)];
    CGFloat res = CGFLOAT_IS_DOUBLE ? end.doubleValue - start.doubleValue : end.floatValue - start.floatValue;
    if (ABS(res) > M_PI) {
        return res > 0 ? res - M_PI * 2 : M_PI * 2 + res;
    }
    return res;
}


static NSUInteger const kMaskNull = 10000;

@interface YBIBScreenRotationHandler ()
@property (nonatomic, assign) BOOL rotating;
@property (nonatomic, assign) UIDeviceOrientation currentOrientation;
@end

@implementation YBIBScreenRotationHandler {
    __weak YBImageBrowser *_browser;
    CGSize _verticalContainerSize;
    CGSize _horizontalContainerSize;
    NSInteger _recordPage;
}

#pragma mark - life cycle

- (void)dealloc {
    [self clear];
}

- (instancetype)initWithBrowser:(YBImageBrowser *)browser {
    if (self = [super init]) {
        _browser = browser;
        _rotating = NO;
        _supportedOrientations = UIInterfaceOrientationMaskAllButUpsideDown;
        _rotationDuration = 0.25;
    }
    return self;
}

#pragma mark - public

- (void)startObserveStatusBarOrientation {
    self.currentOrientation = (UIDeviceOrientation)UIApplication.sharedApplication.statusBarOrientation;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangedStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillChangeStatusBarOrientationNotification:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)startObserveDeviceOrientation {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)clear {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configContainerSize:(CGSize)size {
    if (UIDeviceOrientationIsLandscape(self.currentOrientation)) {
        // Now is horizontal.
        _verticalContainerSize = CGSizeMake(size.height, size.width);
        _horizontalContainerSize = size;
    } else {
        // Now is vertical.
        _verticalContainerSize = size;
        _horizontalContainerSize = CGSizeMake(size.height, size.width);
    }
}

- (CGSize)containerSizeWithOrientation:(UIDeviceOrientation)orientation {
    return UIDeviceOrientationIsLandscape(orientation) ? _horizontalContainerSize : _verticalContainerSize;
}

#pragma mark - private

- (BOOL)supportedOfOrientation:(UIDeviceOrientation)orientation {
    if (!YBIBValidDeviceOrientation(orientation)) return NO;
    NSMutableSet *set = [NSMutableSet set];
    if (_supportedOrientations & UIInterfaceOrientationMaskPortrait) [set addObject:@(UIDeviceOrientationPortrait)];
    if (_supportedOrientations & UIInterfaceOrientationMaskPortraitUpsideDown) [set addObject:@(UIDeviceOrientationPortraitUpsideDown)];
    if (_supportedOrientations & UIInterfaceOrientationMaskLandscapeRight) [set addObject:@(UIDeviceOrientationLandscapeLeft)];
    if (_supportedOrientations & UIInterfaceOrientationMaskLandscapeLeft) [set addObject:@(UIDeviceOrientationLandscapeRight)];
    return [set containsObject:@(orientation)];
}

- (BOOL)supportedOnlyOneSystemOrientation {
    UIInterfaceOrientationMask mask = [self supportSystemOrientationMask];
    return mask == (mask & (-mask));
}

- (void)orientationWillChangeWithExpectOrientation:(UIDeviceOrientation)orientation centerCell:(UICollectionViewCell<YBIBCellProtocol> *)centerCell {
    if ([centerCell respondsToSelector:@selector(yb_orientationWillChangeWithExpectOrientation:)]) {
        [centerCell yb_orientationWillChangeWithExpectOrientation:orientation];
    }
    for (id<YBIBToolViewHandler> handler in _browser.toolViewHandlers) {
        if ([handler respondsToSelector:@selector(yb_orientationWillChangeWithExpectOrientation:)]) {
            [handler yb_orientationWillChangeWithExpectOrientation:orientation];
        }
    }
}

- (void)orientationChangeAnimationWithExpectOrientation:(UIDeviceOrientation)orientation centerCell:(UICollectionViewCell<YBIBCellProtocol> *)centerCell {
    if ([centerCell respondsToSelector:@selector(yb_orientationChangeAnimationWithExpectOrientation:)]) {
        [centerCell yb_orientationChangeAnimationWithExpectOrientation:orientation];
        [centerCell layoutIfNeeded];    // Compatible with autolayout.
    }
    for (id<YBIBToolViewHandler> handler in _browser.toolViewHandlers) {
        if ([handler respondsToSelector:@selector(yb_orientationChangeAnimationWithExpectOrientation:)]) {
            [handler yb_orientationChangeAnimationWithExpectOrientation:orientation];
        }
    }
}

- (void)orientationDidChangedWithOrientation:(UIDeviceOrientation)orientation centerCell:(UICollectionViewCell<YBIBCellProtocol> *)centerCell {
    if ([centerCell respondsToSelector:@selector(yb_orientationDidChangedWithOrientation:)]) {
        [centerCell yb_orientationDidChangedWithOrientation:orientation];
    }
    for (id<YBIBToolViewHandler> handler in _browser.toolViewHandlers) {
        if ([handler respondsToSelector:@selector(yb_orientationDidChangedWithOrientation:)]) {
            [handler yb_orientationDidChangedWithOrientation:orientation];
        }
    }
}

#pragma mark - event

- (void)deviceOrientationDidChangeNotification:(NSNotification *)note {
    if (![self supportedOnlyOneSystemOrientation]) return;
    if (_browser.isTransitioning || self.rotating) return;
    
    UIDeviceOrientation expectOrientation = [UIDevice currentDevice].orientation;
    if (expectOrientation == self.currentOrientation || ![self supportedOfOrientation:expectOrientation]) return;
    
    self.rotating = YES;
    
    // Align.
    [_browser.collectionView scrollToPage:_browser.currentPage];
    // Record current page number before transforming.
    NSInteger currentPage = _browser.currentPage;
    
    UIDeviceOrientation statusBarOrientation = (UIDeviceOrientation)UIApplication.sharedApplication.statusBarOrientation;
    CGFloat angleStatusBarToExpect = YBIBRotationAngle(statusBarOrientation, expectOrientation);
    CGFloat angleCurrentToExpect = YBIBRotationAngle(_currentOrientation, expectOrientation);
    CGRect expectBounds = (CGRect){CGPointZero, [self containerSizeWithOrientation:expectOrientation]};
    UICollectionViewCell<YBIBCellProtocol> *centerCell = (UICollectionViewCell<YBIBCellProtocol> *)self->_browser.collectionView.centerCell;
    // Animate smoothly if bigger rotation angle.
    NSTimeInterval duration = self.rotationDuration * (ABS(angleCurrentToExpect) > M_PI_2 ? 2 : 1);

    // 'collectionView' transformation.
    self->_browser.collectionView.bounds = expectBounds;
    self->_browser.collectionView.transform = CGAffineTransformMakeRotation(angleStatusBarToExpect);
    centerCell.contentView.transform = CGAffineTransformMakeRotation(-angleCurrentToExpect);
    
    // Reset to prevent the page number change after transforming.
    [self->_browser.collectionView scrollToPage:currentPage];
    
    [self orientationWillChangeWithExpectOrientation:expectOrientation centerCell:centerCell];
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        // Maybe the internal UI need to transform.
        [self orientationChangeAnimationWithExpectOrientation:expectOrientation centerCell:centerCell];
        
        centerCell.contentView.bounds = expectBounds;
        centerCell.contentView.transform = CGAffineTransformIdentity;
        
        self->_browser.containerView.bounds = expectBounds;
        self->_browser.containerView.transform = CGAffineTransformMakeRotation(angleStatusBarToExpect);
        
    } completion:^(BOOL finished) {
        self.currentOrientation = expectOrientation;
        self.rotating = NO;
        
        [self orientationDidChangedWithOrientation:expectOrientation centerCell:centerCell];
    }];
}

- (void)applicationWillChangeStatusBarOrientationNotification:(NSNotification *)noti {
    if ([self supportedOnlyOneSystemOrientation]) return;
    
    self.rotating = YES;
    // Record current page number before transforming.
    _recordPage = _browser.currentPage;
    
    UICollectionViewCell<YBIBCellProtocol> *centerCell = (UICollectionViewCell<YBIBCellProtocol> *)self->_browser.collectionView.centerCell;
    UIDeviceOrientation expectOrientation = ((NSNumber *)noti.userInfo[UIApplicationStatusBarOrientationUserInfoKey]).integerValue;
    [self orientationWillChangeWithExpectOrientation:expectOrientation centerCell:centerCell];
}

- (void)applicationDidChangedStatusBarOrientationNotification:(NSNotification *)noti {
    if ([self supportedOnlyOneSystemOrientation]) return;
    
    UIDeviceOrientation expectOrientation = (UIDeviceOrientation)UIApplication.sharedApplication.statusBarOrientation;
    UICollectionViewCell<YBIBCellProtocol> *centerCell = (UICollectionViewCell<YBIBCellProtocol> *)self->_browser.collectionView.centerCell;
    
    [self orientationChangeAnimationWithExpectOrientation:expectOrientation centerCell:centerCell];
    
    CGRect expectBounds = (CGRect){CGPointZero, [self containerSizeWithOrientation:expectOrientation]};
    self->_browser.collectionView.layout.itemSize = expectBounds.size;
    
    // Reset to prevent the page number change after transforming.
    [_browser.collectionView scrollToPage:_recordPage];
    
    self.currentOrientation = expectOrientation;
    self.rotating = NO;
    
    [self orientationDidChangedWithOrientation:expectOrientation centerCell:centerCell];
}

#pragma mark - getters & setters

- (void)setRotating:(BOOL)rotating {
    _rotating = rotating;
    _browser.containerView.userInteractionEnabled = !rotating;
    _browser.collectionView.userInteractionEnabled = !rotating;
    _browser.collectionView.panGestureRecognizer.enabled = !rotating;
}

#pragma mark - calculate supported orientation of system

- (UIInterfaceOrientationMask)supportSystemOrientationMask {
    UIInterfaceOrientationMask limitMask = 0;
    // IphoneX series do not support UIInterfaceOrientationMaskPortraitUpsideDown, except selector '-application:supportedInterfaceOrientationsForWindow:' of '[UIApplication sharedApplication].delegate' return 0. Maybe it is BUG of Apple.
    BOOL ignoreUpsideDownIfIphoneX = YES;
    UIInterfaceOrientationMask delegateMask = [self maskOfApplicationDelegate];
    if (delegateMask != kMaskNull) {
        if (delegateMask == 0) {
            // Apple do.
            limitMask = UIInterfaceOrientationMaskAll;
            ignoreUpsideDownIfIphoneX = NO;
        } else {
            limitMask = delegateMask;
        }
    } else {
        // Lower priority.
        limitMask = [self maskOfInfoPlist];
    }
    
    UIInterfaceOrientationMask supportMask = limitMask & [self maskOfViewController];
    
    if (ignoreUpsideDownIfIphoneX && YBIBIsIphoneXSeries() && (supportMask & UIInterfaceOrientationMaskPortraitUpsideDown)) {
        supportMask ^= UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    return supportMask;
}

- (UIInterfaceOrientationMask)maskOfInfoPlist {
    // 'Info.plist' will not change in a process.
    static UIInterfaceOrientationMask mask = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        NSArray *array = dict[@"UISupportedInterfaceOrientations"];
        NSSet *set = [NSSet setWithArray:array];
        if ([set containsObject:@"UIInterfaceOrientationPortrait"]) mask |= UIInterfaceOrientationMaskPortrait;
        if ([set containsObject:@"UIInterfaceOrientationLandscapeRight"]) mask |= UIInterfaceOrientationMaskLandscapeRight;
        if ([set containsObject:@"UIInterfaceOrientationLandscapeLeft"]) mask |= UIInterfaceOrientationMaskLandscapeLeft;
        if ([set containsObject:@"UIInterfaceOrientationPortraitUpsideDown"]) mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    });
    return mask == 0 ? kMaskNull : mask;
}

- (UIInterfaceOrientationMask)maskOfApplicationDelegate {
    UIInterfaceOrientationMask mask = kMaskNull;
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    if ([delegate respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)]) {
        mask = [delegate application:[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:_browser.window];
    }
    return mask;
}

- (UIInterfaceOrientationMask)maskOfViewController {
    UIInterfaceOrientationMask mask = kMaskNull;
    
    // Find the UIViewController whitch 'browser' followed.
    UIViewController *target = nil;
    id next = _browser;
    while (next) {
        if ([next isKindOfClass:UIViewController.self]) {
            target = next;
            break;
        }
        if ([next isKindOfClass:UIWindow.self]) {
            target = YBIBTopControllerByWindow(next);
            break;
        }
        next = [next nextResponder];
    }
    
    // Cover directly.
    if (target.tabBarController) {
        mask = target.tabBarController.shouldAutorotate ? target.tabBarController.supportedInterfaceOrientations : 0;
    } else if (target.navigationController) {
        mask = target.navigationController.shouldAutorotate ? target.navigationController.supportedInterfaceOrientations : 0;
    } else {
        mask = target.shouldAutorotate ? target.supportedInterfaceOrientations : 0;
    }
    return mask;
}

@end
