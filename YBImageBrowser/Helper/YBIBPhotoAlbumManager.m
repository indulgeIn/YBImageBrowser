//
//  YBIBPhotoAlbumManager.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/8/28.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "YBIBPhotoAlbumManager.h"
#import "YBIBUtilities.h"

@implementation YBIBPhotoAlbumManager

+ (void)getAVAssetWithPHAsset:(PHAsset *)phAsset completion:(nonnull void (^)(AVAsset * _Nullable))completion {
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        completion(asset);
    }];
}

+ (void)getImageDataWithPHAsset:(PHAsset *)phAsset completion:(nonnull void (^)(NSData * _Nullable))completion {
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeNone;
    // Only when this property is YES, the callback will in child thread.
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:phAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL complete = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (complete && imageData) {
            completion(imageData);
        } else {
            completion(nil);
        }
    }];
}

+ (void)getPhotoAlbumAuthorizationSuccess:(void(^)(void))success failed:(void(^)(void))failed {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusDenied:
            if (failed) failed();
            break;
        case PHAuthorizationStatusRestricted:
            if (failed) failed();
            break;
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                YBIB_DISPATCH_ASYNC_MAIN(^{
                    if (status == PHAuthorizationStatusAuthorized) {
                        if (success) success();
                    } else {
                        if (failed) failed();
                    }
                })
            }];
        }
            break;
        case PHAuthorizationStatusAuthorized:
            if (success) success();
            break;
    }
}

@end
