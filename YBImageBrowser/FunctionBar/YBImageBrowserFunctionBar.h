//
//  YBImageBrowserFunctionBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserFunctionModel.h"

@class YBImageBrowserFunctionBar;

@protocol YBImageBrowserFunctionBarDelegate <NSObject>

- (void)ybImageBrowserFunctionBar:(YBImageBrowserFunctionBar *)functionBar clickCellWithModel:(YBImageBrowserFunctionModel *)model;

@end

@interface YBImageBrowserFunctionBar : UIView

@property (nonatomic, weak) id <YBImageBrowserFunctionBarDelegate> delegate;

/**
 数据源（默认只有一个存储）
 */
@property (nonatomic, copy) NSArray<YBImageBrowserFunctionModel *> *dataArray;

/**
 每一项的高度
 */
@property (nonatomic, assign) CGFloat heightOfCell;

/**
 操作栏占最大可视高度的比例
 */
@property (nonatomic, assign) CGFloat maxScaleOfOperationBar;

/**
 展示
 */
- (void)show;
- (void)showToView:(UIView *)view;

/**
 隐藏
 */
- (void)hide;
- (void)hideWithAnimate:(BOOL)animate;

/**
 转场动画持续时间
 */
@property (nonatomic, assign) CGFloat timeOfAnimation;

/**
 当前是否是展示状态
 */
@property (nonatomic, assign, readonly) BOOL isShow;

/**
 取消按钮的文案
 */
@property (nonatomic, copy) NSString *cancelText;

@end
