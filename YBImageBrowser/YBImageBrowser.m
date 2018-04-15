//
//  YBImageBrowserTestVC.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBImageBrowserView.h"
#import <pthread.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "YBImageBrowserPromptBar.h"
#import "YBImageBrowserAnimatedTransitioningManager.h"
#import "YBImageBrowerInteractiveTransition.h"

@interface YBImageBrowser () <YBImageBrowserViewDelegate, YBImageBrowserToolBarDelegate, YBImageBrowserFunctionBarDelegate, UIViewControllerTransitioningDelegate> {
    UIInterfaceOrientationMask supportAutorotateTypes;
    pthread_mutex_t lock;
    UIWindow *window;
    BOOL isDealViewDidAppear;
    YBImageBrowserAnimatedTransitioningManager *animatedTransitioningManager;
    YBImageBrowerInteractiveTransition *interactiveTransition;
}

@property (nonatomic, strong) YBImageBrowserView *browserView;
@property (nonatomic, strong) YBImageBrowserToolBar *toolBar;
@property (nonatomic, strong) YBImageBrowserFunctionBar *functionBar;

@end

@implementation YBImageBrowser

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

#pragma mark life cycle

- (void)dealloc {
    YBLOG(@"%@, dealloc", self.class);
    pthread_mutex_destroy(&lock);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
        [self initData];
        [self addNotification];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.browserView];
    [self.view addSubview:self.toolBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //此刻 statusBar 的方向才是当前控制器设定的方向
    if (!isDealViewDidAppear) {
        [self setInfoToBrowerView];
        [self so_setFrameInfoWithSuperViewScreenOrientation:YBImageBrowserScreenOrientationVertical superViewSize:CGSizeMake(YB_SCREEN_WIDTH, YB_SCREEN_HEIGHT)];
        [self so_updateFrameWithScreenOrientation:[self getScreenOrientationByStatusBar]];
        [self.browserView scrollToPageWithIndex:self.currentIndex animated:NO];
        [self addDeviceOrientationNotification];
        isDealViewDidAppear = YES;
        [self configSupportAutorotateTypes];
    }
}

- (BOOL)prefersStatusBarHidden {
    return !self.showStatusBar;
}

#pragma mark private

//初始化数据
- (void)initData {
    animatedTransitioningManager = [YBImageBrowserAnimatedTransitioningManager new];
    interactiveTransition = [YBImageBrowerInteractiveTransition new];
    isDealViewDidAppear = NO;
    _showStatusBar = NO;
    pthread_mutex_init(&lock, NULL);
    window = [YBImageBrowserUtilities getNormalWindow];
    self.verticalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    self.horizontalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    self.fuctionDataArray = @[[YBImageBrowserFunctionModel functionModelForSavePictureToAlbum]];
}

//browerview 赋值
- (void)setInfoToBrowerView {
    self.browserView.loadFailedText = self.copywriter.loadFailedText;
    self.browserView.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
    self.browserView.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
    self.browserView.dataArray = self.dataArray;
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
    
    //隐藏额外功能栏、隐藏提示框
    if (_functionBar && _functionBar.superview) {
        [_functionBar hideWithAnimate:NO];
    }
    [self.view yb_hidePromptImmediately];
    
    //更新UI
    [self so_updateFrameWithScreenOrientation:so];
}

#pragma mark public

- (void)show {
    if (!_dataArray || !_dataArray.count) {
        YBLOG_WARNING(@"dataArray is invalid")
        return;
    }
    UIViewController *fromVC = [YBImageBrowserUtilities getTopController];
    [fromVC presentViewController:self animated:YES completion:nil];
}

- (void)hide {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notice_hide) name:YBImageBrowser_notificationName_hideSelf object:nil];
}

- (void)notice_hide {
    [self hide];
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
    [self.toolBar setTitleLabelWithCurrentIndex:index+1 totalCount:imageBrowserView.dataArray.count];
}

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView longPressBegin:(UILongPressGestureRecognizer *)gesture {
    if (self.fuctionDataArray.count > 1) {
        //弹出额外操作栏
        if (_functionBar) {
            [_functionBar show];
        }
    }
}

#pragma mark YBImageBrowserToolBarDelegate

