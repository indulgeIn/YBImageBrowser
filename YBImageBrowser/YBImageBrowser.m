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

@interface YBImageBrowser () <YBImageBrowserViewDelegate, YBImageBrowserToolBarDelegate, YBImageBrowserFunctionBarDelegate> {
    CGRect frameOfSelfForOrientationPortrait;
    CGRect frameOfSelfForOrientationLandscapeRight;
    CGRect frameOfSelfForOrientationLandscapeLeft;
    CGRect frameOfSelfForOrientationPortraitUpsideDown;
    UIInterfaceOrientationMask supportAutorotateTypes;
    pthread_mutex_t lock;
    UIWindow *window;
    BOOL isDealViewWillAppear;
}

@property (nonatomic, strong) YBImageBrowserView *browserView;
@property (nonatomic, strong) YBImageBrowserToolBar *toolBar;
@property (nonatomic, strong) YBImageBrowserFunctionBar *functionBar;

@end

@implementation YBImageBrowser

#pragma mark life cycle

- (void)dealloc {
    pthread_mutex_destroy(&lock);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self initData];
        [self addNotification];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSupportAutorotateTypes];
    [self.view addSubview:self.browserView];
    [self.view addSubview:self.toolBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //此刻 statusBar 的方向才是当前控制器设定的方向
    if (!isDealViewWillAppear) {
        [self.browserView resetUserInterfaceLayout];
        [self.toolBar resetUserInterfaceLayout];
        [self.browserView scrollToPageWithIndex:self.currentIndex animated:NO];
        [self configFrameForStatusBarOrientation];
        [self addDeviceOrientationNotification];
        isDealViewWillAppear = YES;
    }
}

- (BOOL)prefersStatusBarHidden {
    return !self.showStatusBar;
}

#pragma mark private

//初始化数据
- (void)initData {
    isDealViewWillAppear = NO;
    _showStatusBar = NO;
    pthread_mutex_init(&lock, NULL);
    window = [YBImageBrowserUtilities getNormalWindow];
    self.verticalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    self.horizontalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    self.fuctionDataArray = @[[YBImageBrowserFunctionModel functionModelForSavePictureToAlbum]];
}

//找到 keywidow 和当前 Controller 支持屏幕旋转方向的交集
- (void)configSupportAutorotateTypes {
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientationMask keyWindowSupport = [application supportedInterfaceOrientationsForWindow:window];
    UIInterfaceOrientationMask selfSupport = ![self shouldAutorotate] ? UIInterfaceOrientationMaskPortrait : [self supportedInterfaceOrientations];
    supportAutorotateTypes = keyWindowSupport & selfSupport;
}

//根据当前 statusBar 的方向，配置 statusBar 在不同方向下 self 的 frame
- (void)configFrameForStatusBarOrientation {
    CGRect frame = window.bounds;
    UIInterfaceOrientation statusBarOrientation = YB_STATUSBAR_ORIENTATION;
    if (statusBarOrientation == UIInterfaceOrientationPortrait || statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        frameOfSelfForOrientationPortrait = frame;
        frameOfSelfForOrientationPortraitUpsideDown = frame;
        frameOfSelfForOrientationLandscapeLeft = CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
        frameOfSelfForOrientationLandscapeRight = frameOfSelfForOrientationLandscapeLeft;
    } else if(statusBarOrientation == UIInterfaceOrientationLandscapeLeft || statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        frameOfSelfForOrientationPortrait = CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
        frameOfSelfForOrientationPortraitUpsideDown = frameOfSelfForOrientationPortrait;
        frameOfSelfForOrientationLandscapeLeft = frame;
        frameOfSelfForOrientationLandscapeRight = frame;
    }
}

//根据 device 方向改变 UI
- (void)resetUserInterfaceLayoutByDeviceOrientation {
    CGRect *tagetRect = NULL;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationPortrait && (supportAutorotateTypes & UIInterfaceOrientationMaskPortrait)) {
        tagetRect = &frameOfSelfForOrientationPortrait;
    } else if(deviceOrientation == UIDeviceOrientationLandscapeRight && (supportAutorotateTypes & UIInterfaceOrientationMaskLandscapeLeft)) {
        tagetRect = &frameOfSelfForOrientationLandscapeLeft;
    } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft && (supportAutorotateTypes & UIInterfaceOrientationMaskLandscapeRight)) {
        tagetRect = &frameOfSelfForOrientationLandscapeRight;
    } else if (deviceOrientation == UIInterfaceOrientationPortraitUpsideDown && (supportAutorotateTypes & UIInterfaceOrientationMaskPortraitUpsideDown)) {
        tagetRect = &frameOfSelfForOrientationPortraitUpsideDown;
    } else {
        return;
    }
    self.view.frame = *tagetRect;
    [self.browserView resetUserInterfaceLayout];
    [self.toolBar resetUserInterfaceLayout];
    if (_functionBar && _functionBar.superview) {
        [_functionBar hideWithAnimate:NO];
    }
}

#pragma mark public

- (void)show {
    if (!_dataArray || !_dataArray.count) {
        YBLOG_WARNING(@"dataArray is invalid")
        return;
    }
    [[YBImageBrowserUtilities getTopController] presentViewController:self animated:NO completion:nil];
}

- (void)hide {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notice_hide) name:YBImageBrowser_notificationName_hideSelf object:nil];
}

- (void)notice_hide {
    [self hide];
}

#pragma mark YBImageBrowserViewDelegate

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView didScrollToIndex:(NSUInteger)index {
    [self.toolBar setTitleLabelWithCurrentIndex:index+1 totalCount:imageBrowserView.dataArray.count];
}

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView longPressBegin:(UILongPressGestureRecognizer *)gesture {
    if (self.fuctionDataArray.count > 1) {
        //弹出额外操作栏
        if (_functionBar) {
            [_functionBar showToView:self.view];
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
            [_functionBar showToView:self.view];
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

#pragma mark setter

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    _currentIndex = currentIndex;
    if (_browserView) {
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
        _browserView.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
        _browserView.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
        _browserView.dataArray = self.dataArray;
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
            [self.view showForkWithText:self.copywriter.noImageDataToSave];
        }
    }
}

- (void)judgeAlbumAuthorizationStatusSuccess:(void(^)(void))success {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        [self.view showForkWithText:self.copywriter.albumAuthorizationDenied];
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
            [self.view showHookWithText:self.copywriter.saveImageDataToAlbumSuccessful];
        } else {
            [self.view showHookWithText:self.copywriter.saveImageDataToAlbumFailed];
        }
    }];
}

- (void)savePhotoToAlbumWithImage:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(completedWithImage:error:context:), (__bridge void *)self);
}

- (void)completedWithImage:(UIImage *)image error:(NSError *)error context:(void *)context {
    if (!error) {
        [self.view showHookWithText:self.copywriter.saveImageDataToAlbumSuccessful];
    } else {
        [self.view showHookWithText:self.copywriter.saveImageDataToAlbumFailed];
    }
}

@end
