//
//  YBImageBrowserModel.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"

FOUNDATION_EXTERN NSString * const YBImageBrowser_KVCKey_needUpdateUI;
FOUNDATION_EXTERN NSString * const YBImageBrowser_KVCKey_isLoading;
FOUNDATION_EXTERN NSString * const YBImageBrowser_KVCKey_isLoadFailed;

@interface YBImageBrowserModel : NSObject

/**
 本地图片名字
 */
@property (nonatomic, copy) NSString *imageName;

/**
 本地gif名字（不带后缀）
 */
@property (nonatomic, copy) NSString *gifName;

/**
 网络图片url字符串
 */
@property (nonatomic, copy) NSString *imageUrl;

/**
 预览缩略图
 */
@property (nonatomic, strong) YBImageBrowserModel *previewModel;

/**
 本地图片
 */
@property (nonatomic, strong) UIImage *image;

/**
 网络图片url
 */
@property (nonatomic, strong) NSURL *url;

/**
 gif
 */
@property (nonatomic, strong) FLAnimatedImage *animatedImage;

@end
