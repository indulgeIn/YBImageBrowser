//
//  YBIBVideoData+Internal.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/11.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class YBIBVideoData;

@protocol YBIBVideoDataDelegate <NSObject>
@required

- (void)yb_startLoadingAVAssetFromPHAssetForData:(YBIBVideoData *)data;

- (void)yb_finishLoadingAVAssetFromPHAssetForData:(YBIBVideoData *)data;

- (void)yb_startLoadingFirstFrameForData:(YBIBVideoData *)data;

- (void)yb_finishLoadingFirstFrameForData:(YBIBVideoData *)data;

- (void)yb_videoData:(YBIBVideoData *)data downloadingWithProgress:(CGFloat)progress;

- (void)yb_finishDownloadingForData:(YBIBVideoData *)data;

- (void)yb_videoData:(YBIBVideoData *)data readyForThumbImage:(UIImage *)image;

- (void)yb_videoData:(YBIBVideoData *)data readyForAVAsset:(AVAsset *)asset;

- (void)yb_videoIsInvalidForData:(YBIBVideoData *)data;

@end

@interface YBIBVideoData ()

@property (nonatomic, assign, getter=isLoadingAVAssetFromPHAsset) BOOL loadingAVAssetFromPHAsset;

@property (nonatomic, assign, getter=isLoadingFirstFrame) BOOL loadingFirstFrame;

@property (nonatomic, assign, getter=isDownloading) BOOL downloading;

@property (nonatomic, weak) id<YBIBVideoDataDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
