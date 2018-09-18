//
//  YBIBWebImageManager.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/29.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 A mediator between the 'YBImageBrowser' and 'SDWebImage'.
 */

NS_ASSUME_NONNULL_BEGIN

typedef void(^YBIBWebImageManagerProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);
typedef void(^YBIBWebImageManagerSuccessBlock)(UIImage * _Nullable image, NSData * _Nullable data, BOOL finished);
typedef void(^YBIBWebImageManagerFailedBlock)(NSError * _Nullable error, BOOL finished);
typedef void(^YBIBWebImageManagerCacheQueryCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable data);

@interface YBIBWebImageManager : NSObject

+ (void)storeOutsideConfiguration;

+ (void)restoreOutsideConfiguration;

+ (id)downloadImageWithURL:(NSURL *)url progress:(YBIBWebImageManagerProgressBlock)progress success:(YBIBWebImageManagerSuccessBlock)success failed:(YBIBWebImageManagerFailedBlock)failed;

+ (void)cancelTaskWithDownloadToken:(id)token;

+ (void)storeImage:(nullable UIImage *)image imageData:(nullable NSData *)data forKey:(NSURL *)key toDisk:(BOOL)toDisk;

+ (void)queryCacheOperationForKey:(NSURL *)key completed:(YBIBWebImageManagerCacheQueryCompletedBlock)completed;

@end

NS_ASSUME_NONNULL_END
