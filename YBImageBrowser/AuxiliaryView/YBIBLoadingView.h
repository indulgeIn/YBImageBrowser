//
//  YBIBLoadingView.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/9/1.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (YBIBLoading)

- (void)ybib_showLoading;

- (void)ybib_showLoadingWithProgress:(CGFloat)progress;

- (void)ybib_showLoadingWithText:(NSString *)text click:(nullable void(^)(void))click;

- (void)ybib_hideLoading;

@end


@interface YBIBLoadingView : UIView

- (void)show;

- (void)showProgress:(CGFloat)progress;

- (void)showText:(NSString *)text click:(void(^)(void))click;

@end

NS_ASSUME_NONNULL_END
