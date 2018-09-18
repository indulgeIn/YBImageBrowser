//
//  YBIBPhotoAlbumManager.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/28.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

@interface YBIBPhotoAlbumManager : NSObject

/**
 Get photo album authorization.
 */
+ (void)getPhotoAlbumAuthorizationSuccess:(void(^)(void))success failed:(void(^)(void))failed;

/**
 Get 'AVAsset' through 'PHAsset' asynchronously.
 */
+ (void)getAVAssetWithPHAsset:(PHAsset *)phAsset success:(void(^)(AVAsset *asset))success failed:(void(^)(void))failed;

/**
 Get 'ImageData' through 'PHAsset' asynchronously.
 */
+ (void)getImageDataWithPHAsset:(PHAsset *)phAsset success:(void(^)(NSData *data))success failed:(void(^)(void))failed;

+ (void)saveImageToAlbum:(UIImage *)image;

+ (void)saveDataToAlbum:(NSData *)data;

+ (void)saveVideoToAlbumWithPath:(NSString *)path;

@end
