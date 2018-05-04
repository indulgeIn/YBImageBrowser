//
//  YBImageBrowserTestVC.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBImageBrowserView.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "YBImageBrowserPromptBar.h"
#import "YBImageBrowserAnimatedTransitioning.h"
#import "YBImageBrowserViewLayout.h"
#import "YBImageBrowserDownloader.h"
#import "NSBundle+YBImageBrowser.h"

static CGFloat _maxDisplaySize = 3500;
static BOOL _showStatusBar = NO;    //改控制器是否需要隐藏状态栏
static BOOL _isControllerPreferredForStatusBar = YES; //状态栏是否是控制器优先
static BOOL _statusBarIsHideBefore = NO;    //状态栏在模态切换之前是否隐藏

@interface YBImageBrowser () <YBImageBrowserViewDelegate, YBImageBrowserViewDataSource, YBImageBrowserToolBarDelegate, YBImageBrowserFunctionBarDelegate, UIViewControllerTransitioningDelegate> {
    UIInterfaceOrientationMask supportAutorotateTypes;
    UIWindow *window;
    BOOL isDealViewDidAppear;
    YBImageBrowserAnimatedTransitioning *animatedTransitioningManager;
    UIColor *backgroundColor;
}

@property (nonatomic, strong) YBImageBrowserView *browserView;
@property (nonatomic, strong) YBImageBrowserToolBar *toolBar;
@property (nonatomic, strong) YBImageBrowserFunctionBar *functionBar;

@property (class, assign) BOOL isControllerPreferredForStatusBar;

@end

@implementation YBImageBrowser

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

#pragma mark life cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self initData];
        [self getStatusBarConfigByInfoPlist];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = backgroundColor;
    [self addNotification];
    if (_isControllerPreferredForStatusBar && !_showStatusBar && !_statusBarIsHideBefore) {
        [self configStatusBarHide:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _statusBarIsHideBefore = [UIApplication sharedApplication].statusBarHidden;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!isDealViewDidAppear) {
        [self setConfigInfoToChildModules];
        [self so_setFrameInfoWithSuperViewScreenOrientation:YBImageBrowserScreenOrientationVertical superViewSize:CGSizeMake(YB_SCREEN_WIDTH, YB_SCREEN_HEIGHT)];
        [self so_updateFrameWithScreenOrientation:[self getScreenOrientationByStatusBar]];
        [self.view addSubview:self.browserView];
        [self.view addSubview:self.toolBar];
        [self.browserView scrollToPageWithIndex:self.currentIndex];
        [self addDeviceOrientationNotification];
        isDealViewDidAppear = YES;
        [self configSupportAutorotateTypes];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_isControllerPreferredForStatusBar && !_showStatusBar && !_statusBarIsHideBefore) {
        [self configStatusBarHide:NO];
    }
}

- (BOOL)prefersStatusBarHidden {
    return !YBImageBrowser.showStatusBar;
}

- (void)configStatusBarHide:(BOOL)hide {
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    statusBar.alpha = !hide;
}

#pragma mark notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yBImageBrowser_notification_changeAlpha:) name:YBImageBrowser_notification_changeAlpha object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yBImageBrowser_notification_showBrowerView) name:YBImageBrowser_notification_showBrowerView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yBImageBrowser_notification_hideBrowerView) name:YBImageBrowser_notification_hideBrowerView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yBImageBrowser_notification_willShowBrowerViewWithTimeInterval:) name:YBImageBrowser_notification_willShowBrowerViewWithTimeInterval object:nil];
}

- (void)yBImageBrowser_notification_willShowBrowerViewWithTimeInterval:(NSNotification *)noti {
    CGFloat timeInterval = [noti.userInfo[YBImageBrowser_notificationKey_willShowBrowerViewWithTimeInterval] floatValue];
    [UIView animateWithDuration:timeInterval animations:^{
        self.view.backgroundColor = [self->backgroundColor colorWithAlphaComponent:1];
    }];
}

