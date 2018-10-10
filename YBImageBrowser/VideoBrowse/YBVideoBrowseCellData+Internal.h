//
//  YBVideoBrowseCellData+Internal.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/3.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBVideoBrowseCellData.h"

typedef NS_ENUM(NSInteger, YBVideoBrowseCellDataState) {
    YBVideoBrowseCellDataStateInvalid,
    YBVideoBrowseCellDataStateFirstFrameReady,
    
    YBVideoBrowseCellDataStateIsLoadingFirstFrame,
    YBVideoBrowseCellDataStateLoadFirstFrameSuccess,
    YBVideoBrowseCellDataStateLoadFirstFrameFailed,
    
    YBVideoBrowseCellDataStateIsLoadingPHAsset,
    YBVideoBrowseCellDataStateLoadPHAssetSuccess,
    YBVideoBrowseCellDataStateLoadPHAssetFailed
};

typedef NS_ENUM(NSInteger, YBVideoBrowseCellDataDownloadState) {
    YBVideoBrowseCellDataDownloadStateNone,
    YBVideoBrowseCellDataDownloadStateIsDownloading,
    YBVideoBrowseCellDataDownloadStateComplete
};

@interface YBVideoBrowseCellData ()

@property (nonatomic, assign) YBVideoBrowseCellDataState dataState;

@property (nonatomic, assign) YBVideoBrowseCellDataDownloadState dataDownloadState;

@property (nonatomic, assign) CGFloat downloadingVideoProgress;

- (void)loadData;

+ (CGRect)getImageViewFrameWithImageSize:(CGSize)size;

@end
