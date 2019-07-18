//
//  YBIBWebImageManager.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/8/29.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 A mediator between 'YBImageBrowser' and 'SDWebImage'.
 */

NS_ASSUME_NONNULL_BEGIN

typedef NSURLRequest * _Nullable (^YBIBWebImageRequestModifierBlock)(NSURLRequest *request);

typedef void(^YBIBWebImageProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);
typedef void(^YBIBWebImageSuccessBlock)(NSData * _Nullable imageData, BOOL finished);
typedef void(^YBIBWebImageFailedBlock)(NSError * _Nullable error, BOOL finished);
typedef void(^YBIBWebImageCacheQueryCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable imageData);

@interface YBIBWebImageManager : NSObject

+ (id)downloadImageWithURL:(NSURL *)url requestModifier:(nullable YBIBWebImageRequestModifierBlock)requestModifier progress:(YBIBWebImageProgressBlock)progress success:(YBIBWebImageSuccessBlock)success failed:(YBIBWebImageFailedBlock)failed;

+ (void)cancelTaskWithDownloadToken:(id)token;

+ (void)storeToDiskWithImageData:(nullable NSData *)data forKey:(NSURL *)key;

+ (void)queryCacheOperationForKey:(NSURL *)key completed:(YBIBWebImageCacheQueryCompletedBlock)completed;

@end

NS_ASSUME_NONNULL_END