- (void)yBImageBrowser_notification_changeAlpha:(NSNotification *)noti {
    CGFloat scale = [noti.userInfo[YBImageBrowser_notificationKey_changeAlpha] floatValue];
    self.view.backgroundColor = [backgroundColor colorWithAlphaComponent:scale];
}

- (void)yBImageBrowser_notification_showBrowerView {
    self.view.backgroundColor = [backgroundColor colorWithAlphaComponent:1];
    if (self.browserView.isHidden) self.browserView.hidden = NO;
}

- (void)yBImageBrowser_notification_hideBrowerView {
    if (!self.browserView.isHidden)  self.browserView.hidden = YES;
}

#pragma mark private

//初始化数据
- (void)initData {
    backgroundColor = [UIColor blackColor];
    _showStatusBar = NO;
    isDealViewDidAppear = NO;
    _cancelLongPressGesture = NO;
    _yb_supportedInterfaceOrientations = UIInterfaceOrientationMaskAllButUpsideDown;
    _distanceBetweenPages = 18;
    _autoCountMaximumZoomScale = YES;
    animatedTransitioningManager = [YBImageBrowserAnimatedTransitioning new];
    _transitionDuration = 0.35;
    _cancelLongPressGesture = NO;
    _cancelDragImageViewAnimation = NO;
    _outScaleOfDragImageViewAnimation = 0.15;
    _inAnimation = YBImageBrowserAnimationMove;
    _outAnimation = YBImageBrowserAnimationMove;
    window = [YBImageBrowserUtilities getNormalWindow];
    _verticalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    _horizontalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    self.fuctionDataArray = @[[YBImageBrowserFunctionModel functionModelForSavePictureToAlbum]];
}

//给子模块赋值配置
- (void)setConfigInfoToChildModules {
    self.browserView.autoCountMaximumZoomScale = _autoCountMaximumZoomScale;
    self.browserView.loadFailedText = self.copywriter.loadFailedText;
    self.browserView.isScaleImageText = self.copywriter.isScaleImageText;
    self.browserView.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
    self.browserView.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
    self.browserView.cancelDragImageViewAnimation = self.cancelDragImageViewAnimation;
    self.browserView.outScaleOfDragImageViewAnimation = self.outScaleOfDragImageViewAnimation;
    ((YBImageBrowserViewLayout *)self.browserView.collectionViewLayout).distanceBetweenPages = self.distanceBetweenPages;
}

//获取屏幕展示的方向
- (YBImageBrowserScreenOrientation)getScreenOrientationByStatusBar {
    UIInterfaceOrientation obr = [UIApplication sharedApplication].statusBarOrientation;
    if ((obr == UIInterfaceOrientationPortrait) || (obr == UIInterfaceOrientationPortraitUpsideDown)) {
        return YBImageBrowserScreenOrientationVertical;
    } else if ((obr == UIInterfaceOrientationLandscapeLeft) || (obr == UIInterfaceOrientationLandscapeRight)) {
        return YBImageBrowserScreenOrientationHorizontal;
    } else {
        return YBImageBrowserScreenOrientationUnknown;
    }
}

//找到 keywidow 和当前 Controller 支持屏幕旋转方向的交集
- (void)configSupportAutorotateTypes {
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientationMask keyWindowSupport = [application supportedInterfaceOrientationsForWindow:window];
    UIInterfaceOrientationMask selfSupport = ![self shouldAutorotate] ? UIInterfaceOrientationMaskPortrait : [self supportedInterfaceOrientations];
    supportAutorotateTypes = keyWindowSupport & selfSupport;
}

