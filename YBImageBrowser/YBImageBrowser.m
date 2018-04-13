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

@interface YBImageBrowser () {
    CGRect frameOfSelfForOrientationPortrait;
    CGRect frameOfSelfForOrientationLandscapeRight;
    CGRect frameOfSelfForOrientationLandscapeLeft;
    CGRect frameOfSelfForOrientationPortraitUpsideDown;
    UIInterfaceOrientationMask supportAutorotateTypes;
    pthread_mutex_t lock;
}

@property (nonatomic, strong) YBImageBrowserView *browserView;

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
        [self initData];
        [self addNotification];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSupportAutorotateTypes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //此刻 statusBar 的方向才是当前控制器设定的方向
    [self initYBImageBrowserView];
    [self configFrameForStatusBarOrientation];
    [self addDeviceOrientationNotification];
}

#pragma mark private

//初始化数据
- (void)initData {
    pthread_mutex_init(&lock, NULL);
    self.verticalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
    self.horizontalScreenImageViewFillType = YBImageBrowserImageViewFillTypeFullWidth;
}

//初始化核心视图
- (void)initYBImageBrowserView {
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _browserView = [[YBImageBrowserView alloc] initWithFrame:[YBImageBrowserTool getNormalWindow].bounds collectionViewLayout:layout];
    _browserView.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
    _browserView.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
    _browserView.dataArray = self.dataArray;
    [self.view addSubview:_browserView];
}

//找到 keywidow 和当前 Controller 支持屏幕旋转方向的交集
- (void)configSupportAutorotateTypes {
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientationMask keyWindowSupport = [application supportedInterfaceOrientationsForWindow:[YBImageBrowserTool getNormalWindow]];
    UIInterfaceOrientationMask selfSupport = ![self shouldAutorotate] ? UIInterfaceOrientationMaskPortrait : [self supportedInterfaceOrientations];
    supportAutorotateTypes = keyWindowSupport & selfSupport;
}

//根据当前 statusBar 的方向，配置 statusBar 在不同方向下 self 的 frame
- (void)configFrameForStatusBarOrientation {
    CGRect frame = [YBImageBrowserTool getNormalWindow].bounds;
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
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
    [_browserView resetUserInterfaceLayout];
}

#pragma mark public

- (void)show {
    if (!_dataArray || _dataArray.count <= 0) {
        YBLogWarning(@"the dataArray is invalid");
        return;
    }
    [[YBImageBrowserTool getTopController] presentViewController:self animated:NO completion:nil];
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

#pragma mark setter

- (void)setDataArray:(NSArray<YBImageBrowserModel *> *)dataArray {
    if (!_dataArray) {
        _dataArray = dataArray;
    }
}

- (void)setYb_supportedInterfaceOrientations:(UIInterfaceOrientationMask)yb_supportedInterfaceOrientations {
    _yb_supportedInterfaceOrientations = yb_supportedInterfaceOrientations;
}

#pragma mark device orientation

- (void)addDeviceOrientationNotification {
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)deviceOrientationChanged:(NSNotification *)note {
    if (supportAutorotateTypes - (supportAutorotateTypes & (-supportAutorotateTypes)) == 0) {
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

@end
