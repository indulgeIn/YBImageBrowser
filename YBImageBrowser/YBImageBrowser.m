//
//  YBImageBrowser.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBImageBrowserView.h"

@interface YBImageBrowser () {
    CGRect frameOfSelfForOrientationPortrait;
    CGRect frameOfSelfForOrientationLandscapeRight;
    CGRect frameOfSelfForOrientationLandscapeLeft;
    CGRect frameOfSelfForOrientationPortraitUpsideDown;
    
    UIInterfaceOrientationMask supportAutorotateTypes;
}

@property (nonatomic, strong) YBImageBrowserView *browserView;

@end

@implementation YBImageBrowser

#pragma mark life cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (instancetype)init {
    return [self initWithFrame:[UIScreen mainScreen].bounds];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configSupportAutorotateTypes];
        [self configFrameForDeviceOrientation];
        [self addNotification];
        [self addDeviceOrientationNotification];
        [self initYBImageBrowserView];
    }
    return self;
}

#pragma mark private
- (void)configSupportAutorotateTypes {
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientationMask keyWindowSupport = [application supportedInterfaceOrientationsForWindow:[YBImageBrowserTool getNormalWindow]];
    UIInterfaceOrientationMask topControllerSupport = [YBImageBrowserTool getTopController].supportedInterfaceOrientations;
    supportAutorotateTypes = keyWindowSupport & topControllerSupport;
}
- (void)configFrameForDeviceOrientation {
    CGRect frame = self.frame;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
        frameOfSelfForOrientationPortrait = frame;
        frameOfSelfForOrientationPortraitUpsideDown = frame;
        frameOfSelfForOrientationLandscapeLeft = CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
        frameOfSelfForOrientationLandscapeRight = frameOfSelfForOrientationLandscapeLeft;
    } else if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        frameOfSelfForOrientationPortrait = CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
        frameOfSelfForOrientationPortraitUpsideDown = frameOfSelfForOrientationPortrait;
        frameOfSelfForOrientationLandscapeLeft = frame;
        frameOfSelfForOrientationLandscapeRight = frame;
    } 
}
- (void)initYBImageBrowserView {
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _browserView = [[YBImageBrowserView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
}

#pragma mark public
- (void)show {
    [self showToView:[UIApplication sharedApplication].keyWindow];
}
- (void)showToView:(UIView *)view {
    if (!_dataArray || _dataArray.count <= 0) return;
    [self addSubview:self.browserView];
    [view addSubview:self];
}
- (void)hide {
    [self removeFromSuperview];
}

#pragma mark notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notice_hide) name:YBImageBrowser_notice_hideSelf object:nil];
}
- (void)notice_hide {
    [self hide];
}

#pragma mark device orientation
- (void)addDeviceOrientationNotification {
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}
- (void)orientationChanged:(NSNotification *)note{
    CGRect *tagetRect = NULL;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationPortrait && (supportAutorotateTypes & UIInterfaceOrientationMaskPortrait)) {
        tagetRect = &frameOfSelfForOrientationPortrait;
    } else if(orientation == UIDeviceOrientationLandscapeRight && (supportAutorotateTypes & UIInterfaceOrientationMaskLandscapeLeft)) {
        tagetRect = &frameOfSelfForOrientationLandscapeRight;
    } else if (orientation == UIDeviceOrientationLandscapeLeft && (supportAutorotateTypes & UIInterfaceOrientationMaskLandscapeRight)) {
        tagetRect = &frameOfSelfForOrientationLandscapeLeft;
    } else if (orientation == UIDeviceOrientationPortraitUpsideDown && (supportAutorotateTypes & UIInterfaceOrientationMaskPortraitUpsideDown)) {
        tagetRect = &frameOfSelfForOrientationPortraitUpsideDown;
    } else {
        return;
    }
    self.frame = *tagetRect;
    [_browserView resetUserInterfaceLayout];
}

#pragma mark setter
- (void)setDataArray:(NSArray<YBImageBrowserModel *> *)dataArray {
    if (!_dataArray) {
        _dataArray = dataArray;
        _browserView.dataArray = dataArray;
    }
}

@end
