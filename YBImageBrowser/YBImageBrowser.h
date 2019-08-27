//
//  YBImageBrowser.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/5.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBCollectionView.h"
#import "YBImageBrowserDataSource.h"
#import "YBImageBrowserDelegate.h"
#import "YBIBDataProtocol.h"
#import "YBIBCellProtocol.h"
#import "YBIBAnimatedTransition.h"
#import "YBIBAuxiliaryViewHandler.h"
#import "YBIBToolViewHandler.h"
#import "YBIBWebImageMediator.h"
#import "YBIBImageData.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBImageBrowser : UIView

/// 数据源数组
@property (nonatomic, copy) NSArray<id<YBIBDataProtocol>> *dataSourceArray;

/// 数据源代理
@property (nonatomic, weak) id<YBImageBrowserDataSource> dataSource;

/// 状态回调代理
@property (nonatomic, weak) id<YBImageBrowserDelegate> delegate;

/**
 展示图片浏览器

 @param view 指定父视图（view 的大小不能为 CGSizeZero，但允许变化）
 @param containerSize 容器大小（当 view 的大小允许变化时，必须指定确切的 containerSize）
 */
- (void)showToView:(UIView *)view containerSize:(CGSize)containerSize;
- (void)showToView:(UIView *)view;
- (void)show;

/**
 隐藏图片浏览器（不建议外部持有图片浏览器重复使用）
 */
- (void)hide;

/// 当前页码
@property (nonatomic, assign) NSInteger currentPage;

/// 分页间距
@property (nonatomic, assign) CGFloat distanceBetweenPages;

/// 当前图片浏览器的方向
@property (nonatomic, assign, readonly) UIDeviceOrientation currentOrientation;

/// 图片浏览器支持的方向 (仅当前控制器不支持旋转时有效，否则将跟随控制器旋转)
@property (nonatomic, assign) UIInterfaceOrientationMask supportedOrientations;

/// 是否自动隐藏 id<YBIBImageData> 设置的映射视图，默认为 YES
@property (nonatomic, assign) BOOL autoHideProjectiveView;

/// 是否正在转场
@property (nonatomic, assign, readonly, getter=isTransitioning) BOOL transitioning;

/// 预加载数量 (默认为 2，低内存设备默认为 0)
@property (nonatomic, assign) NSUInteger preloadCount;

/**
 重载数据，请保证数据源被正确修改
 */
- (void)reloadData;

/**
 获取当前展示的数据对象

 @return 数据对象
 */
- (id<YBIBDataProtocol>)currentData;

/// 是否隐藏状态栏，默认为 YES
@property (nonatomic, assign) BOOL shouldHideStatusBar;

/// 工具视图处理器
/// 赋值可自定义，实现者可以直接用 UIView，或者创建一个中介者管理一系列的 UIView。
/// 内部消息是按照数组下标顺序调度的，所以如果有多个处理器注意添加 UIView 的视图层级。
@property (nonatomic, copy) NSArray<id<YBIBToolViewHandler>> *toolViewHandlers;
/// 默认工具视图处理器
@property (nonatomic, weak, readonly) YBIBToolViewHandler *defaultToolViewHandler;

/// Toast/Loading 处理器 (赋值可自定义)
@property (nonatomic, strong) id<YBIBAuxiliaryViewHandler> auxiliaryViewHandler;

/// 转场实现类 (赋值可自定义)
@property (nonatomic, strong) id<YBIBAnimatedTransition> animatedTransition;
/// 默认转场实现类 (可配置其属性)
@property (nonatomic, weak, readonly) YBIBAnimatedTransition *defaultAnimatedTransition;

/// 图片下载缓存相关的中介者（赋值可自定义）
@property (nonatomic, strong) id<YBIBWebImageMediator> webImageMediator;

/// 核心集合视图
@property (nonatomic, strong, readonly) YBIBCollectionView *collectionView;

@end

NS_ASSUME_NONNULL_END
