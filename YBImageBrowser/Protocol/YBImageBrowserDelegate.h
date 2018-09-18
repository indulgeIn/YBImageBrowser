//
//  YBImageBrowserDelegate.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBImageBrowserCellDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowser;

@protocol YBImageBrowserDelegate <NSObject>

@optional

- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser pageIndexChanged:(NSUInteger)index data:(id<YBImageBrowserCellDataProtocol>)data;

- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser respondsToLongPress:(UILongPressGestureRecognizer *)longPress;

- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser transitionAnimationEndedWithIsEnter:(BOOL)isEnter;

@end

NS_ASSUME_NONNULL_END
