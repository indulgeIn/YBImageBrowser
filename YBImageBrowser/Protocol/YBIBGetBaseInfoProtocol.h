//
//  YBIBGetBaseInfoProtocol.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/23.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBIBAuxiliaryViewHandler.h"
#import "YBIBWebImageMediator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YBIBGetBaseInfoProtocol <NSObject>

@optional

/// 当前的方向
@property (nonatomic, copy) UIDeviceOrientation(^yb_currentOrientation)(void);

/// 根据方向获取容器大小
@property (nonatomic, copy) CGSize(^yb_containerSize)(UIDeviceOrientation orientation);

/// 容器视图 (可在上面添加子视图)
@property (nonatomic, weak) UIView *yb_containerView;

/// 辅助视图处理器
@property (nonatomic, copy) id<YBIBAuxiliaryViewHandler>(^yb_auxiliaryViewHandler)(void);

/// 图片下载缓存相关中介者
@property (nonatomic, copy) id<YBIBWebImageMediator>(^yb_webImageMediator)(void);

/// 当前页码
@property (nonatomic, copy) NSInteger(^yb_currentPage)(void);

/// 总页码数量
@property (nonatomic, copy) NSInteger(^yb_totalPage)(void);

/// 判断当前展示的 cell 是否恰好在屏幕中间
@property (nonatomic, copy) BOOL(^yb_cellIsInCenter)(void);

/// 是否正在转场
@property (nonatomic, copy) BOOL(^yb_isTransitioning)(void);

/// 是否正在旋转
@property (nonatomic, copy) BOOL(^yb_isRotating)(void);

/// 背景视图 (也就是 YBImageBrower 对象，不可在上面添加子视图。作用：一是可以更改透明度和颜色，入场和出场动效有用；二是可以用来比较内存指针，在做不同实例差异化功能时可能有用，虽然不提倡这么做)
@property (nonatomic, weak) __kindof UIView *yb_backView;

/// 集合视图
@property (nonatomic, copy) __kindof UICollectionView *(^yb_collectionView)(void);

@end

NS_ASSUME_NONNULL_END
