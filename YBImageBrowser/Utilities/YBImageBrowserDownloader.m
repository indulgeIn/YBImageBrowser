//
//  YBImageBrowserDownloader.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/17.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserDownloader.h"
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/SDImageCache.h>

static SDImageCache *_imageCache = nil;

@interface YBImageBrowserDownloader ()

@property (class, strong) SDImageCache *imageCache;

@end

@implementation YBImageBrowserDownloader

#pragma mark public

+ (id)downloadWebImageWithUrl:(NSURL *)url progress:(YBImageBrowserDownloaderProgressBlock)progress success:(YBImageBrowserDownloaderSuccessBlock)success failed:(YBImageBrowserDownloaderFailedBlock)failed {
    if (!url) return nil;
    
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:SDWebImageDownloaderLowPriority|SDWebImageDownloaderScaleDownLargeImages progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        if (progress) progress(receivedSize, expectedSize, targetURL);
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        if (error) {
            if (failed) failed(error, finished);
            return;
        }
        
        if (success) success(image, data, finished);
    }];
    return token;
}

+ (void)cancelTaskWithDownloadToken:(id)token {
    if (token) [[SDWebImageDownloader sharedDownloader] cancel:token];
}

+ (void)storeImageDataWithKey:(NSString *)key image:(UIImage *)image data:(NSData *)data {
    if (!image) return;
    BOOL isGif = [YBImageBrowserUtilities isGif:data];
    if (isGif && !data) return;
    [self.imageCache storeImage:image imageData:isGif?data:nil forKey:key toDisk:YES completion:nil];
}

+ (void)memeryImageDataExistWithKey:(NSString *)key exist:(void (^)(BOOL))exist {
    if (exist) exist([self.imageCache diskImageDataExistsWithKey:key]);
}

+ (void)queryCacheOperationForKey:(NSString *)key completed:(YBImageBrowserDownloaderCacheQueryCompletedBlock)completed {
    if (!key) return;
    [self.imageCache queryCacheOperationForKey:key options:SDImageCacheQueryDataWhenInMemory|SDImageCacheQueryDiskSync done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (completed) completed(image, data);
    }];
}

#pragma mark imageCache

+ (void)setImageCache:(SDImageCache *)x {
    if (!self.imageCache) {
        _imageCache = x;
    }
}
+ (SDImageCache *)imageCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _imageCache = [SDImageCache sharedImageCache];
    });
    return _imageCache;
}

@end
