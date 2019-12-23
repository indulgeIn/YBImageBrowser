//
//  YBImageBrowser.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/5.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBIBUtilities.h"
#import "YBIBCellProtocol.h"
#import "YBIBDataMediator.h"
#import "YBIBScreenRotationHandler.h"
#import "NSObject+YBImageBrowser.h"
#import "YBImageBrowser+Internal.h"
#if __has_include("YBIBDefaultWebImageMediator.h")
#import "YBIBDefaultWebImageMediator.h"
#endif

@interface YBImageBrowser () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) YBIBCollectionView *collectionView;
@property (nonatomic, strong) YBIBDataMediator *dataMediator;
@property (nonatomic, strong) YBIBScreenRotationHandler *rotationHandler;
@end

@implementation YBImageBrowser {
    BOOL _originStatusBarHidden;
}

#pragma mark - life cycle

- (void)dealloc {
    self.hiddenProjectiveView = nil;
    [self showStatusBar];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.blackColor;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToLongPress:)];
        [self addGestureRecognizer:longPress];
        [self initValue];
    }
    return self;
}

- (void)initValue {
    _transitioning = _showTransitioning = _hideTransitioning = NO;
    _defaultAnimatedTransition = _animatedTransition = [YBIBAnimatedTransition new];
    _toolViewHandlers = @[[YBIBToolViewHandler new]];
    _defaultToolViewHandler = _toolViewHandlers[0];
    _auxiliaryViewHandler = [YBIBAuxiliaryViewHandler new];
    _shouldHideStatusBar = YES;
    _autoHideProjectiveView = YES;
#if __has_include("YBIBDefaultWebImageMediator.h")
    _webImageMediator = [YBIBDefaultWebImageMediator new];
#endif
}

#pragma mark - private

- (void)build {
    [self addSubview:self.collectionView];
    self.collectionView.frame = self.bounds;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:self.containerView];
    self.containerView.frame = self.bounds;
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self buildToolView];
    
    [self layoutIfNeeded];
    
    [self collectionViewScrollToPage:self.currentPage];
    [self.rotationHandler startObserveDeviceOrientation];
}

- (void)buildToolView {
    for (id<YBIBToolViewHandler> handler in self.toolViewHandlers) {
        [self implementGetBaseInfoProtocol:handler];
        [self implementOperateBrowserProtocol:handler];
        __weak typeof(self) wSelf = self;
        if ([handler respondsToSelector:@selector(setYb_currentData:)]) {
            [handler setYb_currentData:^id<YBIBDataProtocol>{
                __strong typeof(wSelf) self = wSelf;
                if (!self) return nil;
                return self.currentData;
            }];
        }
        [handler yb_containerViewIsReadied];
        [handler yb_hide:NO];
    }
}

- (void)rebuild {
    self.hiddenProjectiveView = nil;
    [self showStatusBar];
    [self.containerView removeFromSuperview];
    _containerView = nil;
    [self.collectionView removeFromSuperview];
    _collectionView = nil;
    [self.dataMediator clear];
    [self.rotationHandler clear];
}

- (void)collectionViewScrollToPage:(NSInteger)page {
    [self.collectionView scrollToPage:page];
    [self pageNumberChanged];
}

- (void)pageNumberChanged {
    id<YBIBDataProtocol> data = self.currentData;
    UIView *projectiveView = nil;
    if ([data respondsToSelector:@selector(yb_projectiveView)]) {
        projectiveView = [data yb_projectiveView];
    }
    self.hiddenProjectiveView = projectiveView;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(yb_imageBrowser:pageChanged:data:)]) {
        [self.delegate yb_imageBrowser:self pageChanged:self.currentPage data:data];
    }
    for (id<YBIBToolViewHandler> handler in self.toolViewHandlers) {
        if ([handler respondsToSelector:@selector(yb_pageChanged)]) {
            [handler yb_pageChanged];
        }
    }
    NSArray *visibleCells = self.collectionView.visibleCells;
    for (UICollectionViewCell<YBIBCellProtocol> *cell in visibleCells) {
        if ([cell respondsToSelector:@selector(yb_pageChanged)]) {
            [cell yb_pageChanged];
        }
    }
}

- (void)showStatusBar {
    if (self.shouldHideStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = _originStatusBarHidden;
    }
}

- (void)hideStatusBar {
    if (self.shouldHideStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    }
}

#pragma mark - public

