//
//  YBImageBrowserModel.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowserModel;

typedef void(^YBImageBrowserModelDownloadProgressBlock)(YBImageBrowserModel *backModel, NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);
typedef void(^YBImageBrowserModelDownloadSuccessBlock)(YBImageBrowserModel *backModel, UIImage * _Nullable image, NSData * _Nullable data, BOOL finished);
typedef void(^YBImageBrowserModelDownloadFailedBlock)(YBImageBrowserModel *backModel, NSError * _Nullable error, BOOL finished);
typedef void(^YBImageBrowserModelScaleImageSuccessBlock)(YBImageBrowserModel *backModel);
typedef void(^YBImageBrowserModelCutImageSuccessBlock)(YBImageBrowserModel *backModel, UIImage *targetImage);

FOUNDATION_EXTERN NSString * const YBImageBrowserModel_KVCKey_isLoading;
FOUNDATION_EXTERN NSString * const YBImageBrowserModel_KVCKey_isLoadFailed;
FOUNDATION_EXTERN NSString * const YBImageBrowserModel_KVCKey_largeImage;
FOUNDATION_EXTERN char * const YBImageBrowserModel_SELName_download;
FOUNDATION_EXTERN char * const YBImageBrowserModel_SELName_scaleImage;
FOUNDATION_EXPORT char * const YBImageBrowserModel_SELName_cutImage;

@interface YBImageBrowserModel : NSObject

/**
 本地图片
 （setImageWithFileName:fileType: 若图片不在 Assets 中，尽量使用此方法以避免图片缓存过多导致内存飙升）
 */
@property (nonatomic, strong, nullable) UIImage *image;
- (void)setImageWithFileName:(NSString *)fileName fileType:(NSString *)type;

/**
 网络图片 url
 （setUrlWithDownloadInAdvance: 设置 url 的时候异步预下载）
 */
@property (nonatomic, strong, nullable) NSURL *url;
- (void)setUrlWithDownloadInAdvance:(NSURL *)url;

/**
 本地 gif 名字
 （请不要带后缀）
 */
@property (nonatomic, copy, nullable) NSString *gifName;

/**
 本地或者网络 gif 最终转换类型
 */
@property (nonatomic, strong, nullable) FLAnimatedImage *animatedImage;

/**
 来源图片视图
 （用于做 YBImageBrowserAnimationMove 类型的动效）
 */
@property (nonatomic, strong, nullable) UIImageView *sourceImageView;

/**
 预览缩略图
 */
@property (nonatomic, strong, nullable) YBImageBrowserModel *previewModel;

/**
 最大缩放值 默认4
 （若 YBImageBrowser 的 autoCountMaximumZoomScale 属性为 NO 有效）
 */
@property (nonatomic, assign) CGFloat maximumZoomScale;

/**
 是否需要裁剪显示
 */
@property (nonatomic, assign) BOOL needCutToShow;

@end

NS_ASSUME_NONNULL_END
