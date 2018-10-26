//
//  YBIBWebImageManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/29.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBWebImageManager.h"
#if __has_include(<SDWebImage/SDWebImageDownloader.h>)
#import <SDWebImage/SDWebImageDownloader.h>
#else
#import "SDWebImageDownloader.h"
#endif
#if __has_include(<SDWebImage/SDImageCache.h>)
#import <SDWebImage/SDImageCache.h>
#else
#import "SDImageCache.h"
#endif

static BOOL _downloaderShouldDecompressImages;
static BOOL _cacheShouldDecompressImages;

@implementation YBIBWebImageManager

#pragma mark public

+ (void)storeOutsideConfiguration {
    _downloaderShouldDecompressImages = [SDWebImageDownloader sharedDownloader].shouldDecompressImages;
    _cacheShouldDecompressImages = [SDImageCache sharedImageCache].config.shouldDecompressImages;
    [SDWebImageDownloader sharedDownloader].shouldDecompressImages = NO;
    [SDImageCache sharedImageCache].config.shouldDecompressImages = NO;
}

+ (void)restoreOutsideConfiguration {
    [SDWebImageDownloader sharedDownloader].shouldDecompressImages = _downloaderShouldDecompressImages;
    [SDImageCache sharedImageCache].config.shouldDecompressImages = _cacheShouldDecompressImages;
}

+ (id)downloadImageWithURL:(NSURL *)url progress:(YBIBWebImageManagerProgressBlock)progress success:(YBIBWebImageManagerSuccessBlock)success failed:(YBIBWebImageManagerFailedBlock)failed {
    if (!url) return nil;
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        if (progress) {
            progress(receivedSize, expectedSize, targetURL);
        }
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (error) {
            if (failed) failed(error, finished);
            return;
        }
        if (success) {
            success(image, data, finished);
        }
    }];
    return token;
}

+ (void)cancelTaskWithDownloadToken:(id)token {
    if (token) {
        [[SDWebImageDownloader sharedDownloader] cancel:token];
    }
}

+ (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSURL *)key toDisk:(BOOL)toDisk {
    [[SDImageCache sharedImageCache] storeImage:image imageData:data forKey:key.absoluteString toDisk:toDisk completion:nil];
}

+ (void)queryCacheOperationForKey:(NSURL *)key completed:(YBIBWebImageManagerCacheQueryCompletedBlock)completed {
    if (!key) return;
    SDImageCacheOptions options = SDImageCacheQueryDataWhenInMemory;
    [[SDImageCache sharedImageCache] queryCacheOperationForKey:key.absoluteString options:options done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (completed) {
            completed(image, data);
        }
    }];
}

@end