- (void)show {
    [self showToView:[UIApplication sharedApplication].keyWindow];
}

- (void)showToView:(UIView *)view {
    [self showToView:view containerSize:view.bounds.size];
}

- (void)showToView:(UIView *)view containerSize:(CGSize)containerSize {
    [self.rotationHandler startObserveStatusBarOrientation];
    
    [view addSubview:self];
    self.frame = view.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _originStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
    
    [self.rotationHandler configContainerSize:containerSize];
    
    [self.dataMediator preloadWithPage:self.currentPage];
    
    __kindof UIView *startView;
    UIImage *startImage;
    CGRect endFrame = CGRectZero;
    id<YBIBDataProtocol> data = [self.dataMediator dataForCellAtIndex:self.currentPage];
    if ([data respondsToSelector:@selector(yb_projectiveView)]) {
        startView = data.yb_projectiveView;
        self.hiddenProjectiveView = startView;
        if ([startView isKindOfClass:UIImageView.class]) {
            startImage = ((UIImageView *)startView).image;
        } else {
            startImage = YBIBSnapshotView(startView);
        }
    }
    if ([data respondsToSelector:@selector(yb_imageViewFrameWithContainerSize:imageSize:orientation:)]) {
        endFrame = [data yb_imageViewFrameWithContainerSize:self.bounds.size imageSize:startImage.size orientation:self.rotationHandler.currentOrientation];
    }
    
    [self setTransitioning:YES isShow:YES];
    [self.animatedTransition yb_showTransitioningWithContainer:self startView:startView startImage:startImage endFrame:endFrame orientation:self.rotationHandler.currentOrientation completion:^{
        [self hideStatusBar];
        [self build];
        [self setTransitioning:NO isShow:YES];
    }];
}

- (void)hide {
    __kindof UIView *startView;
    __kindof UIView *endView;
    UICollectionViewCell<YBIBCellProtocol> *cell = (UICollectionViewCell<YBIBCellProtocol> *)self.collectionView.centerCell;
    if ([cell respondsToSelector:@selector(yb_foregroundView)]) {
        startView = cell.yb_foregroundView;
    }
    if ([cell.yb_cellData respondsToSelector:@selector(yb_projectiveView)]) {
        endView = cell.yb_cellData.yb_projectiveView;
    }
    
    for (id<YBIBToolViewHandler> handler in self.toolViewHandlers) {
        [handler yb_hide:YES];
    }
    [self showStatusBar];
    
    [self setTransitioning:YES isShow:NO];
    [self.animatedTransition yb_hideTransitioningWithContainer:self startView:startView endView:endView orientation:self.rotationHandler.currentOrientation completion:^{
        [self rebuild];
        [self removeFromSuperview];
        [self setTransitioning:NO isShow:NO];
    }];
}

- (void)reloadData {
    [self.dataMediator clear];
    NSInteger page = self.currentPage;
    [self.collectionView reloadData];
    self.currentPage = page;
}

- (id<YBIBDataProtocol>)currentData {
    return [self.dataMediator dataForCellAtIndex:self.currentPage];
}

#pragma mark - internal

- (void)setHiddenProjectiveView:(NSObject *)hiddenProjectiveView {
    if (_hiddenProjectiveView && [_hiddenProjectiveView respondsToSelector:@selector(setAlpha:)]) {
        CGFloat originAlpha = _hiddenProjectiveView.ybib_originAlpha;
        if (originAlpha != 1) {
            [_hiddenProjectiveView setValue:@(1) forKey:@"alpha"];
            [UIView animateWithDuration:0.2 animations:^{
                [self->_hiddenProjectiveView setValue:@(originAlpha) forKey:@"alpha"];
            }];
        } else {
            [_hiddenProjectiveView setValue:@(originAlpha) forKey:@"alpha"];
        }
    }
    _hiddenProjectiveView = hiddenProjectiveView;
    
    if (!self.autoHideProjectiveView) return;
    
    if (hiddenProjectiveView && [hiddenProjectiveView respondsToSelector:@selector(setAlpha:)]) {
        hiddenProjectiveView.ybib_originAlpha = ((NSNumber *)[hiddenProjectiveView valueForKey:@"alpha"]).floatValue;
        [hiddenProjectiveView setValue:@(0) forKey:@"alpha"];
    }
}

