//
//  YBIBVideoCell.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/10.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBVideoCell.h"
#import "YBIBVideoData.h"
#import "YBIBVideoData+Internal.h"
#import "YBIBCopywriter.h"
#import "YBIBIconManager.h"
#import <objc/runtime.h>
#import "YBIBVideoCell+Internal.h"

@interface NSObject (YBIBVideoPlayingRecord)
- (void)ybib_videoPlayingAdd:(NSObject *)obj;
- (void)ybib_videoPlayingRemove:(NSObject *)obj;
- (BOOL)ybib_noVideoPlaying;
@end
@implementation NSObject (YBIBVideoPlayingRecord)
- (NSMutableSet *)ybib_videoPlayingSet {
    static void *kRecordKey = &kRecordKey;
    NSMutableSet *set = objc_getAssociatedObject(self, kRecordKey);
    if (!set) {
        set = [NSMutableSet set];
        objc_setAssociatedObject(self, kRecordKey, set, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return set;
}
- (void)ybib_videoPlayingAdd:(NSObject *)obj {
    [[self ybib_videoPlayingSet] addObject:[NSString stringWithFormat:@"%p", obj]];
}
- (void)ybib_videoPlayingRemove:(NSObject *)obj {
    [[self ybib_videoPlayingSet] removeObject:[NSString stringWithFormat:@"%p", obj]];
}
- (BOOL)ybib_noVideoPlaying {
    return [self ybib_videoPlayingSet].count == 0;
}
@end


@interface YBIBVideoCell () <YBIBVideoDataDelegate, YBIBVideoViewDelegate, UIGestureRecognizerDelegate>
@end

@implementation YBIBVideoCell {
    CGPoint _interactStartPoint;
    BOOL _interacting;
}

#pragma mark - life cycle

- (void)dealloc {
    [self.yb_backView ybib_videoPlayingRemove:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initValue];
        [self.contentView addSubview:self.videoView];
        [self addGesture];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.videoView.frame = self.bounds;
}

- (void)initValue {
    _interactStartPoint = CGPointZero;
    _interacting = NO;
}

- (void)prepareForReuse {
    ((YBIBVideoData *)self.yb_cellData).delegate = nil;
    self.videoView.thumbImageView.image = nil;
    [self hideAuxiliaryView];
    [self.videoView reset];
    self.videoView.asset = nil;
    [super prepareForReuse];
}

#pragma mark - private

- (void)hideAuxiliaryView {
    [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
    [self.yb_auxiliaryViewHandler() yb_hideToastWithContainer:self];
}

- (void)updateImageLayoutWithOrientation:(UIDeviceOrientation)orientation previousImageSize:(CGSize)previousImageSize {
    YBIBVideoData *data = self.yb_cellData;
    UIImage *image = self.videoView.thumbImageView.image;
    CGSize imageSize = image.size;
    
    CGRect imageViewFrame = [data yb_imageViewFrameWithContainerSize:self.yb_containerSize(orientation) imageSize:imageSize orientation:orientation];
    
    CGFloat scale;
    if (previousImageSize.width > 0 && previousImageSize.height > 0) {
        scale = imageSize.width / imageSize.height - previousImageSize.width / previousImageSize.height;
    } else {
        scale = 0;
    }
    // '0.001' is admissible error.
    if (ABS(scale) <= 0.001) {
        self.videoView.thumbImageView.frame = imageViewFrame;
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            self.videoView.thumbImageView.frame = imageViewFrame;
        }];
    }
}

- (void)hideBrowser {
    ((YBIBVideoData *)self.yb_cellData).delegate = nil;
    self.videoView.thumbImageView.hidden = NO;
    self.videoView.autoPlayCount = 0;
    [self.videoView reset];
    [self.videoView hideToolBar:YES];
    [self.videoView hidePlayButton];
    self.yb_hideBrowser();
    _interacting = NO;
}

- (void)hideToolViews:(BOOL)hide {
    if (hide) {
        self.yb_hideToolViews(YES);
    } else {
        if ([self.yb_backView ybib_noVideoPlaying]) {
            self.yb_hideToolViews(NO);
        }
    }
}

#pragma mark - <YBIBCellProtocol>

@synthesize yb_currentOrientation = _yb_currentOrientation;
@synthesize yb_containerSize = _yb_containerSize;
@synthesize yb_backView = _yb_backView;
@synthesize yb_collectionView = _yb_collectionView;
@synthesize yb_isTransitioning = _yb_isTransitioning;
@synthesize yb_auxiliaryViewHandler = _yb_auxiliaryViewHandler;
@synthesize yb_hideStatusBar = _yb_hideStatusBar;
@synthesize yb_hideBrowser = _yb_hideBrowser;
@synthesize yb_hideToolViews = _yb_hideToolViews;
@synthesize yb_cellData = _yb_cellData;
@synthesize yb_currentPage = _yb_currentPage;
@synthesize yb_selfPage = _yb_selfPage;
@synthesize yb_cellIsInCenter = _yb_cellIsInCenter;
@synthesize yb_isRotating = _yb_isRotating;

- (void)setYb_cellData:(id<YBIBDataProtocol>)yb_cellData {
    _yb_cellData = yb_cellData;
    YBIBVideoData *data = (YBIBVideoData *)yb_cellData;
    data.delegate = self;
    
    UIDeviceOrientation orientation = self.yb_currentOrientation();
    CGSize containerSize = self.yb_containerSize(orientation);
    [self.videoView updateLayoutWithExpectOrientation:orientation containerSize:containerSize];
    self.videoView.autoPlayCount = data.autoPlayCount;
    self.videoView.topBar.cancelButton.hidden = data.shouldHideForkButton;
}

- (void)yb_orientationWillChangeWithExpectOrientation:(UIDeviceOrientation)orientation {
    if (_interacting) [self restoreGestureInteractionWithDuration:0];
}

- (void)yb_orientationChangeAnimationWithExpectOrientation:(UIDeviceOrientation)orientation {
    [self updateImageLayoutWithOrientation:orientation previousImageSize:self.videoView.thumbImageView.image.size];
    CGSize containerSize = self.yb_containerSize(orientation);
    [self.videoView updateLayoutWithExpectOrientation:orientation containerSize:containerSize];
}

- (UIView *)yb_foregroundView {
    return self.videoView.thumbImageView;
}

- (void)yb_pageChanged {
    if (self.yb_currentPage() != self.yb_selfPage()) {
        [self.videoView reset];
        [self hideToolViews:NO];
        [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
        if (_interacting) [self restoreGestureInteractionWithDuration:0];
        self.videoView.needAutoPlay = NO;
    } else {
        self.videoView.needAutoPlay = YES;
    }
}

#pragma mark - <YBIBVideoDataDelegate>

- (void)yb_startLoadingAVAssetFromPHAssetForData:(YBIBVideoData *)data {}

- (void)yb_finishLoadingAVAssetFromPHAssetForData:(YBIBVideoData *)data {}

- (void)yb_startLoadingFirstFrameForData:(YBIBVideoData *)data {
    if (!self.videoView.thumbImageView.image) {
        [self.yb_auxiliaryViewHandler() yb_showLoadingWithContainer:self];
    }
}

- (void)yb_finishLoadingFirstFrameForData:(YBIBVideoData *)data {
    [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
}

- (void)yb_videoData:(YBIBVideoData *)data downloadingWithProgress:(CGFloat)progress {
    [self.yb_auxiliaryViewHandler() yb_showLoadingWithContainer:self progress:progress];
}

- (void)yb_finishDownloadingForData:(YBIBVideoData *)data {
    [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
}

- (void)yb_videoData:(YBIBVideoData *)data readyForAVAsset:(AVAsset *)asset {
    self.videoView.asset = asset;
}

- (void)yb_videoData:(YBIBVideoData *)data readyForThumbImage:(UIImage *)image {
    if (!self.videoView.isPlaying) {
        self.videoView.thumbImageView.hidden = NO;
    }
    
    if (!self.videoView.thumbImageView.image) {
        CGSize previousSize = self.videoView.thumbImageView.image.size;
        self.videoView.thumbImageView.image = image;
        [self updateImageLayoutWithOrientation:self.yb_currentOrientation() previousImageSize:previousSize];
    }
}

- (void)yb_videoIsInvalidForData:(YBIBVideoData *)data {
    [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
    NSString *imageIsInvalid = [YBIBCopywriter sharedCopywriter].videoIsInvalid;
    if (self.videoView.thumbImageView.image) {
        [self.yb_auxiliaryViewHandler() yb_showIncorrectToastWithContainer:self text:imageIsInvalid];
    } else {
        [self.yb_auxiliaryViewHandler() yb_showLoadingWithContainer:self text:imageIsInvalid];
    }
}

#pragma mark - <YBIBVideoViewDelegate>

- (BOOL)yb_isFreezingForVideoView:(YBIBVideoView *)view {
    return self.yb_isTransitioning();
}

- (void)yb_preparePlayForVideoView:(YBIBVideoView *)view {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!view.isPlaying && !view.isPlayFailed && self.yb_selfPage() == self.yb_currentPage()) {
            [self.yb_auxiliaryViewHandler() yb_showLoadingWithContainer:self];
        }
    });
}

- (void)yb_startPlayForVideoView:(YBIBVideoView *)view {
    self.videoView.thumbImageView.hidden = YES;
    [self.yb_backView ybib_videoPlayingAdd:self];
    [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
    [self hideToolViews:YES];
}

- (void)yb_didPlayToEndTimeForVideoView:(YBIBVideoView *)view {
    YBIBVideoData *data = (YBIBVideoData *)self.yb_cellData;
    if (data.repeatPlayCount == NSUIntegerMax) {
        [view preparPlay];
    } else if (data.repeatPlayCount > 0) {
        --data.repeatPlayCount;
        [view preparPlay];
    } else {
        [self hideToolViews:NO];
    }
}

- (void)yb_finishPlayForVideoView:(YBIBVideoView *)view {
    [self.yb_backView ybib_videoPlayingRemove:self];
    [self hideToolViews:NO];
}

- (void)yb_playFailedForVideoView:(YBIBVideoView *)view {
    [self.yb_auxiliaryViewHandler() yb_hideLoadingWithContainer:self];
    [self.yb_auxiliaryViewHandler() yb_showIncorrectToastWithContainer:self text:YBIBCopywriter.sharedCopywriter.videoError];
}

- (void)yb_respondsToTapGestureForVideoView:(YBIBVideoView *)view {
    if (self.yb_isRotating()) return;
    
    YBIBVideoData *data = self.yb_cellData;
    if (data.singleTouchBlock) {
        data.singleTouchBlock(data);
    } else {
        [self hideBrowser];
    }
}

- (void)yb_cancelledForVideoView:(YBIBVideoView *)view {
    if (self.yb_isRotating()) return;
    
    [self hideBrowser];
}

- (CGSize)yb_containerSizeForVideoView:(YBIBVideoView *)view {
    return self.yb_containerSize(self.yb_currentOrientation());
}

- (void)yb_autoPlayCountChanged:(NSUInteger)count {
    YBIBVideoData *data = (YBIBVideoData *)self.yb_cellData;
    data.autoPlayCount = count;
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - gesture

- (void)addGesture {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToPanGesture:)];
    panGesture.cancelsTouchesInView = NO;
    panGesture.delegate = self;
    [self.videoView.tapGesture requireGestureRecognizerToFail:panGesture];
    [self.videoView addGestureRecognizer:panGesture];
}

- (void)respondsToPanGesture:(UIPanGestureRecognizer *)pan {
    if (self.yb_isRotating()) return;
    if ((!self.videoView.thumbImageView.image && !self.videoView.isPlaying)) return;
    
    YBIBInteractionProfile *profile = ((YBIBVideoData *)self.yb_cellData).interactionProfile;
    if (profile.disable) return;
    
    CGPoint point = [pan locationInView:self];
    CGSize containerSize = self.yb_containerSize(self.yb_currentOrientation());
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        _interactStartPoint = point;
    } else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateRecognized || pan.state == UIGestureRecognizerStateFailed) {
        
        // End
        if (_interacting) {
            CGPoint velocity = [pan velocityInView:self.videoView];
            
            BOOL velocityArrive = ABS(velocity.y) > profile.dismissVelocityY;
            BOOL distanceArrive = ABS(point.y - _interactStartPoint.y) > containerSize.height * profile.dismissScale;
            
            BOOL shouldDismiss = distanceArrive || velocityArrive;
            if (shouldDismiss) {
                [self hideBrowser];
            } else {
                [self restoreGestureInteractionWithDuration:profile.restoreDuration];
            }
        }
        
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        
        if (_interacting) {
            
            // Change
            self.videoView.center = point;
            CGFloat scale = 1 - ABS(point.y - _interactStartPoint.y) / (containerSize.height * 1.2);
            if (scale > 1) scale = 1;
            if (scale < 0.35) scale = 0.35;
            self.videoView.transform = CGAffineTransformMakeScale(scale, scale);
            
            CGFloat alpha = 1 - ABS(point.y - _interactStartPoint.y) / (containerSize.height * 0.7);
            if (alpha > 1) alpha = 1;
            if (alpha < 0) alpha = 0;
            self.yb_backView.backgroundColor = [self.yb_backView.backgroundColor colorWithAlphaComponent:alpha];
            
        } else {
            
            // Start
            if (CGPointEqualToPoint(_interactStartPoint, CGPointZero) || self.yb_currentPage() != self.yb_selfPage() || !self.yb_cellIsInCenter() || self.videoView.actionBar.isTouchInside) return;
            
            CGPoint velocityPoint = [pan velocityInView:self.videoView];
            CGFloat triggerDistance = profile.triggerDistance;
            
            BOOL distanceArrive = ABS(point.y - _interactStartPoint.y) > triggerDistance && (ABS(point.x - _interactStartPoint.x) < triggerDistance && ABS(velocityPoint.x) < 500);
            
            BOOL shouldStart = distanceArrive;
            if (!shouldStart) return;
            
            [self.videoView hideToolBar:YES];
            
            _interactStartPoint = point;
            
            CGRect startFrame = self.videoView.bounds;
            CGFloat anchorX = (point.x - startFrame.origin.x) / startFrame.size.width,
            anchorY = (point.y - startFrame.origin.y) / startFrame.size.height;
            self.videoView.layer.anchorPoint = CGPointMake(anchorX, anchorY);
            self.videoView.userInteractionEnabled = NO;
            self.videoView.center = point;
            
            [self hideToolViews:YES];
            self.yb_hideStatusBar(NO);
            self.yb_collectionView().scrollEnabled = NO;
            
            _interacting = YES;
        }
    }
}

