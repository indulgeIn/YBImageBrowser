//
//  YBIBWebImageMediator.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/8/27.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSURLRequest * _Nullable (^YBIBWebImageRequestModifierBlock)(NSURLRequest *request);
typedef void(^YBIBWebImageProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);
typedef void(^YBIBWebImageSuccessBlock)(NSData * _Nullable imageData, BOOL finished);
typedef void(^YBIBWebImageFailedBlock)(NSError * _Nullable error, BOOL finished);
typedef void(^YBIBWebImageCacheQueryCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable imageData);

@protocol YBIBWebImageMediator <NSObject>

@required

/**
 下载图片

 @param URL 图片地址
 @param requestModifier 修改默认 NSURLRequest 的闭包
 @param progress 进度回调
 @param success 成功回调
 @param failed 失败回调
 @return 下载 token (可为空)
 */
- (id)yb_downloadImageWithURL:(NSURL *)URL requestModifier:(nullable YBIBWebImageRequestModifierBlock)requestModifier progress:(YBIBWebImageProgressBlock)progress success:(YBIBWebImageSuccessBlock)success failed:(YBIBWebImageFailedBlock)failed;

/**
 缓存图片数据到磁盘

 @param data 图片数据
 @param key 缓存标识
 */
- (void)yb_storeToDiskWithImageData:(nullable NSData *)data forKey:(NSURL *)key;

/**
 读取图片数据

 @param key 缓存标识
 @param completed 读取回调
 */
- (void)yb_queryCacheOperationForKey:(NSURL *)key completed:(YBIBWebImageCacheQueryCompletedBlock)completed;

@optional

/**
 取消下载
 
 @param token 下载 token
 */
- (void)yb_cancelTaskWithDownloadToken:(id)token;

@end

NS_ASSUME_NONNULL_END