- (void)implementOperateBrowserProtocol:(id<YBIBOperateBrowserProtocol>)obj {
    __weak typeof(self) wSelf = self;
    if ([obj respondsToSelector:@selector(setYb_hideBrowser:)]) {
        [obj setYb_hideBrowser:^{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return;
            [self hide];
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_hideStatusBar:)]) {
        [obj setYb_hideStatusBar:^(BOOL hide) {
            __strong typeof(wSelf) self = wSelf;
            if (!self) return;
            hide ? [self hideStatusBar] : [self showStatusBar];
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_hideToolViews:)]) {
        [obj setYb_hideToolViews:^(BOOL hide) {
            __strong typeof(wSelf) self = wSelf;
            if (!self) return;
            for (id<YBIBToolViewHandler> handler in self.toolViewHandlers) {
                [handler yb_hide:hide];
            }
        }];
    }
}

- (void)implementGetBaseInfoProtocol:(id<YBIBGetBaseInfoProtocol>)obj {
    __weak typeof(self) wSelf = self;
    if ([obj respondsToSelector:@selector(setYb_currentOrientation:)]) {
        [obj setYb_currentOrientation:^UIDeviceOrientation{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return UIDeviceOrientationPortrait;
            return self.rotationHandler.currentOrientation;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_containerSize:)]) {
        [obj setYb_containerSize:^CGSize(UIDeviceOrientation orientation) {
            __strong typeof(wSelf) self = wSelf;
            if (!self) return CGSizeZero;
            return [self.rotationHandler containerSizeWithOrientation:orientation];
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_auxiliaryViewHandler:)]) {
        [obj setYb_auxiliaryViewHandler:^id<YBIBAuxiliaryViewHandler>{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return nil;
            return self.auxiliaryViewHandler;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_webImageMediator:)]) {
        [obj setYb_webImageMediator:^id<YBIBWebImageMediator> {
            __strong typeof(wSelf) self = wSelf;
            if (!self) return nil;
            NSAssert(self.webImageMediator, @"'webImageMediator' should not be nil.");
            return self.webImageMediator;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_currentPage:)]) {
        [obj setYb_currentPage:^NSInteger{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return 0;
            return self.currentPage;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_totalPage:)]) {
        [obj setYb_totalPage:^NSInteger{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return 0;
            return [self.dataMediator numberOfCells];
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_backView:)]) {
        obj.yb_backView = self;
    }
    if ([obj respondsToSelector:@selector(setYb_containerView:)]) {
        obj.yb_containerView = self.containerView;
    }
    if ([obj respondsToSelector:@selector(setYb_collectionView:)]) {
        [obj setYb_collectionView:^__kindof UICollectionView *{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return nil;
            return self.collectionView;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_cellIsInCenter:)]) {
        [obj setYb_cellIsInCenter:^BOOL{
            __strong typeof(wSelf) self = wSelf;
            CGFloat pageF = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width;
            // '0.001' is admissible error.
            return ABS(pageF - (NSInteger)pageF) <= 0.001;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_isTransitioning:)]) {
        [obj setYb_isTransitioning:^BOOL{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return NO;
            return self.isTransitioning;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_isShowTransitioning:)]) {
        [obj setYb_isShowTransitioning:^BOOL{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return NO;
            return self.isShowTransitioning;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_isHideTransitioning:)]) {
        [obj setYb_isHideTransitioning:^BOOL{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return NO;
            return self.isHideTransitioning;
        }];
    }
    if ([obj respondsToSelector:@selector(setYb_isRotating:)]) {
        [obj setYb_isRotating:^BOOL{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return NO;
            return self.rotationHandler.isRotating;
        }];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataMediator numberOfCells];
}

