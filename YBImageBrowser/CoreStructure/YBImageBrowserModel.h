//
//  YBImageBrowserModel.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

FOUNDATION_EXTERN NSString * const YBImageBrowser_KVCKey_isLoading;
FOUNDATION_EXTERN NSString * const YBImageBrowser_KVCKey_isLoadFailed;

@interface YBImageBrowserModel : NSObject

/**
 本地图片
 （若图片不在 Assets 中，尽量使用 setImageWithFileName:fileType: 以避免图片缓存过多导致内存飙升）
 */
@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, strong) UIImage *image;
- (void)setImageWithFileName:(NSString *)fileName fileType:(NSString *)type;

/**
 本地 gif 名字
 （请不要带后缀）
 */
@property (nonatomic, copy) NSString *gifName;

/**
 网络图片 url
 */
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, strong) NSURL *url;

/**
 本地或者网络 gif 最终转换类型
 */
@property (nonatomic, strong) FLAnimatedImage *animatedImage;

/**
 来源图片视图
 （用于做入场和出场动效）
 */
@property (nonatomic, strong) UIImageView *sourceImageView;

/**
 预览缩略图
 */
@property (nonatomic, strong) YBImageBrowserModel *previewModel;

@end
