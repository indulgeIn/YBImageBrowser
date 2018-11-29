//
//  YBIBPhotoAlbumManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/28.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBPhotoAlbumManager.h"
#import "YBIBUtilities.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "YBImageBrowserTipView.h"
#import "YBIBCopywriter.h"

@implementation YBIBPhotoAlbumManager

+ (void)getAVAssetWithPHAsset:(PHAsset *)phAsset success:(void(^)(AVAsset *))success failed:(void(^)(void))failed {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        YBIB_GET_QUEUE_MAIN_ASYNC(^{
            if (asset) {
                if (success) success(asset);
            } else {
                if (failed) failed();
            }
        })
    }];
}

+ (void)getImageDataWithPHAsset:(PHAsset *)phAsset success:(void(^)(NSData *))success failed:(void(^)(void))failed {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeNone;
    option.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:phAsset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL complete = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (complete && imageData) {
            if (success) success(imageData);
        } else {
            if (failed) failed();
        }
    }];
}

+ (void)getPhotoAlbumAuthorizationSuccess:(void(^)(void))success failed:(void(^)(void))failed {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusDenied:
            [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].getPhotoAlbumAuthorizationFailed];
            if (failed) failed();
            break;
        case PHAuthorizationStatusRestricted:
            [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].getPhotoAlbumAuthorizationFailed];
            if (failed) failed();
            break;
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                YBIB_GET_QUEUE_MAIN_ASYNC(^{
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

+ (void)saveDataToAlbum:(NSData *)data {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].saveToPhotoAlbumFailed];
        } else {
            [YBIBGetNormalWindow() yb_showHookTipView:[YBIBCopywriter shareCopywriter].saveToPhotoAlbumSuccess];
        }
    }];
}

+ (void)saveImageToAlbum:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(completedWithImage:error:context:), NULL);
}

+ (void)completedWithImage:(UIImage *)image error:(NSError *)error context:(void *)context {
    if (error) {
        [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].saveToPhotoAlbumFailed];
    } else {
        [YBIBGetNormalWindow() yb_showHookTipView:[YBIBCopywriter shareCopywriter].saveToPhotoAlbumSuccess];
    }
}

+ (void)saveVideoToAlbumWithPath:(NSString *)path {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    } else {
        [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].unableToSave];
    }
}

+ (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].saveToPhotoAlbumFailed];
    } else {
        [YBIBGetNormalWindow() yb_showHookTipView:[YBIBCopywriter shareCopywriter].saveToPhotoAlbumSuccess];
    }
}


@end
