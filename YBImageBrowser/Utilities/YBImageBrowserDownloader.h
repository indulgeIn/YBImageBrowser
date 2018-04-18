//
//  YBImageBrowserDownloader.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/17.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

/*
    该类将 SDWebImage 相关逻辑提取出来，若换成其他图片处理框架（如 YYImage）可直接改这里
 */

NS_ASSUME_NONNULL_BEGIN

typedef void(^YBImageBrowserDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);
typedef void(^YBImageBrowserDownloaderSuccessBlock)(UIImage * _Nullable image, NSData * _Nullable data, BOOL finished);
typedef void(^YBImageBrowserDownloaderFailedBlock)(NSError * _Nullable error, BOOL finished);
typedef void(^YBImageBrowserDownloaderCacheQueryCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable data);

@interface YBImageBrowserDownloader : NSObject

//执行下载
+ (id)downloadWebImageWithUrl:(NSURL *)url progress:(YBImageBrowserDownloaderProgressBlock)progress success:(YBImageBrowserDownloaderSuccessBlock)success failed:(YBImageBrowserDownloaderFailedBlock)failed;

//取消某个下载任务
+ (void)cancelTaskWithDownloadToken:(id _Nullable)token;

//缓存
+ (void)storeImageDataWithKey:(NSString *)key image:(UIImage * _Nullable)image data:(NSData * _Nullable)data;

//判断缓存中 imageData 是否存在（采用 block，不管替换框架是异步还是同步都行）
+ (void)memeryImageDataExistWithKey:(NSString *)key exist:(void(^)(BOOL exist))exist;

//查找缓存（采用 block，不管替换框架是异步还是同步都行）
+ (void)queryCacheOperationForKey:(NSString *)key completed:(YBImageBrowserDownloaderCacheQueryCompletedBlock)completed;

//框架下载时候的图片解压
+ (void)shouldDecompressImages:(BOOL)should;

@end

NS_ASSUME_NONNULL_END
