//
//  TestFController.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/8/4.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestFController.h"
#import "YBIBPhotoAlbumManager.h"
#import "YBImageBrowser.h"
#import "YBIBVideoData.h"

@interface TestFController () <YBImageBrowserDataSource>

@end

@implementation TestFController

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [YBIBPhotoAlbumManager getPhotoAlbumAuthorizationSuccess:^{
            self.dataArray = [BaseFileManager imagePHAssets];
        } failed:^{}];
    }
    return self;
}

+ (NSString *)yb_title {
    return @"用代理配置数据源（以相册为例）";
}

#pragma mark - override

- (void)selectedIndex:(NSInteger)index {
    
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSource = self;
    browser.currentPage = index;
    [browser show];
}

#pragma mark - <YBImageBrowserDataSource>

- (NSInteger)yb_numberOfCellsInImageBrowser:(YBImageBrowser *)imageBrowser {
    return self.dataArray.count;
}

- (id<YBIBDataProtocol>)yb_imageBrowser:(YBImageBrowser *)imageBrowser dataForCellAtIndex:(NSInteger)index {
    
    PHAsset *asset = (PHAsset *)self.dataArray[index];
    if (asset.mediaType == PHAssetMediaTypeVideo) {

        // 系统相册的视频
        YBIBVideoData *data = [YBIBVideoData new];
        data.videoPHAsset = asset;
        data.projectiveView = [self viewAtIndex:index];
        return data;

    } else if (asset.mediaType == PHAssetMediaTypeImage) {

        // 系统相册的图片
        YBIBImageData *data = [YBIBImageData new];
        data.imagePHAsset = asset;
        data.projectiveView = [self viewAtIndex:index];
        return data;

    }
    
    return nil;
}

@end
