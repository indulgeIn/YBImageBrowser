//
//  YBImageBrowserDownloader.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserDownloader.h"
#import <SDWebImage/SDWebImageDownloader.h>

@implementation YBImageBrowserDownloader

+ (void)downloadImageWithURL:(NSURL *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progress success:(void(^)(UIImage *image))success failed:(void(^)(void))failed {
    
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:SDWebImageDownloaderScaleDownLargeImages|SDWebImageDownloaderProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        if (progress) progress(receivedSize, expectedSize);
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        if (error) {
            failed();
        } else {
            success(image);
        }
        
    }];
}

@end
