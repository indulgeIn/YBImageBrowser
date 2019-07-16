//
//  YBIBImageData+Internal.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/12.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBImageData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBIBImageLoadingStatus) {
    YBIBImageLoadingStatusNone,
    YBIBImageLoadingStatusCompressing,
    YBIBImageLoadingStatusDecoding,
    YBIBImageLoadingStatusQuerying,
    YBIBImageLoadingStatusProcessing,
    YBIBImageLoadingStatusDownloading,
    YBIBImageLoadingStatusReadingPHAsset,
};

@class YBIBImageData;

@protocol YBIBImageDataDelegate <NSObject>
@required

- (void)yb_imageData:(YBIBImageData *)data startLoadingWithStatus:(YBIBImageLoadingStatus)status;

- (void)yb_imageIsInvalidForData:(YBIBImageData *)data;

- (void)yb_imageData:(YBIBImageData *)data readyForImage:(__kindof UIImage *)image;

- (void)yb_imageData:(YBIBImageData *)data readyForThumbImage:(__kindof UIImage *)image;

- (void)yb_imageData:(YBIBImageData *)data readyForCompressedImage:(__kindof UIImage *)image;

- (void)yb_imageData:(YBIBImageData *)data downloadProgress:(CGFloat)progress;

- (void)yb_imageDownloadFailedForData:(YBIBImageData *)data;

@end

@interface YBIBImageData ()

@property (nonatomic, weak) id<YBIBImageDataDelegate> delegate;

/// The status of asynchronous tasks.
@property (nonatomic, assign) YBIBImageLoadingStatus loadingStatus;

/// The origin image.
@property (nonatomic, strong) UIImage *originImage;

/// The image compressed by 'originImage' if need.
@property (nonatomic, strong) UIImage *compressedImage;

- (BOOL)shouldCompress;

- (void)cuttingImageToRect:(CGRect)rect complete:(void(^)(UIImage * _Nullable image))complete;

@end

NS_ASSUME_NONNULL_END
