//
//  YBIBAuxiliaryViewHandler.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/27.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YBIBAuxiliaryViewHandler <NSObject>

@required

/// 展示正确情况的提示
- (void)yb_showCorrectToastWithContainer:(UIView *)container text:(NSString *)text;
/// 展示错误情况的提示
- (void)yb_showIncorrectToastWithContainer:(UIView *)container text:(NSString *)text;
/// 隐藏所有提示
- (void)yb_hideToastWithContainer:(UIView *)container;

/// 展示加载视图
- (void)yb_showLoadingWithContainer:(UIView *)container;
/// 展示带进度的加载视图
- (void)yb_showLoadingWithContainer:(UIView *)container progress:(CGFloat)progress;
/// 展示带文字的视图
- (void)yb_showLoadingWithContainer:(UIView *)container text:(NSString *)text;
/// 隐藏所有视图
- (void)yb_hideLoadingWithContainer:(UIView *)container;

@end

@interface YBIBAuxiliaryViewHandler : NSObject <YBIBAuxiliaryViewHandler>

@end

NS_ASSUME_NONNULL_END
