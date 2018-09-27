//
//  YBImageBrowseCellData.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowseCellData.h"
#import "YBImageBrowseCellData+Internal.h"
#import "YBImageBrowseCell.h"
#import "YBImageBrowser.h"
#import "YBIBWebImageManager.h"
#import "YBIBPhotoAlbumManager.h"
#import "YBIBUtilities.h"
#import "YBIBPhotoAlbumManager.h"
#import "YBImageBrowserTipView.h"
#import "YBIBCopywriter.h"

static YBImageBrowseFillType _globalVerticalfillType = YBImageBrowseFillTypeFullWidth;
static YBImageBrowseFillType _globalHorizontalfillType = YBImageBrowseFillTypeFullWidth;
static BOOL _precutLargeImage = YES;
static CGSize _globalMaxTextureSize = (CGSize){4096, 4096};
static CGFloat _globalZoomScaleSurplus = 1.5;

@interface YBImageBrowseCellData () {
    __weak id _downloadToken;
}
@end

@implementation YBImageBrowseCellData

#pragma mark - life cycle

- (void)dealloc {
    if (self->_downloadToken) [YBIBWebImageManager cancelTaskWithDownloadToken:self->_downloadToken];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
    }
    return self;
}

- (void)initVars {
    self->_maxZoomScale = 0;
    self->_verticalfillType = YBImageBrowseFillTypeUnknown;
    self->_horizontalfillType = YBImageBrowseFillTypeUnknown;
    self->_allowSaveToPhotoAlbum = YES;
    
    self->_isCutting = NO;
}

#pragma mark - <YBImageBrowserCellDataProtocol>

- (Class)yb_classOfBrowserCell {
    return YBImageBrowseCell.class;
}

- (id)yb_browserCellSourceObject {
    return self.sourceObject;
}

- (CGRect)yb_browserCurrentImageFrameWithImageSize:(CGSize)size {
    return [self.class getImageViewFrameWithContainerSize:[self.class getSizeOfCurrentLayoutDirection] imageSize:size fillType:[self getFillTypeWithLayoutDirection:[YBIBLayoutDirectionManager getLayoutDirectionByStatusBar]]];
}

- (BOOL)yb_browserAllowSaveToPhotoAlbum {
    return self.allowSaveToPhotoAlbum;
}

- (void)yb_browserSaveToPhotoAlbum {
    [YBIBPhotoAlbumManager getPhotoAlbumAuthorizationSuccess:^{
        if (self.image.animatedImageData) {
            [YBIBPhotoAlbumManager saveDataToAlbum:self.image.animatedImageData];
        } else if (self.image) {
            [YBIBPhotoAlbumManager saveImageToAlbum:self.image];
        } else if (self.url) {
            [YBIBWebImageManager queryCacheOperationForKey:self.url completed:^(UIImage * _Nullable image, NSData * _Nullable data) {
                if (data) {
                    self.image = [YBImage imageWithData:data];
                    [YBIBPhotoAlbumManager saveImageToAlbum:self.image];
                } else {
                    [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].unableToSave];
                }
            }];
        } else {
            [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].unableToSave];
        }
    } failed:nil];
}

#pragma mark - public

- (void)preload {
    [self loadWithPre:YES];
}

#pragma mark - internal

- (void)loadWithPre:(BOOL)pre {
    if (self.image) {
        [self loadLocalImageWithPre:pre];
    } else if (self.url) {
        if (!pre) [self loadThumbImage];
        [self queryImageCacheWithPre:pre];
    } else if (self.phAsset) {
        if (!pre) [self loadThumbImage];
        [self loadImageFromPHAssetWithPre:pre];
    } else {
        self.dataState = YBImageBrowseCellDataStateInvalid;
    }
}

- (void)loadLocalImageWithPre:(BOOL)pre {
    if (!self.image) return;
    if ([self needCompress]) {
        if (self.compressImage) {
            self.dataState = YBImageBrowseCellDataStateCompressImageReady;
        } else if (pre ? YBImageBrowseCellData.precutLargeImage : YES) {
            [self compressingImageWithPre:pre];
        }
    } else {
        self.dataState = YBImageBrowseCellDataStateImageReady;
    }
}

- (void)loadImageFromPHAssetWithPre:(BOOL)pre {
    if (!self.phAsset) return;
    if (self.dataState == YBImageBrowseCellDataStateIsLoadingPHAsset) {
        self.dataState = YBImageBrowseCellDataStateIsLoadingPHAsset;
        return;
    }
    
    self.dataState = YBImageBrowseCellDataStateIsLoadingPHAsset;
    [YBIBPhotoAlbumManager getImageDataWithPHAsset:self.phAsset success:^(NSData *imgData) {
        self.image = [YBImage imageWithData:imgData];
        
        self.dataState = YBImageBrowseCellDataStateLoadPHAssetSuccess;
        [self loadLocalImageWithPre:pre];
    } failed:^{
        self.dataState = YBImageBrowseCellDataStateLoadPHAssetFailed;
    }];
}

