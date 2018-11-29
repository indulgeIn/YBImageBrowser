//
//  YBImageBrowseCellData+Internal.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/2.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowseCellData.h"
#import "YBIBLayoutDirectionManager.h"

typedef NS_ENUM(NSInteger, YBImageBrowseCellDataState) {
    YBImageBrowseCellDataStateInvalid,
    YBImageBrowseCellDataStateImageReady,
    YBImageBrowseCellDataStateCompressImageReady,
    
    YBImageBrowseCellDataStateThumbImageReady,
    
    YBImageBrowseCellDataStateIsDecoding,
    YBImageBrowseCellDataStateDecodeComplete,
    
    YBImageBrowseCellDataStateIsCompressingImage,
    YBImageBrowseCellDataStateCompressImageComplete,
    
    YBImageBrowseCellDataStateIsLoadingPHAsset,
    YBImageBrowseCellDataStateLoadPHAssetSuccess,
    YBImageBrowseCellDataStateLoadPHAssetFailed,
    
    YBImageBrowseCellDataStateIsQueryingCache,
    YBImageBrowseCellDataStateQueryCacheComplete,
    
    YBImageBrowseCellDataStateIsDownloading,
    YBImageBrowseCellDataStateDownloadProcess,
    YBImageBrowseCellDataStateDownloadSuccess,
    YBImageBrowseCellDataStateDownloadFailed,
};

@interface YBImageBrowseCellData ()

@property (nonatomic, assign) YBImageBrowseCellDataState dataState;

@property (nonatomic, strong) UIImage *compressImage;
@property (nonatomic, assign) CGFloat downloadProgress;
@property (nonatomic, assign) BOOL    isCutting;

- (void)loadData;

- (void)cuttingImageToRect:(CGRect)rect complete:(void(^)(UIImage *image))complete;

- (BOOL)needCompress;

- (YBImageBrowseFillType)getFillTypeWithLayoutDirection:(YBImageBrowserLayoutDirection)layoutDirection;

+ (CGFloat)getMaximumZoomScaleWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize fillType:(YBImageBrowseFillType)fillType;

+ (CGRect)getImageViewFrameWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize fillType:(YBImageBrowseFillType)fillType;

+ (CGSize)getContentSizeWithContainerSize:(CGSize)containerSize imageViewFrame:(CGRect)imageViewFrame;

@end
