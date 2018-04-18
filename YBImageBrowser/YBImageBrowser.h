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


@protocol YBImageBrowserDelegate <NSObject>
@optional

//滚动时下标切换的实时回调
- (void)yBImageBrowser:(YBImageBrowser *)imageBrowser didScrollToIndex:(NSInteger)index;

//点击弹出功能栏的回调
- (void)yBImageBrowser:(YBImageBrowser *)imageBrowser clickFunctionBarWithModel:(YBImageBrowserFunctionModel *)model;

@end


@protocol YBImageBrowserDataSource <NSObject>
@required

//返回点击的那个 UIImageView （用于做动效）
- (UIImageView * _Nullable)imageViewOfTouchForImageBrowser:(YBImageBrowser *)imageBrowser;

//返回数量
- (NSInteger)numberInYBImageBrowser:(YBImageBrowser *)imageBrowser;

//返回当前 index 的数据模型
- (YBImageBrowserModel *)yBImageBrowser:(YBImageBrowser *)imageBrowser modelForCellAtIndex:(NSInteger)index;

@end


@interface YBImageBrowser : UIViewController <YBImageBrowserScreenOrientationProtocol>

/**
 数据源
 （可重载）
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

/**
 支持旋转的方向
 （请保证在 general -> deployment info -> Device Orientation 有对应的配置，目前不支持强制旋转）
 */
@property (nonatomic, assign) UIInterfaceOrientationMask yb_supportedInterfaceOrientations;

/**
 纵屏时候图片填充类型
 */
@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;

/**
 横屏时候图片填充类型
 */
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

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

/**
 显示状态栏
 */
@property (nonatomic, assign) BOOL showStatusBar;

/**
 文案撰写者
 （可依靠该属性配置自定义的文案）
 */
@property (nonatomic, strong) YBImageBrowserCopywriter *copywriter;

/**
 转场动画持续时间
 */
@property (nonatomic, assign) NSTimeInterval transitionDuration;

/**
 取消拖拽图片的动画效果
 */
@property (nonatomic, assign) BOOL cancelDragImageViewAnimation;

/**
 拖拽图片动效触发出场的比例（拖动距离/屏幕高度 默认0.3）
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
 页与页之间的距离
 */
@property (nonatomic, assign) CGFloat distanceBetweenPages;

@end

NS_ASSUME_NONNULL_END