- (void)restoreGestureInteractionWithDuration:(NSTimeInterval)duration {
    [self.videoView hideToolBar:NO];
    
    CGSize containerSize = self.yb_containerSize(self.yb_currentOrientation());
    
    void (^animations)(void) = ^{
        self.yb_backView.backgroundColor = [self.yb_backView.backgroundColor colorWithAlphaComponent:1];
        
        CGPoint anchorPoint = self.videoView.layer.anchorPoint;
        self.videoView.center = CGPointMake(containerSize.width * anchorPoint.x, containerSize.height * anchorPoint.y);
        self.videoView.transform = CGAffineTransformIdentity;
    };
    void (^completion)(BOOL finished) = ^(BOOL finished){
        self.videoView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.videoView.center = CGPointMake(containerSize.width * 0.5, containerSize.height * 0.5);
        self.videoView.userInteractionEnabled = YES;
        
        self.yb_hideStatusBar(YES);
        self.yb_collectionView().scrollEnabled = YES;
        if (!self.videoView.isPlaying) [self hideToolViews:NO];;
        
        self->_interactStartPoint = CGPointZero;
        self->_interacting = NO;
    };
    if (duration <= 0) {
        animations();
        completion(NO);
    } else {
        [UIView animateWithDuration:duration animations:animations completion:completion];
    }
}

#pragma mark - getters & setters

- (YBIBVideoView *)videoView {
    if (!_videoView) {
        _videoView = [YBIBVideoView new];
        _videoView.delegate = self;
    }
    return _videoView;
}

@end
