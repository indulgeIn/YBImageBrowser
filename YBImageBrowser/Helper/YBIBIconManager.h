//
//  YBIBIconManager.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/8/29.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (YBImageBrowser)

/**
 获取图片便利构造方法

 @param name 图片名字
 @param bundle 资源对象
 @return 图片实例
 */
+ (instancetype)ybib_imageNamed:(NSString *)name bundle:(NSBundle *)bundle;

@end


/// 获取图片闭包
typedef UIImage * _Nullable (^YBIBIconBlock)(void);

/**
 图标管理类
 */
@interface YBIBIconManager : NSObject

/**
 唯一有效单例
 */
+ (instancetype)sharedManager;

#pragma - 以下图片可更改

/// 基本-加载
@property (nonatomic, copy) YBIBIconBlock loadingImage;

/// 工具视图-保存
@property (nonatomic, copy) YBIBIconBlock toolSaveImage;
/// 工具视图-更多
@property (nonatomic, copy) YBIBIconBlock toolMoreImage;

/// 视频-播放
@property (nonatomic, copy) YBIBIconBlock videoPlayImage;
/// 视频-暂停
@property (nonatomic, copy) YBIBIconBlock videoPauseImage;
/// 视频-取消
@property (nonatomic, copy) YBIBIconBlock videoCancelImage;
/// 视频-播放大图
@property (nonatomic, copy) YBIBIconBlock videoBigPlayImage;
/// 视频-拖动圆点
@property (nonatomic, copy) YBIBIconBlock videoDragCircleImage;

@end

NS_ASSUME_NONNULL_END
