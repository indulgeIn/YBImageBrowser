//
//  YBImageBrowserTestVC.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserModel.h"
#import "YBImageBrowserFunctionBar.h"
#import "YBImageBrowserToolBar.h"
#import "YBImageBrowserCopywriter.h"
#import "YBImageBrowserScreenOrientationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowser;

#pragma mark 事件回调代理 (callback agency)
@protocol YBImageBrowserDelegate <NSObject>
@optional

/**
 图片浏览器翻页

 @param imageBrowser 当前图片浏览器
 @param index 目前的下标
 */
- (void)yBImageBrowser:(YBImageBrowser *)imageBrowser didScrollToIndex:(NSInteger)index;

/**
 点击功能栏的回调

 @param imageBrowser 当前图片浏览器
 @param model 功能的数据model
 */
- (void)yBImageBrowser:(YBImageBrowser *)imageBrowser clickFunctionBarWithModel:(YBImageBrowserFunctionModel *)model;

@end


#pragma mark 数据源代理 (dataSource agency)
@protocol YBImageBrowserDataSource <NSObject>
@required

/**
 返回点击的那个 UIImageView（用于做 YBImageBrowserAnimationMove 类型动效）

 @param imageBrowser 当前图片浏览器
 @return 点击的图片视图
 */
- (UIImageView * _Nullable)imageViewOfTouchForImageBrowser:(YBImageBrowser *)imageBrowser;

/**
 配置图片的数量

 @param imageBrowser 当前图片浏览器
 @return 图片数量
 */
- (NSInteger)numberInYBImageBrowser:(YBImageBrowser *)imageBrowser;

/**
 返回当前 index 图片对应的数据模型

 @param imageBrowser 当前图片浏览器
 @param index 当前下标
 @return 数据模型
 */
- (YBImageBrowserModel *)yBImageBrowser:(YBImageBrowser *)imageBrowser modelForCellAtIndex:(NSInteger)index;

@end


@interface YBImageBrowser : UIViewController <YBImageBrowserScreenOrientationProtocol>

#pragma mark 基本功能 (basic function)

/**
 数据源
 （请不要尝试数据重载，更改数据源请另开辟内存）
 */
@property (nonatomic, copy) NSArray<YBImageBrowserModel *> *dataArray;

/**
 数据源代理
 （请在设置 dataArray 和实现 dataSource 代理中选其一，注意 dataArray 优先级高于代理）
 */
@property (nonatomic, weak) id <YBImageBrowserDataSource> dataSource;

/**
 展示
 */
- (void)show;
- (void)showFromController:(UIViewController *)controller;

/**
 当前下标
 */
@property (nonatomic, assign) NSUInteger currentIndex;

/**
 隐藏
 */
- (void)hide;

/**
 代理回调
 */
@property (nonatomic, weak) id <YBImageBrowserDelegate> delegate;

#pragma mark 功能栏操作 (function bar operation)

/**
 弹出功能栏的数据源
 （默认有图片保存功能）
 */
@property (nonatomic, copy, nullable) NSArray<YBImageBrowserFunctionModel *> *fuctionDataArray;

/**
 弹出功能栏
 */
@property (nonatomic, strong, readonly) YBImageBrowserFunctionBar *functionBar;

/**
 工具栏
 */
@property (nonatomic, strong, readonly) YBImageBrowserToolBar *toolBar;

/**
 取消长按手势的响应
 */
@property (nonatomic, assign) BOOL cancelLongPressGesture;

#pragma mark 动画相关 (animation)

/**
 转场动画持续时间
 */
@property (nonatomic, assign) NSTimeInterval transitionDuration;

/**
 取消拖拽图片的动画效果
 */
@property (nonatomic, assign) BOOL cancelDragImageViewAnimation;

/**
 拖拽图片动效触发出场的比例（拖动距离/屏幕高度 默认0.15）
 */
@property (nonatomic, assign) CGFloat outScaleOfDragImageViewAnimation;

/**
 入场动画类型
 */
@property (nonatomic, assign) YBImageBrowserAnimation inAnimation;

/**
 出场动画类型
 */
@property (nonatomic, assign) YBImageBrowserAnimation outAnimation;

/**
 页与页之间的间距
 */
@property (nonatomic, assign) CGFloat distanceBetweenPages;

#pragma mark 屏幕方向相关 (screen direction)

/**
 支持旋转的方向
 （请保证在 general -> deployment info -> Device Orientation 有对应的配置，目前不支持强制旋转）
 */
@property (nonatomic, assign) UIInterfaceOrientationMask yb_supportedInterfaceOrientations;

#pragma mark 缩放相关 (scale)

/**
 是否需要自动计算缩放
 （默认是自动的，若改为NO，可用 YBImageBrowserModel 的 maximumZoomScale 设置希望当前图片的最大缩放比例）
 */
@property (nonatomic, assign) BOOL autoCountMaximumZoomScale;

/**
 纵屏时候图片填充类型
 */
@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;

/**
 横屏时候图片填充类型
 */
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

#pragma mark 性能和内存相关 (performance and memory)

/**
 网络图片下载和持久化时，是否做内存缓存，为YES能提高图片第二次显示的性能，为NO能减少图片的内存占用（高清大图请置NO）
 */
@property (nonatomic, assign) BOOL downloaderShouldDecompressImages;

/**
 最大显示pt（超过这个数量框架会自动做压缩和裁剪，默认为3500）
 */
@property (class, assign) CGFloat maxDisplaySize;

#pragma mark 其他 (other)

/**
 文案撰写者
 （可依靠该属性配置自定义的文案）
 */
@property (nonatomic, strong) YBImageBrowserCopywriter *copywriter;

/**
 显示状态栏
 */
@property (class, assign) BOOL showStatusBar;

/**
 进入图片浏览器之前状态栏是否隐藏（进入框架内部会判断，若在图片浏览器生命周期之间外部的状态栏显示与否发生改变，你需要改变该属性的值）
 */
@property (class, assign) BOOL statusBarIsHideBefore;

/**
 状态栏是否是控制器优先
 */
@property (class, assign, readonly) BOOL isControllerPreferredForStatusBar;

@end

NS_ASSUME_NONNULL_END
