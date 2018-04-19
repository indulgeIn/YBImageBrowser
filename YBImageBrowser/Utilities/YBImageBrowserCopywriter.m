//
//  YBImageBrowserCopywriter.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserCopywriter.h"

@implementation YBImageBrowserCopywriter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _noImageDataToSave = @"当前无图片可保存";
        _albumAuthorizationDenied = @"请为本APP开启相册权限";
        _saveImageDataToAlbumSuccessful = @"保存成功";
        _saveImageDataToAlbumFailed = @"保存失败";
        _loadFailedText = @"哎呀，图片加载失败了";
        _isScaleImageText = @"图片处理中...";
    }
    return self;
}

@end