- (UICollectionViewCell *)collectionView:(YBIBCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id<YBIBDataProtocol> data = [self.dataMediator dataForCellAtIndex:indexPath.row];
    
    UICollectionViewCell<YBIBCellProtocol> *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[collectionView reuseIdentifierForCellClass:data.yb_classOfCell] forIndexPath:indexPath];
    
    [self implementGetBaseInfoProtocol:cell];
    [self implementOperateBrowserProtocol:cell];
    
    if ([cell respondsToSelector:@selector(setYb_selfPage:)]) {
        [cell setYb_selfPage:^NSInteger{
            return indexPath.row;
        }];
    }
    
    cell.yb_cellData = data;
    
    if ([cell respondsToSelector:@selector(yb_pageChanged)]) {
        [cell yb_pageChanged];
    }
    
    [self.dataMediator preloadWithPage:indexPath.row];
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageF = scrollView.contentOffset.x / scrollView.bounds.size.width;
    NSInteger page = (NSInteger)(pageF + 0.5);
    
    for (id<YBIBToolViewHandler> handler in self.toolViewHandlers) {
        if ([handler respondsToSelector:@selector(yb_offsetXChanged:)]) {
            [handler yb_offsetXChanged:pageF];
        }
    }
    
    if (!scrollView.isDecelerating && !scrollView.isDragging) {
        // Return if not scrolled by finger.
        return;
    }
    if (page < 0 || page > [self.dataMediator numberOfCells] - 1) return;
    if (self.rotationHandler.isRotating) return;
    
    if (page != _currentPage) {
        _currentPage = page;
        [self pageNumberChanged];
    }
}

#pragma mark - event

- (void)respondsToLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(yb_imageBrowser:respondsToLongPressWithData:)]) {
            [self.delegate yb_imageBrowser:self respondsToLongPressWithData:[self currentData]];
        } else {
            for (id<YBIBToolViewHandler> handler in self.toolViewHandlers) {
                if ([handler respondsToSelector:@selector(yb_respondsToLongPress)]) {
                    [handler yb_respondsToLongPress];
                }
            }
        }
    }
}

#pragma mark - getters & setters

- (YBIBContainerView *)containerView {
    if (!_containerView) {
        _containerView = [YBIBContainerView new];
        _containerView.backgroundColor = UIColor.clearColor;
        _containerView.layer.masksToBounds = YES;
    }
    return _containerView;
}

- (YBIBCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [YBIBCollectionView new];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}
- (void)setCurrentPage:(NSInteger)currentPage {
    NSInteger maxPage = self.dataMediator.numberOfCells - 1;
    if (currentPage > maxPage) {
        currentPage = maxPage;
    }
    _currentPage = currentPage;
    if (self.collectionView.superview) {
        [self collectionViewScrollToPage:currentPage];
    }
}
- (void)setDistanceBetweenPages:(CGFloat)distanceBetweenPages {
    self.collectionView.layout.distanceBetweenPages = distanceBetweenPages;
}
- (CGFloat)distanceBetweenPages {
    return self.collectionView.layout.distanceBetweenPages;
}

- (void)setTransitioning:(BOOL)transitioning isShow:(BOOL)isShow {
    _transitioning = transitioning;
    _showTransitioning = transitioning && isShow;
    _hideTransitioning = transitioning && !isShow;
    
    // Make 'self.userInteractionEnabled' always 'YES' to block external interaction.
    self.containerView.userInteractionEnabled = !transitioning;
    self.collectionView.userInteractionEnabled = !transitioning;
    
    if (transitioning) {
        if ([self.delegate respondsToSelector:@selector(yb_imageBrowser:beginTransitioningWithIsShow:)]) {
            [self.delegate yb_imageBrowser:self beginTransitioningWithIsShow:isShow];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(yb_imageBrowser:endTransitioningWithIsShow:)]) {
            [self.delegate yb_imageBrowser:self endTransitioningWithIsShow:isShow];
        }
    }
}

- (YBIBDataMediator *)dataMediator {
    if (!_dataMediator) {
        _dataMediator = [[YBIBDataMediator alloc] initWithBrowser:self];
        _dataMediator.dataCacheCountLimit = YBIBLowMemory() ? 9 : 27;
        _dataMediator.preloadCount = YBIBLowMemory() ? 0 : 2;
    }
    return _dataMediator;
}
- (void)setPreloadCount:(NSUInteger)preloadCount {
    self.dataMediator.preloadCount = preloadCount;
}
- (NSUInteger)preloadCount {
    return self.dataMediator.preloadCount;
}

- (YBIBScreenRotationHandler *)rotationHandler {
    if (!_rotationHandler) {
        _rotationHandler = [[YBIBScreenRotationHandler alloc] initWithBrowser:self];
    }
    return _rotationHandler;
}
- (void)setSupportedOrientations:(UIInterfaceOrientationMask)supportedOrientations {
    self.rotationHandler.supportedOrientations = supportedOrientations;
}
- (UIInterfaceOrientationMask)supportedOrientations {
    return self.rotationHandler.supportedOrientations;
}
- (UIDeviceOrientation)currentOrientation {
    return self.rotationHandler.currentOrientation;
}

@end