- (void)queryImageCacheWithPre:(BOOL)pre {
    if (!self.url) return;
    if (self.dataState == YBImageBrowseCellDataStateIsQueryingCache) {
        self.dataState = YBImageBrowseCellDataStateIsQueryingCache;
        return;
    }
    
    self.dataState = YBImageBrowseCellDataStateIsQueryingCache;
    [YBIBWebImageManager queryCacheOperationForKey:self.url completed:^(id _Nullable image, NSData * _Nullable imagedata) {
        if (imagedata)
            self.image = [YBImage imageWithData:imagedata];
        
        self.dataState = YBImageBrowseCellDataStateQueryCacheComplete;
        
        if (self.image)
            [self loadLocalImageWithPre:pre];
        else
            [self downloadImageWithPre:pre];
    }];
}

- (void)downloadImageWithPre:(BOOL)pre {
    if (!self.url) return;
    if (self.dataState == YBImageBrowseCellDataStateIsDownloading) {
        self.dataState = YBImageBrowseCellDataStateIsDownloading;
        return;
    }
    
    self.dataState = YBImageBrowseCellDataStateIsDownloading;
    self->_downloadToken = [YBIBWebImageManager downloadImageWithURL:self.url progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        CGFloat value = receivedSize * 1.0 / expectedSize ?: 0;
        self->_downloadProgress = value;
        
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            self.dataState = YBImageBrowseCellDataStateDownloadProcess;
        })
    } success:^(UIImage * _Nullable image, NSData * _Nullable nsData, BOOL finished) {
        if (!finished) return;
        self.image = [YBImage imageWithData:nsData];
        [YBIBWebImageManager storeImage:self.image imageData:nsData forKey:self.url toDisk:YES];
        
        self.dataState = YBImageBrowseCellDataStateDownloadSuccess;
        [self loadLocalImageWithPre:pre];
    } failed:^(NSError * _Nullable error, BOOL finished) {
        if (!finished) return;
        self.dataState = YBImageBrowseCellDataStateDownloadFailed;
    }];
}

- (void)loadThumbImage {
    if (self.thumbImage) {
        self.dataState = YBImageBrowseCellDataStateThumbImageReady;
    } else if (self.sourceObject && [self.sourceObject isKindOfClass:UIImageView.class] && ((UIImageView *)self.sourceObject).image) {
        self.thumbImage = ((UIImageView *)self.sourceObject).image;
        self.dataState = YBImageBrowseCellDataStateThumbImageReady;
    } else if (self.thumbUrl) {
        [YBIBWebImageManager queryCacheOperationForKey:self.thumbUrl completed:^(UIImage * _Nullable image, NSData * _Nullable data) {
            if (image)
                self.thumbImage = image;
            else if (data)
                self.thumbImage = [UIImage imageWithData:data];
            
            // If the target image is ready, ignore the thumb image.
            if (self.dataState != YBImageBrowseCellDataStateCompressImageReady && self.dataState != YBImageBrowseCellDataStateImageReady)
                self.dataState = YBImageBrowseCellDataStateThumbImageReady;
        }];
    }
}

- (void)compressingImageWithPre:(BOOL)pre {
    if (!self.image) return;
    if (self.dataState == YBImageBrowseCellDataStateIsCompressingImage) {
        self.dataState = YBImageBrowseCellDataStateIsCompressingImage;
        return;
    }
    
    self.dataState = YBImageBrowseCellDataStateIsCompressingImage;
    CGSize size = [self getSizeOfCompressing];
    YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIGraphicsBeginImageContext(size);
        [self.image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        self->_compressImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            self.dataState = YBImageBrowseCellDataStateCompressImageComplete;
            [self loadLocalImageWithPre:pre];
        })
    })
}

- (void)cuttingImageToRect:(CGRect)rect complete:(void(^)(UIImage *image))complete {
    if (!self.image) return;
    if (self->_isCutting) return;
    
    self->_isCutting = YES;
    YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef cgImage = CGImageCreateWithImageInRect(self.image.CGImage, rect);
        UIImage *resultImg = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            self->_isCutting = NO;
            if (complete) complete(resultImg);
        })
    })
}

- (YBImageBrowseFillType)getFillTypeWithLayoutDirection:(YBImageBrowserLayoutDirection)layoutDirection {
    YBImageBrowseFillType fillType;
    if (layoutDirection == YBImageBrowserLayoutDirectionHorizontal) {
        fillType = self.horizontalfillType == YBImageBrowseFillTypeUnknown ? YBImageBrowseCellData.globalHorizontalfillType : self.horizontalfillType;
    } else {
        fillType = self.verticalfillType == YBImageBrowseFillTypeUnknown ? YBImageBrowseCellData.globalVerticalfillType : self.verticalfillType;
    }
    return fillType == YBImageBrowseFillTypeUnknown ? YBImageBrowseFillTypeFullWidth : fillType;
}

- (BOOL)needCompress {
    if (!self.image) return NO;
    return YBImageBrowseCellData.globalMaxTextureSize.width * YBImageBrowseCellData.globalMaxTextureSize.height < self.image.size.width * self.image.scale * self.image.size.height * self.image.scale;
}