//根据 device 方向改变 UI
- (void)resetUserInterfaceLayoutByDeviceOrientation {
    
    YBImageBrowserScreenOrientation so;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    BOOL isVertical = (deviceOrientation == UIDeviceOrientationPortrait && (supportAutorotateTypes & UIInterfaceOrientationMaskPortrait)) || (deviceOrientation == UIInterfaceOrientationPortraitUpsideDown && (supportAutorotateTypes & UIInterfaceOrientationMaskPortraitUpsideDown));
    BOOL isHorizontal = (deviceOrientation == UIDeviceOrientationLandscapeRight && (supportAutorotateTypes & UIInterfaceOrientationMaskLandscapeLeft)) || (deviceOrientation == UIDeviceOrientationLandscapeLeft && (supportAutorotateTypes & UIInterfaceOrientationMaskLandscapeRight));
    if (isVertical) {
        so = YBImageBrowserScreenOrientationVertical;
    } else if(isHorizontal) {
        so = YBImageBrowserScreenOrientationHorizontal;
    } else {
        return;
    }
    
    //发送将要转屏更新 UI 的广播
    [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notification_willToRespondsDeviceOrientation object:nil];
    
    //将正在执行的拖拽动画取消
    [self yBImageBrowser_notification_showBrowerView];
    
    //隐藏弹出功能栏、隐藏提示框
    if (_functionBar && _functionBar.superview) {
        [_functionBar hideWithAnimate:NO];
    }
    [self.view yb_hidePromptImmediately];
    
    //更新UI
    [self so_updateFrameWithScreenOrientation:so];
}

- (void)setTooBarNumberCountWithCurrentIndex:(NSInteger)index {
    NSInteger totalCount = 0;
    if (self.dataArray) {
        totalCount = self.dataArray.count;
    } else if (_dataSource && [_dataSource respondsToSelector:@selector(numberInYBImageBrowser:)]) {
        totalCount = [_dataSource numberInYBImageBrowser:self];
    }
    [self.toolBar setTitleLabelWithCurrentIndex:index totalCount:totalCount];
}

- (void)setTooBarHideWithDataSourceCount:(NSInteger)count {
    if (count <= 1) {
        if(!self.toolBar.titleLabel.isHidden) self.toolBar.titleLabel.hidden = YES;
    } else {
        if (self.toolBar.titleLabel.isHidden) self.toolBar.titleLabel.hidden = NO;
    }
}

#pragma mark public

- (void)show {
    [self showFromController:[YBImageBrowserUtilities getTopController]];
}

- (void)showFromController:(UIViewController *)controller {
    if (self.dataArray) {
        if (!self.dataArray.count) {
            YBLOG_ERROR(@"dataArray is invalid");
            return;
        }
    } else if (_dataSource && [_dataSource respondsToSelector:@selector(numberInYBImageBrowser:)]) {
        if (![_dataSource numberInYBImageBrowser:self]) {
            YBLOG_ERROR(@"numberInYBImageBrowser: is invalid");
            return;
        }
    } else {
        YBLOG_ERROR(@"the data source is invalid");
        return;
    }
    [controller presentViewController:self animated:YES completion:nil];
}

- (void)hide {
    if (!YBImageBrowser.isControllerPreferredForStatusBar) [[UIApplication sharedApplication] setStatusBarHidden:YBImageBrowser.statusBarIsHideBefore];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark YBImageBrowserScreenOrientationProtocol

- (void)so_setFrameInfoWithSuperViewScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation superViewSize:(CGSize)size {
    
    BOOL isVertical = screenOrientation == YBImageBrowserScreenOrientationVertical;
    CGRect rect0 = CGRectMake(0, 0, size.width, size.height), rect1 = CGRectMake(0, 0, size.height, size.width);
    _so_frameOfVertical = isVertical ? rect0 : rect1;
    _so_frameOfHorizontal = !isVertical ? rect0 : rect1;
    
    [self.browserView so_setFrameInfoWithSuperViewScreenOrientation:YBImageBrowserScreenOrientationVertical superViewSize:_so_frameOfVertical.size];
    [self.toolBar so_setFrameInfoWithSuperViewScreenOrientation:YBImageBrowserScreenOrientationVertical superViewSize:_so_frameOfVertical.size];
}

- (void)so_updateFrameWithScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation {
    if (screenOrientation == _so_screenOrientation) return;
    
    _so_isUpdateUICompletely = NO;
    
    self.view.frame = screenOrientation == YBImageBrowserScreenOrientationVertical ? _so_frameOfVertical : _so_frameOfHorizontal;
    
    _so_screenOrientation = screenOrientation;
    
    [self.browserView so_updateFrameWithScreenOrientation:screenOrientation];
    [self.toolBar so_updateFrameWithScreenOrientation:screenOrientation];
    
    _so_isUpdateUICompletely = YES;
}

#pragma mark YBImageBrowserViewDelegate

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView didScrollToIndex:(NSUInteger)index {
    _currentIndex = index;
    [self setTooBarNumberCountWithCurrentIndex:index+1];
    if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowser:didScrollToIndex:)]) {
        [_delegate yBImageBrowser:self didScrollToIndex:index];
    }
}

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView longPressBegin:(UILongPressGestureRecognizer *)gesture {
    if (_cancelLongPressGesture) return;
    if (self.fuctionDataArray.count > 1) {
        //弹出功能栏
        if (_functionBar) {
            [_functionBar show];
        }
    }
}

