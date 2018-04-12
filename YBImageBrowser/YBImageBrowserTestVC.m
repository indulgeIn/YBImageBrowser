//
//  YBImageBrowserTestVC.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTestVC.h"
#import "YBImageBrowserView.h"
#import <pthread.h>

@interface YBImageBrowserTestVC () {
    CGRect frameOfSelfForOrientationPortrait;
    CGRect frameOfSelfForOrientationLandscapeRight;
    CGRect frameOfSelfForOrientationLandscapeLeft;
    CGRect frameOfSelfForOrientationPortraitUpsideDown;
    UIInterfaceOrientationMask supportAutorotateTypes;
    pthread_mutex_t lock;
}

@property (nonatomic, strong) YBImageBrowserView *browserView;

@end

@implementation YBImageBrowserTestVC

#pragma mark life cycle

- (void)dealloc {
    pthread_mutex_destroy(&lock);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    pthread_mutex_init(&lock, NULL);
    [self configSupportAutorotateTypes];
    [self configFrameForStatusBarOrientation];
    [self addNotification];
    [self addDeviceOrientationNotification];
    [self initYBImageBrowserView];
}

#pragma mark private

- (void)initYBImageBrowserView {
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _browserView = [[YBImageBrowserView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds collectionViewLayout:layout];
    _browserView.dataArray = self.dataArray;
    [self.view addSubview:_browserView];
}

//找到 keywidow 和当前 Controller 支持屏幕旋转方向的交集
- (void)configSupportAutorotateTypes {
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientationMask keyWindowSupport = [application supportedInterfaceOrientationsForWindow:[YBImageBrowserTool getNormalWindow]];
    UIInterfaceOrientationMask selfSupport = ![self shouldAutorotate] ? UIInterfaceOrientationMaskPortrait : self.supportedInterfaceOrientations;
    supportAutorotateTypes = keyWindowSupport & selfSupport;
}

//根据当前 statusBar 的方向，配置 statusBar 在不同方向下 self 的 frame
- (void)configFrameForStatusBarOrientation {
    CGRect frame = [UIApplication sharedApplication].keyWindow.bounds;
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
    if (!_dataArray || _dataArray.count <= 0) return;

    [[YBImageBrowserTool getTopController] presentViewController:self animated:NO completion:nil];
}

- (void)hide {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notice_hide) name:YBImageBrowser_notice_hideSelf object:nil];
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

#pragma mark device orientation

- (void)addDeviceOrientationNotification {
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)deviceOrientationChanged:(NSNotification *)note{
    [self resetUserInterfaceLayoutByDeviceOrientation];
}

- (BOOL)shouldAutorotate {
    return NO;
}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskLandscapeRight;
//}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationPortrait;
//}

@end
