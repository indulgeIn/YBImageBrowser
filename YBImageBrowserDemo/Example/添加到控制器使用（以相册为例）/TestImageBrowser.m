//
//  TestImageBrowser.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestImageBrowser.h"
#import "YBImageBrowser.h"
#import "YBIBVideoData.h"
#import "YBIBUtilities.h"

@interface TestImageBrowser () <YBImageBrowserDataSource>

@end

@implementation TestImageBrowser

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    /*
     用控制器包装处理起来有些麻烦，需要关闭很多效果
     */
    
    YBImageBrowser *browser = [YBImageBrowser new];
    // 禁止旋转（但是若当前控制器能旋转，图片浏览器也会跟随，布局可能会错位，这种情况还待处理）
    browser.supportedOrientations = UIInterfaceOrientationMaskPortrait;
    // 这里演示使用代理来处理数据源（当然用数组也可以）
    browser.dataSource = self;
    browser.currentPage = self.selectIndex;
    // 关闭入场和出场动效
    browser.defaultAnimatedTransition.showType = YBIBTransitionTypeNone;
    browser.defaultAnimatedTransition.hideType = YBIBTransitionTypeNone;
    // 删除工具视图（你可能需要自定义的工具视图，那请自己实现吧）
    browser.toolViewHandlers = @[];
    // 由于 self.view 的大小可能会变化，所以需要显式的赋值容器大小
    CGSize size = CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height - YBIBStatusbarHeight() - 44);
    [browser showToView:self.view containerSize:size];
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - <YBImageBrowserDataSource>

- (NSInteger)yb_numberOfCellsInImageBrowser:(YBImageBrowser *)imageBrowser {
    return self.imagePHAssets.count;
}

- (id<YBIBDataProtocol>)yb_imageBrowser:(YBImageBrowser *)imageBrowser dataForCellAtIndex:(NSInteger)index {
    
    PHAsset *asset = (PHAsset *)self.imagePHAssets[index];
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        
        // 系统相册的视频
        YBIBVideoData *data = [YBIBVideoData new];
        data.videoPHAsset = asset;
        data.interactionProfile.disable = YES;  //关闭手势交互
        data.shouldHideForkButton = YES;    //隐藏播放时的取消按钮
        data.singleTouchBlock = ^(YBIBVideoData * _Nonnull videoData) {};   //拦截单击事件
        return data;
        
    } else if (asset.mediaType == PHAssetMediaTypeImage) {
        
        // 系统相册的图片
        YBIBImageData *data = [YBIBImageData new];
        data.imagePHAsset = asset;
        data.interactionProfile.disable = YES;  //关闭手势交互
        data.singleTouchBlock = ^(YBIBImageData * _Nonnull imageData) {};   //拦截单击事件
        return data;
        
    }
    return nil;
}

@end
