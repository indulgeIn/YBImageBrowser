//
//  YBImageBrowserModel.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"

@interface YBImageBrowserModel : NSObject

////* 配置属性

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





////* 不建议直接赋值的属性（内部会根据'配置属性'自动转换）
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) FLAnimatedImage *animatedImage;

@end