+ (CGFloat)getMaximumZoomScaleWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize fillType:(YBImageBrowseFillType)fillType {
    if (containerSize.width <= 0 || containerSize.height <= 0) return 0;
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale <= 0) return 0;
    CGFloat widthScale = imageSize.width / scale / containerSize.width,
    heightScale = imageSize.height / scale / containerSize.height,
    maxScale = 1;
    switch (fillType) {
        case YBImageBrowseFillTypeFullWidth:
            maxScale = widthScale;
            break;
        case YBImageBrowseFillTypeCompletely:
            maxScale = MAX(widthScale, heightScale);
            break;
        case YBImageBrowseFillTypeUnknown: break;
    }
    return MAX(maxScale, 1) * YBImageBrowseCellData.globalZoomScaleSurplus;
}

+ (CGRect)getImageViewFrameWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize fillType:(YBImageBrowseFillType)fillType {
    if (containerSize.width <= 0 || containerSize.height <= 0 || imageSize.width <= 0 || imageSize.height <= 0) return CGRectZero;
    CGFloat x = 0, y = 0, width = 0, height = 0;
    switch (fillType) {
        case YBImageBrowseFillTypeFullWidth: {
            x = 0;
            width = containerSize.width;
            height = containerSize.width * (imageSize.height / imageSize.width);
            if (imageSize.width / imageSize.height >= containerSize.width / containerSize.height)
                y = (containerSize.height - height) / 2.0;
            else
                y = 0;
        }
            break;
        case YBImageBrowseFillTypeCompletely: {
            if (imageSize.width / imageSize.height >= containerSize.width / containerSize.height) {
                width = containerSize.width;
                height = containerSize.width * (imageSize.height / imageSize.width);
                x = 0;
                y = (containerSize.height - height) / 2.0;
            } else {
                height = containerSize.height;
                width = containerSize.height * (imageSize.width / imageSize.height);
                x = (containerSize.width - width) / 2.0;
                y = 0;
            }
        }
            break;
        case YBImageBrowseFillTypeUnknown: break;
    }
    return CGRectMake(x, y, width, height);
}

+ (CGSize)getContentSizeWithContainerSize:(CGSize)containerSize imageViewFrame:(CGRect)imageViewFrame {
    return CGSizeMake(MAX(containerSize.width, imageViewFrame.size.width), MAX(containerSize.height, imageViewFrame.size.height));
}

#pragma mark - private

+ (CGSize)getSizeOfCurrentLayoutDirection {
    return [YBIBLayoutDirectionManager getLayoutDirectionByStatusBar] == YBImageBrowserLayoutDirectionHorizontal ? CGSizeMake(YBIMAGEBROWSER_HEIGHT, YBIMAGEBROWSER_WIDTH) : CGSizeMake(YBIMAGEBROWSER_WIDTH, YBIMAGEBROWSER_HEIGHT);
}

- (CGSize)getSizeOfCompressing {
    CGSize containerSize = [self.class getSizeOfCurrentLayoutDirection];
    YBImageBrowseFillType fillType = [self getFillTypeWithLayoutDirection:[YBIBLayoutDirectionManager getLayoutDirectionByStatusBar]];
    CGSize imageViewsize = [self.class getImageViewFrameWithContainerSize:containerSize imageSize:self.image.size fillType:fillType].size;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(floor(imageViewsize.width * scale), floor(imageViewsize.height * scale));
    return size;
}

#pragma mark - setter

- (void)setImage:(YBImage *)image {
    _image = image;
    
    if ([self needCompress] && !self.compressImage && YBImageBrowseCellData.precutLargeImage)
        [self compressingImageWithPre:YES];
}

- (void)setUrl:(NSURL *)url {
    _url = [url isKindOfClass:NSString.class] ? [NSURL URLWithString:(NSString *)url] : url;
}

+ (void)setGlobalVerticalfillType:(YBImageBrowseFillType)globalVerticalfillType {
    _globalVerticalfillType = globalVerticalfillType;
}

+ (void)setGlobalHorizontalfillType:(YBImageBrowseFillType)globalHorizontalfillType {
    _globalHorizontalfillType = globalHorizontalfillType;
}

+ (void)setGlobalMaxTextureSize:(CGSize)globalMaxTextureSize {
    _globalMaxTextureSize = globalMaxTextureSize;
}

+ (void)setPrecutLargeImage:(BOOL)precutLargeImage {
    _precutLargeImage = precutLargeImage;
}

+ (void)setGlobalZoomScaleSurplus:(CGFloat)globalZoomScaleSurplus {
    _globalZoomScaleSurplus = globalZoomScaleSurplus;
}

#pragma mark - getter

+ (YBImageBrowseFillType)globalVerticalfillType {
    return _globalVerticalfillType;
}

+ (YBImageBrowseFillType)globalHorizontalfillType {
    return _globalHorizontalfillType;
}

+ (CGSize)globalMaxTextureSize {
    return _globalMaxTextureSize;
}

+ (BOOL)precutLargeImage {
    return _precutLargeImage;
}

+ (CGFloat)globalZoomScaleSurplus {
    return _globalZoomScaleSurplus;
}

@end