- (void)yBImageBrowserToolBar:(YBImageBrowserToolBar *)imageBrowserToolBar didClickRightButton:(UIButton *)button {
    if (!self.fuctionDataArray.count) return;
    if (self.fuctionDataArray.count == 1 && [self.fuctionDataArray[0].ID isEqualToString:YBImageBrowserFunctionModel_ID_savePictureToAlbum]) {
        //直接保存图片
        [self savePhotoToAlbumWithCurrentIndex];
    } else {
        //弹出额外操作栏
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
        YBLOG(@"%@", NSStringFromSelector(_cmd))
    }
}

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    animatedTransitioningManager.currentModel = self.dataArray[self.currentIndex];
    animatedTransitioningManager.imageBrowser = self;
    return animatedTransitioningManager;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    animatedTransitioningManager.currentModel = self.dataArray[self.browserView.currentIndex];
    animatedTransitioningManager.imageBrowser = self;
    return animatedTransitioningManager;
}

//- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
//    return interactiveTransition;
//}

#pragma mark setter

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    _currentIndex = currentIndex;
    if (isDealViewDidAppear && _browserView) {
        [_browserView scrollToPageWithIndex:self.currentIndex animated:NO];
    }
}

- (void)setDataArray:(NSArray<YBImageBrowserModel *> *)dataArray {
    if (!dataArray || !dataArray.count) {
        YBLOG_WARNING(@"dataArray is invalid")
        return;
    }
    _dataArray = dataArray;
    self.browserView.dataArray = dataArray;
    [self.toolBar setTitleLabelWithCurrentIndex:1 totalCount:dataArray.count];
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
            YBLOG_WARNING(@"the only model in fuctionDataArray is invalid")
        }
    } else {
        [self.toolBar setRightButtonImage:YB_READIMAGE_FROMFILE(@"ybImageBrowser_more", @"png")];
        [self.toolBar setRightButtonTitle:nil];
        //functionBar 方法仅在此处调用其它地方均用实例变量方式访问
        self.functionBar.dataArray = fuctionDataArray;
    }
}

#pragma mark getter

- (YBImageBrowserView *)browserView {
    if (!_browserView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _browserView = [[YBImageBrowserView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _browserView.yb_delegate = self;
    }
    return _browserView;
}

- (YBImageBrowserToolBar *)toolBar {
    if (!_toolBar) {
        _toolBar = [YBImageBrowserToolBar new];
        _toolBar.delegate = self;
        [_toolBar setTitleLabelWithCurrentIndex:1 totalCount:self.dataArray.count];
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
    pthread_mutex_lock(&lock);
    [self resetUserInterfaceLayoutByDeviceOrientation];
    pthread_mutex_unlock(&lock);
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.yb_supportedInterfaceOrientations;
}

#pragma mark save photo to album

- (void)savePhotoToAlbumWithCurrentIndex {
    NSArray *dataArray = self.browserView.dataArray;
    NSUInteger currentIndex = self.browserView.currentIndex;
    if (currentIndex >= dataArray.count) {
        YBLOG_WARNING(@"currentIndex is out of range")
        return;
    }
    [self savePhotoToAlbumWithModel:dataArray[currentIndex] preview:NO];
}

- (void)savePhotoToAlbumWithModel:(YBImageBrowserModel *)model preview:(BOOL)preview {
    if (model.image) {
        [self judgeAlbumAuthorizationStatusSuccess:^{
            [self savePhotoToAlbumWithImage:model.image];
        }];
    } else if (model.animatedImage) {
        if (model.animatedImage.data) {
            [self judgeAlbumAuthorizationStatusSuccess:^{
                [self saveGifToAlbumWithData:model.animatedImage.data];
            }];
        } else {
            YBLOG_WARNING(@"instance of FLAnimatedImage is exist, but it's key-data is not exist, this maybe the BUG of the framework of FLAnimatedImage")
        }
    } else {
        if (!preview) {
            [self savePhotoToAlbumWithModel:model.previewModel preview:YES];
        } else {
            [self.view yb_showForkPromptWithText:self.copywriter.noImageDataToSave];
        }
    }
}

- (void)judgeAlbumAuthorizationStatusSuccess:(void(^)(void))success {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        [self.view yb_showForkPromptWithText:self.copywriter.albumAuthorizationDenied];
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
            [self.view yb_showHookPromptWithText:self.copywriter.saveImageDataToAlbumSuccessful];
        } else {
            [self.view yb_showForkPromptWithText:self.copywriter.saveImageDataToAlbumFailed];
        }
    }];
}

- (void)savePhotoToAlbumWithImage:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(completedWithImage:error:context:), (__bridge void *)self);
}

- (void)completedWithImage:(UIImage *)image error:(NSError *)error context:(void *)context {
    if (!error) {
        [self.view yb_showHookPromptWithText:self.copywriter.saveImageDataToAlbumSuccessful];
    } else {
        [self.view yb_showForkPromptWithText:self.copywriter.saveImageDataToAlbumFailed];
    }
}

@end
