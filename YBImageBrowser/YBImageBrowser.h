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

@class YBImageBrowser;

@protocol YBImageBrowserDelegate <NSObject>

@end

@interface YBImageBrowser : UIViewController

/**
 数据源
 （可重载）
 */
@property (nonatomic, copy) NSArray<YBImageBrowserModel *> *dataArray;

/**
 展示
 */
- (void)show;

/**
 隐藏
 */
- (void)hide;

/**
 当前下标
 */
@property (nonatomic, assign) NSUInteger currentIndex;

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
 额外操作弹出框的数据源
 （默认有图片/gif保存功能）
 */
@property (nonatomic, copy) NSArray<YBImageBrowserFunctionModel *> *fuctionDataArray;

/**
 额外操作弹出框
 */
@property (nonatomic, strong, readonly) YBImageBrowserFunctionBar *functionBar;

/**
 工具栏
 */
@property (nonatomic, strong, readonly) YBImageBrowserToolBar *toolBar;

/**
 显示状态栏
 */
@property (nonatomic, assign) BOOL showStatusBar;

/**
 文案撰写者
 （可依靠该属性配置自定义的文案）
 */
@property (nonatomic, strong) YBImageBrowserCopywriter *copywriter;

@end