- (void)applyForHiddenByYBImageBrowserView:(YBImageBrowserView *)imageBrowserView {
    [self hide];
}

#pragma mark YBImageBrowserViewDataSource

- (NSInteger)numberInYBImageBrowserView:(YBImageBrowserView *)imageBrowserView {
    if (self.dataArray) {
        NSUInteger count = self.dataArray.count;
        [self setTooBarHideWithDataSourceCount:count];
        return count;
    } else if (_dataSource && [_dataSource respondsToSelector:@selector(numberInYBImageBrowser:)]) {
        NSUInteger count = [_dataSource numberInYBImageBrowser:self];
        [self setTooBarHideWithDataSourceCount:count];
        return count;
    }
    return 0;
}

- (YBImageBrowserModel *)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView modelForCellAtIndex:(NSInteger)index {
    if (self.dataArray) {
        return self.dataArray[index];
    } else if (_dataSource && [_dataSource respondsToSelector:@selector(yBImageBrowser:modelForCellAtIndex:)]) {
        return [_dataSource yBImageBrowser:self modelForCellAtIndex:index];
    }
    return nil;
}

#pragma mark YBImageBrowserToolBarDelegate

- (void)yBImageBrowserToolBar:(YBImageBrowserToolBar *)imageBrowserToolBar didClickRightButton:(UIButton *)button {
    if (!self.fuctionDataArray.count) return;
    if (self.fuctionDataArray.count == 1 && [self.fuctionDataArray[0].ID isEqualToString:YBImageBrowserFunctionModel_ID_savePictureToAlbum]) {
        //直接保存图片
        [self savePhotoToAlbumWithCurrentIndex];
    } else {
        //弹出功能栏
        if (_functionBar) {
            [_functionBar show];
        }
    }
}

#pragma mark YBImageBrowserFunctionBarDelegate

- (void)ybImageBrowserFunctionBar:(YBImageBrowserFunctionBar *)functionBar clickCellWithModel:(YBImageBrowserFunctionModel *)model {
    
    if ([model.ID isEqualToString:YBImageBrowserFunctionModel_ID_savePictureToAlbum]) {
        [self savePhotoToAlbumWithCurrentIndex];
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowser:clickFunctionBarWithModel:)]) {
            [_delegate yBImageBrowser:self clickFunctionBarWithModel:model];
        } else {
            YBLOG_WARNING(@"you are not handle events of functionBar");
        }
    }
}

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    [animatedTransitioningManager setInfoWithImageBrowser:self];
    return animatedTransitioningManager;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    [animatedTransitioningManager setInfoWithImageBrowser:self];
    return animatedTransitioningManager;
}

#pragma mark setter

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    _currentIndex = currentIndex;
    if (isDealViewDidAppear && _browserView) {
        [_browserView scrollToPageWithIndex:_currentIndex];
    }
}

- (void)setDataArray:(NSArray<YBImageBrowserModel *> *)dataArray {
    if (!dataArray || !dataArray.count) {
        YBLOG_ERROR(@"dataArray is invalid");
        return;
    }
    _dataArray = dataArray;
    [self setTooBarNumberCountWithCurrentIndex:1];
}

