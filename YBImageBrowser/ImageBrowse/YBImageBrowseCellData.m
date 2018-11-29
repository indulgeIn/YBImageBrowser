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
static CGSize _globalMaxTextureSize = (CGSize){4096, 4096};
static CGFloat _globalZoomScaleSurplus = 1.5;
static BOOL _shouldDecodeAsynchronously = YES;

@interface YBImageBrowseCellData () {
    __weak id _downloadToken;
}
@property (nonatomic, strong) YBImage *image;
@property (nonatomic, assign) BOOL    isLoading;
@end

@implementation YBImageBrowseCellData

#pragma mark - life cycle

- (void)dealloc {
    if (self->_downloadToken) {
        [YBIBWebImageManager cancelTaskWithDownloadToken:self->_downloadToken];
    }
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
    self->_allowShowSheetView = YES;
    
    self->_isCutting = NO;
    
    self->_isLoading = NO;
}

#pragma mark - <YBImageBrowserCellDataProtocol>

- (Class)yb_classOfBrowserCell {
    return YBImageBrowseCell.class;
}

- (id)yb_browserCellSourceObject {
    return self.sourceObject;
}

- (CGRect)yb_browserCurrentImageFrameWithImageSize:(CGSize)size {
    YBImageBrowseFillType fillType = [self getFillTypeWithLayoutDirection:[YBIBLayoutDirectionManager getLayoutDirectionByStatusBar]];
    return [self.class getImageViewFrameWithContainerSize:[self.class getSizeOfCurrentLayoutDirection] imageSize:size fillType:fillType];
}

- (BOOL)yb_browserAllowShowSheetView {
    return self.allowShowSheetView;
}

- (BOOL)yb_browserAllowSaveToPhotoAlbum {
    return self.allowSaveToPhotoAlbum;
}

- (void)yb_browserSaveToPhotoAlbum {
    [YBIBPhotoAlbumManager getPhotoAlbumAuthorizationSuccess:^{
        if ([self.image respondsToSelector:@selector(animatedImageData)] && self.image.animatedImageData) {
            [YBIBPhotoAlbumManager saveDataToAlbum:self.image.animatedImageData];
        } else if (self.image) {
            [YBIBPhotoAlbumManager saveImageToAlbum:self.image];
        } else if (self.url) {
            [YBIBWebImageManager queryCacheOperationForKey:self.url completed:^(UIImage * _Nullable image, NSData * _Nullable data) {
                if (data) {
                    YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        self.image = [YBImage imageWithData:data];
                        YBIB_GET_QUEUE_MAIN_ASYNC(^{
                            [YBIBPhotoAlbumManager saveImageToAlbum:self.image];
                        });
                    });
                } else {
                    [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].unableToSave];
                }
            }];
        } else {
            [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].unableToSave];
        }
    } failed:nil];
}

- (void)yb_preload {
    [self loadData];
}

#pragma mark - internal

- (void)loadData {
    if (self.isLoading) {
        YBImageBrowseCellDataState tmpState = self.dataState;
        if (self.thumbImage) {
            self.dataState = YBImageBrowseCellDataStateThumbImageReady;
        }
        self.dataState = tmpState;
        return;
    } else {
        self.isLoading = YES;
    }
    
    if (self.image) {
        [self loadLocalImage];
    } else if (self.imageBlock) {
        [self loadThumbImage];
        [self decodeLocalImage];
    } else if (self.url) {
        [self loadThumbImage];
        [self queryImageCache];
    } else if (self.phAsset) {
        [self loadThumbImage];
        [self loadImageFromPHAsset];
    } else {
        self.dataState = YBImageBrowseCellDataStateInvalid;
        self.isLoading = NO;
    }
}

- (void)loadLocalImage {
    if (!self.image) return;
    if ([self needCompress]) {
        if (self.compressImage) {
            self.dataState = YBImageBrowseCellDataStateCompressImageReady;
            self.isLoading = NO;
        } else {
            [self compressingImage];
        }
    } else {
        self.dataState = YBImageBrowseCellDataStateImageReady;
        self.isLoading = NO;
    }
}

- (void)decodeLocalImage {
    if (!self.imageBlock) return;
    
    self.dataState = YBImageBrowseCellDataStateIsDecoding;
    YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.image = self.imageBlock();
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            self.dataState = YBImageBrowseCellDataStateDecodeComplete;
            if (self.image) {
                [self loadLocalImage];
            }
        });
    });
}

