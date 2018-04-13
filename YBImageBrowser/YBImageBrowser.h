//
//  YBImageBrowserTestVC.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"
#import "YBImageBrowserFunctionBar.h"

@class YBImageBrowser;

@protocol YBImageBrowserDelegate <NSObject>

@end

@interface YBImageBrowser : UIViewController

/**
 数据源
 （只赋值一次，试图更换数据源请另开辟内存）
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
 */
@property (nonatomic, copy) NSArray<YBImageBrowserFunctionModel *> *fuctionDataArray;

@end
