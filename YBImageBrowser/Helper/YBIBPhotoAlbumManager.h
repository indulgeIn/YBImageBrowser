//
//  YBIBPhotoAlbumManager.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/8/28.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface YBIBPhotoAlbumManager : NSObject

/**
 Get photo album authorization.
 */
+ (void)getPhotoAlbumAuthorizationSuccess:(void(^)(void))success failed:(void(^)(void))failed;

/**
 Get 'AVAsset' by 'PHAsset' asynchronously, callback is in child thread.
 */
+ (void)getAVAssetWithPHAsset:(PHAsset *)phAsset completion:(void(^)(AVAsset * _Nullable asset))completion;

/**
 Get 'ImageData' by 'PHAsset' synchronously, callback is in child thread.
 */
+ (void)getImageDataWithPHAsset:(PHAsset *)phAsset completion:(void(^)(NSData * _Nullable data))completion;

@end

NS_ASSUME_NONNULL_END