- (void)setYb_supportedInterfaceOrientations:(UIInterfaceOrientationMask)yb_supportedInterfaceOrientations {
    _yb_supportedInterfaceOrientations = yb_supportedInterfaceOrientations;
}

- (void)setFuctionDataArray:(NSArray<YBImageBrowserFunctionModel *> *)fuctionDataArray {
    _fuctionDataArray = fuctionDataArray;
    if (fuctionDataArray.count == 0) {
        [self.toolBar setRightButtonHide:YES];
    } else if (fuctionDataArray.count == 1) {
        YBImageBrowserFunctionModel *model = fuctionDataArray[0];
        if (model.image) {
            [self.toolBar setRightButtonImage:model.image];
            [self.toolBar setRightButtonTitle:nil];
        } else if (model.name) {
            [self.toolBar setRightButtonImage:nil];
            [self.toolBar setRightButtonTitle:model.name];
        } else {
            [self.toolBar setRightButtonImage:nil];
            [self.toolBar setRightButtonTitle:nil];
            YBLOG_WARNING(@"the only model in fuctionDataArray is invalid");
        }
    } else {
        [self.toolBar setRightButtonImage:[UIImage imageWithContentsOfFile:[[NSBundle yBImageBrowserBundle] pathForResource:@"ybImageBrowser_more" ofType:@"png"]]];
        [self.toolBar setRightButtonTitle:nil];
        //functionBar 方法仅在此处调用其它地方均用实例变量方式访问
        self.functionBar.dataArray = fuctionDataArray;
    }
}

- (void)setDownloaderShouldDecompressImages:(BOOL)downloaderShouldDecompressImages {
    _downloaderShouldDecompressImages = downloaderShouldDecompressImages;
    [YBImageBrowserDownloader shouldDecompressImages:downloaderShouldDecompressImages];
}

#pragma mark getter

- (YBImageBrowserView *)browserView {
    if (!_browserView) {
        _browserView = [[YBImageBrowserView alloc] initWithFrame:CGRectZero collectionViewLayout:[YBImageBrowserViewLayout new]];
        _browserView.yb_delegate = self;
        _browserView.yb_dataSource = self;
    }
    return _browserView;
}

- (YBImageBrowserToolBar *)toolBar {
    if (!_toolBar) {
        _toolBar = [YBImageBrowserToolBar new];
        _toolBar.delegate = self;
    }
    return _toolBar;
}

- (YBImageBrowserFunctionBar *)functionBar {
    if (!_functionBar) {
        _functionBar = [YBImageBrowserFunctionBar new];
        _functionBar.delegate = self;
    }
    return _functionBar;
}

- (YBImageBrowserCopywriter *)copywriter {
    if (!_copywriter) {
        _copywriter = [YBImageBrowserCopywriter new];
    }
    return _copywriter;
}

#pragma mark class property

+ (CGFloat)maxDisplaySize {
    return _maxDisplaySize;
}

+ (void)setMaxDisplaySize:(CGFloat)maxDisplaySize {
    _maxDisplaySize = maxDisplaySize;
}

+ (BOOL)showStatusBar {
    return _showStatusBar;
}

+ (void)setShowStatusBar:(BOOL)showStatusBar {
    _showStatusBar = showStatusBar;
}

+ (void)setStatusBarIsHideBefore:(BOOL)statusBarIsHideBefore {
    _statusBarIsHideBefore = statusBarIsHideBefore;
}

+ (BOOL)statusBarIsHideBefore {
    return _statusBarIsHideBefore;
}

+ (BOOL)isControllerPreferredForStatusBar {
    return _isControllerPreferredForStatusBar;
}

+ (void)setIsControllerPreferredForStatusBar:(BOOL)isControllerPreferredForStatusBar {
    _isControllerPreferredForStatusBar = isControllerPreferredForStatusBar;
}

#pragma mark device orientation

