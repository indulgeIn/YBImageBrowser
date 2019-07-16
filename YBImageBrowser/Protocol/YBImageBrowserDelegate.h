//
//  YBImageBrowserDelegate.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/9.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowser;

@protocol YBImageBrowserDelegate <NSObject>

@optional

/**
 页码变化

 @param imageBrowser 图片浏览器
 @param page 当前页码
 @param data 数据
 */
- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser pageChanged:(NSInteger)page data:(id<YBIBDataProtocol>)data;

/**
 响应长按手势（若实现该方法将阻止其它地方捕获到长按事件）

 @param imageBrowser 图片浏览器
 @param data 数据
 */
- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser respondsToLongPressWithData:(id<YBIBDataProtocol>)data;

/**
 开始转场

 @param imageBrowser 图片浏览器
 @param isShow YES 表示入场，NO 表示出场
 */
- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser beginTransitioningWithIsShow:(BOOL)isShow;

/**
 结束转场

 @param imageBrowser 图片浏览器
 @param isShow YES 表示入场，NO 表示出场
 */
- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser endTransitioningWithIsShow:(BOOL)isShow;

@end

NS_ASSUME_NONNULL_END
