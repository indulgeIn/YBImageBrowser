//
//  YBIBWebImageManager.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/8/29.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "YBIBWebImageManager.h"
#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImage.h>
#else
#import "SDWebImage.h"
#endif

@implementation YBIBWebImageManager

#pragma mark public

+ (id)downloadImageWithURL:(NSURL *)url requestModifier:(nullable YBIBWebImageRequestModifierBlock)requestModifier progress:(nonnull YBIBWebImageProgressBlock)progress success:(nonnull YBIBWebImageSuccessBlock)success failed:(nonnull YBIBWebImageFailedBlock)failed {
    if (!url) return nil;
    
    SDWebImageContext *context = nil;
    if (requestModifier) {
        SDWebImageDownloaderRequestModifier *modifier = [SDWebImageDownloaderRequestModifier requestModifierWithBlock:requestModifier];
        context = @{SDWebImageContextDownloadRequestModifier:modifier};
    }
    
    SDWebImageDownloaderOptions options = SDWebImageDownloaderLowPriority | SDWebImageDownloaderAvoidDecodeImage;
    
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:options context:context progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        if (progress) progress(receivedSize, expectedSize);
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (error) {
            if (failed) failed(error, finished);
        } else {
            if (success) success(data, finished);
        }
    }];
    return token;
}

+ (void)cancelTaskWithDownloadToken:(id)token {
    if (token && [token isKindOfClass:SDWebImageDownloadToken.class]) {
        [((SDWebImageDownloadToken *)token) cancel];
    }
}

+ (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSURL *)key toDisk:(BOOL)toDisk {
    if (!key) return;
    NSString *cacheKey = [SDWebImageManager.sharedManager cacheKeyForURL:key];
    if (!cacheKey) return;
    
    // The 'image' must be existent, otherwise this methode will do nothing. (That is a strange design of SDWebImage 🐶)
    [[SDImageCache sharedImageCache] storeImage:image imageData:data forKey:cacheKey toDisk:toDisk completion:nil];
}

+ (void)queryCacheOperationForKey:(NSURL *)key completed:(YBIBWebImageCacheQueryCompletedBlock)completed {
#define QUERY_CACHE_FAILED if (completed) {completed(nil, nil); return;}
    if (!key) QUERY_CACHE_FAILED
    NSString *cacheKey = [SDWebImageManager.sharedManager cacheKeyForURL:key];
    if (!cacheKey) QUERY_CACHE_FAILED
#undef QUERY_CACHE_FAILED
    
    // 'NSData' of image must be read to ensure decoding correctly.
    SDImageCacheOptions options = SDImageCacheQueryMemoryData | SDImageCacheAvoidDecodeImage;
    [[SDImageCache sharedImageCache] queryCacheOperationForKey:cacheKey options:options done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (completed) completed(image, data);
    }];
}

@end