- (void)addDeviceOrientationNotification {
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)deviceOrientationChanged:(NSNotification *)note {
    if (supportAutorotateTypes == (supportAutorotateTypes & (-supportAutorotateTypes))) {
        //若不是复合项，不需要改变结构UI（此处位运算部分感谢算法大佬刘曦老哥的贡献😁）
        return;
    }
    [self resetUserInterfaceLayoutByDeviceOrientation];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.yb_supportedInterfaceOrientations;
}

#pragma mark save photo to album

- (void)savePhotoToAlbumWithCurrentIndex {
    YBImageBrowserView *browserView = self.browserView;
    if (!browserView) return;
    YBImageBrowserCell *cell = (YBImageBrowserCell *)[browserView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:browserView.currentIndex inSection:0]];
    if (!cell) return;
    if (cell.model) [self savePhotoToAlbumWithModel:cell.model preview:NO];
}

- (void)savePhotoToAlbumWithModel:(YBImageBrowserModel *)model preview:(BOOL)preview {
    if (model.needCutToShow) {
        [self judgeAlbumAuthorizationStatusSuccess:^{
            UIImage *largeImage = [model valueForKey:YBImageBrowserModel_KVCKey_largeImage];
            if (largeImage) [self savePhotoToAlbumWithImage:largeImage];
        }];
    } if (model.image) {
        [self judgeAlbumAuthorizationStatusSuccess:^{
            [self savePhotoToAlbumWithImage:model.image];
        }];
    } else if (model.animatedImage) {
        if (model.animatedImage.data) {
            [self judgeAlbumAuthorizationStatusSuccess:^{
                [self saveGifToAlbumWithData:model.animatedImage.data];
            }];
        } else {
            YBLOG_WARNING(@"instance of FLAnimatedImage is exist, but it's key-data is not exist, this maybe the BUG of the framework of FLAnimatedImage");
        }
    } else {
        if (!preview) {
            [self savePhotoToAlbumWithModel:model.previewModel preview:YES];
        } else {
            [YB_NORMALWINDOW yb_showForkPromptWithText:self.copywriter.noImageDataToSave];
        }
    }
}

- (void)judgeAlbumAuthorizationStatusSuccess:(void(^)(void))success {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        [YB_NORMALWINDOW yb_showForkPromptWithText:self.copywriter.albumAuthorizationDenied];
    } else if(status == PHAuthorizationStatusNotDetermined){
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            if (status == PHAuthorizationStatusAuthorized) {
                if (success) success();
            } else {
                YBLOG_WARNING(@"user is not Authorized");
            }
        }];
    } else if (status == PHAuthorizationStatusAuthorized){
        if (success) success();
    }
}
    
- (void)saveGifToAlbumWithData:(NSData *)data {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if (!error) {
            [YB_NORMALWINDOW yb_showHookPromptWithText:self.copywriter.saveImageDataToAlbumSuccessful];
        } else {
            [YB_NORMALWINDOW yb_showForkPromptWithText:self.copywriter.saveImageDataToAlbumFailed];
        }
    }];
}

- (void)savePhotoToAlbumWithImage:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self.class, @selector(completedWithImage:error:context:), (__bridge void *)self);
}

+ (void)completedWithImage:(UIImage *)image error:(NSError *)error context:(void *)context {
    id obj = (__bridge id)context;
    if (!obj || ![obj isKindOfClass:[YBImageBrowser class]]) return;
    YBImageBrowserCopywriter *copywriter = ((YBImageBrowser *)obj).copywriter;
    if (!error) {
        [YB_NORMALWINDOW yb_showHookPromptWithText:copywriter.saveImageDataToAlbumSuccessful];
    } else {
        [YB_NORMALWINDOW yb_showForkPromptWithText:copywriter.saveImageDataToAlbumFailed];
    }
}

#pragma mark status bar

- (void)getStatusBarConfigByInfoPlist {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:bundlePath];
    id value = dict[@"UIViewControllerBasedStatusBarAppearance"];
    if (value) {
        _isControllerPreferredForStatusBar = [value boolValue];
    } else {
        _isControllerPreferredForStatusBar = YES;
    }
}

@end
