//
//  YBIBImageLayout.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/12.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YBIBImageLayout <NSObject>
@required

/**
 计算图片展示的位置

 @param containerSize 容器大小
 @param imageSize 图片大小 (逻辑像素)
 @param orientation 图片浏览器的方向
 @return 图片展示的位置 (frame)
 */
- (CGRect)yb_imageViewFrameWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize orientation:(UIDeviceOrientation)orientation;

/**
 计算最大缩放比例

 @param containerSize 容器大小
 @param imageSize 图片大小 (逻辑像素)
 @param orientation 图片浏览器的方向
 @return 最大缩放比例
 */
- (CGFloat)yb_maximumZoomScaleWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize orientation:(UIDeviceOrientation)orientation;

@end

typedef NS_ENUM(NSUInteger, YBIBImageFillType) {
    /// 宽度优先填充满
    YBIBImageFillTypeFullWidth,
    /// 完整显示
    YBIBImageFillTypeCompletely
};

@interface YBIBImageLayout : NSObject <YBIBImageLayout>

/// 纵向的填充方式，默认 YBIBImageFillTypeCompletely
@property (nonatomic, assign) YBIBImageFillType verticalFillType;

/// 横向的填充方式，默认 YBIBImageFillTypeFullWidth
@property (nonatomic, assign) YBIBImageFillType horizontalFillType;

/// 最大缩放比例 (必须大于 1 才有效，若不指定内部会自动计算)
@property (nonatomic, assign) CGFloat maxZoomScale;

/// 自动计算严格缩放比例后，再乘以这个值作为最终缩放比例，默认 1.5
@property (nonatomic, assign) CGFloat zoomScaleSurplus;

@end

NS_ASSUME_NONNULL_END
