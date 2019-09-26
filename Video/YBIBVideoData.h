//
//  YBIBVideoData.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/10.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <Photos/Photos.h>
#import "YBIBDataProtocol.h"
#import "YBIBInteractionProfile.h"

NS_ASSUME_NONNULL_BEGIN

@class YBIBVideoData;

/// 单击事件的处理闭包
typedef void (^YBIBVideoSingleTouchBlock)(YBIBVideoData *videoData);


/**
 图片数据类，承担配置数据和处理数据的责任
 */
@interface YBIBVideoData : NSObject <YBIBDataProtocol>

/// 视频 URL
@property (nonatomic, copy, nullable) NSURL *videoURL;

/// 相册视频资源
@property (nonatomic, strong, nullable) PHAsset *videoPHAsset;

/// 视频 AVAsset (通常使用 AVURLAsset)
@property (nonatomic, strong, nullable) AVAsset *videoAVAsset;

/// 投影视图，当前数据模型对应外界业务的 UIView (通常为 UIImageView)，做转场动效用
@property (nonatomic, weak, nullable) __kindof UIView *projectiveView;

/// 预览图/缩约图，若 projectiveView 存在且是 UIImageView 类型将会自动获取缩约图
@property (nonatomic, strong, nullable) UIImage *thumbImage;

/// 是否允许保存到相册
@property (nonatomic, assign) BOOL allowSaveToPhotoAlbum;

/// 自动播放次数，默认为 0，NSUIntegerMax 表示无限次
@property (nonatomic, assign) NSUInteger autoPlayCount;

/// 重复播放次数，默认为 0，NSUIntegerMax 表示无限次
@property (nonatomic, assign) NSUInteger repeatPlayCount;

/// 预留属性可随意使用
@property (nonatomic, strong, nullable) id extraData;

/// 手势交互动效配置文件
@property (nonatomic, strong) YBIBInteractionProfile *interactionProfile;

/// 单击的处理（视频未播放时），默认是退出图片浏览器
@property (nonatomic, copy, nullable) YBIBVideoSingleTouchBlock singleTouchBlock;

/// 是否要隐藏播放时的叉叉（取消）按钮
@property (nonatomic, assign) BOOL shouldHideForkButton;

@end

NS_ASSUME_NONNULL_END
