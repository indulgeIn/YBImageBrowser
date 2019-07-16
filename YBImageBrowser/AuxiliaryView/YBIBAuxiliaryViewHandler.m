//
//  YBIBAuxiliaryViewHandler.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/27.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBAuxiliaryViewHandler.h"
#import "YBIBToastView.h"
#import "YBIBLoadingView.h"

@implementation YBIBAuxiliaryViewHandler

#pragma mark - <YBIBAuxiliaryViewHandler>

- (void)yb_showCorrectToastWithContainer:(UIView *)container text:(NSString *)text {
    [container ybib_showHookToast:text];
}

- (void)yb_showIncorrectToastWithContainer:(UIView *)container text:(NSString *)text {
    [container ybib_showForkToast:text];
}

- (void)yb_hideToastWithContainer:(UIView *)container {
    [container ybib_hideToast];
}

- (void)yb_showLoadingWithContainer:(UIView *)container {
    [container ybib_showLoading];
}

- (void)yb_showLoadingWithContainer:(UIView *)container progress:(CGFloat)progress {
    [container ybib_showLoadingWithProgress:progress];
}

- (void)yb_showLoadingWithContainer:(UIView *)container text:(NSString *)text {
    [container ybib_showLoadingWithText:text click:nil];
}

- (void)yb_hideLoadingWithContainer:(UIView *)container {
    [container ybib_hideLoading];
}

@end
