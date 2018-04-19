//
//  YBImageBrowserCopywriter.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YBImageBrowserCopywriter : NSObject

//当前无图片数据可保存
@property (nonatomic, copy) NSString *noImageDataToSave;

//访问相册权限被拒绝
@property (nonatomic, copy) NSString *albumAuthorizationDenied;

//保存图片数据到相册成功
@property (nonatomic, copy) NSString *saveImageDataToAlbumSuccessful;

//保存图片数据到相册失败
@property (nonatomic, copy) NSString *saveImageDataToAlbumFailed;

//加载图片失败占位文字
@property (nonatomic, copy) NSString *loadFailedText;

//正在压缩图片的文案
@property (nonatomic, strong) NSString *isScaleImageText;

@end

NS_ASSUME_NONNULL_END