- (void)loadImageFromPHAsset {
    if (!self.phAsset) return;
    
    self.dataState = YBImageBrowseCellDataStateIsLoadingPHAsset;
    
    static dispatch_queue_t assetQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetQueue = dispatch_queue_create("com.yangbo.ybimagebrowser.asset", DISPATCH_QUEUE_CONCURRENT);
    });
    
    dispatch_block_t block = ^{
        [YBIBPhotoAlbumManager getImageDataWithPHAsset:self.phAsset success:^(NSData *imgData) {
            self.image = [YBImage imageWithData:imgData];
            YBIB_GET_QUEUE_MAIN_ASYNC(^{
                self.dataState = YBImageBrowseCellDataStateLoadPHAssetSuccess;
                if (self.image) {
                    [self loadLocalImage];
                }
            });
        } failed:^{
            YBIB_GET_QUEUE_MAIN_ASYNC(^{
                self.dataState = YBImageBrowseCellDataStateLoadPHAssetFailed;
                self.isLoading = NO;
            });
        }];
    };
    
    YBIB_GET_QUEUE_ASYNC(assetQueue, ^{
        block();
    });
}

- (void)queryImageCache {
    if (!self.url) return;
   
    self.dataState = YBImageBrowseCellDataStateIsQueryingCache;
    [YBIBWebImageManager queryCacheOperationForKey:self.url completed:^(id _Nullable image, NSData * _Nullable imagedata) {
        
        YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (imagedata) {
                self.image = [YBImage imageWithData:imagedata];
            }
            
            YBIB_GET_QUEUE_MAIN_ASYNC(^{
                self.dataState = YBImageBrowseCellDataStateQueryCacheComplete;
                
                if (self.image) {
                    [self loadLocalImage];
                } else {
                    [self downloadImage];
                }
            });
        });
    }];
}

- (void)downloadImage {
    if (!self.url) return;
    
    self.dataState = YBImageBrowseCellDataStateIsDownloading;
    self->_downloadToken = [YBIBWebImageManager downloadImageWithURL:self.url progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        CGFloat value = receivedSize * 1.0 / expectedSize ?: 0;
        self->_downloadProgress = value;
        
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            self.dataState = YBImageBrowseCellDataStateDownloadProcess;
        })
    } success:^(UIImage * _Nullable image, NSData * _Nullable nsData, BOOL finished) {
        if (!finished) return;
        
        YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.image = [YBImage imageWithData:nsData];
            
            YBIB_GET_QUEUE_MAIN_ASYNC(^{
                [YBIBWebImageManager storeImage:self.image imageData:nsData forKey:self.url toDisk:YES];
                
                self.dataState = YBImageBrowseCellDataStateDownloadSuccess;
                if (self.image) {
                    [self loadLocalImage];
                }
            });
        });
        
    } failed:^(NSError * _Nullable error, BOOL finished) {
        if (!finished) return;
        self.dataState = YBImageBrowseCellDataStateDownloadFailed;
        self.isLoading = NO;
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
            if (image) {
                self.thumbImage = image;
            } else if (data) {
                self.thumbImage = [UIImage imageWithData:data];
            }
            
            // If the target image is ready, ignore the thumb image.
            if (self.dataState != YBImageBrowseCellDataStateCompressImageReady && self.dataState != YBImageBrowseCellDataStateImageReady) {
                self.dataState = YBImageBrowseCellDataStateThumbImageReady;
            }
        }];
    }
}

- (void)compressingImage {
    if (!self.image) return;
    
    self.dataState = YBImageBrowseCellDataStateIsCompressingImage;
    CGSize size = [self getSizeOfCompressing];
    
    YBIB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIGraphicsBeginImageContext(size);
        [self.image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        self->_compressImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            self.dataState = YBImageBrowseCellDataStateCompressImageComplete;
            [self loadLocalImage];
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
    YBImageBrowseFillType fillType = [self getFillTypeWithLayoutDirection:[YBIBLayoutDirectionManager getLayoutDirectionByStatusBar]];
    CGSize imageViewsize = [self.class getImageViewFrameWithContainerSize:[self.class getSizeOfCurrentLayoutDirection] imageSize:self.image.size fillType:fillType].size;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(floor(imageViewsize.width * scale), floor(imageViewsize.height * scale));
    return size;
}

#pragma mark - setter

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

+ (void)setGlobalZoomScaleSurplus:(CGFloat)globalZoomScaleSurplus {
    _globalZoomScaleSurplus = globalZoomScaleSurplus;
}

+ (void)setShouldDecodeAsynchronously:(BOOL)shouldDecodeAsynchronously {
    _shouldDecodeAsynchronously = shouldDecodeAsynchronously;
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

+ (CGFloat)globalZoomScaleSurplus {
    return _globalZoomScaleSurplus;
}

+ (BOOL)shouldDecodeAsynchronously {
    return _shouldDecodeAsynchronously;
}

@end
