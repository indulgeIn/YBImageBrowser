//
//  YBIBDataProtocol.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/5.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBGetBaseInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YBIBDataProtocol <YBIBGetBaseInfoProtocol>

@required

/**
 当前 Data 对应 Cell 的类类型

 @return Class 类型
 */
- (Class)yb_classOfCell;

@optional

/**
 获取投影视图，当前数据模型对应外界业务的 UIView (通常为 UIImageView)，做转场动效用
 
 这个方法会在做出入场动效时调用，若未实现时将无法进行平滑的入场

 @return 投影视图
 */
- (__kindof UIView *)yb_projectiveView;

/**
 通过一系列数据，计算并返回图片视图在容器中的 frame
 
 这个方法会在做入场动效时调用，若未实现时将无法进行平滑的入场

 @param containerSize 容器大小
 @param imageSize 图片大小 (逻辑像素)
 @param orientation 图片浏览器的方向
 @return 计算好的 frame
 */
- (CGRect)yb_imageViewFrameWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize orientation:(UIDeviceOrientation)orientation;

/**
 预加载数据，有效的预加载能提高性能，请注意管理内存
 */
- (void)yb_preload;

/**
 保存到相册，不实现就表示不支持这个功能
 */
- (void)yb_saveToPhotoAlbum;

@end

NS_ASSUME_NONNULL_END
