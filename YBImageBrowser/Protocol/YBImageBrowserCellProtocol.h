//
//  YBImageBrowserCellProtocol.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBImageBrowserCellDataProtocol.h"
#import "YBIBGestureInteractionProfile.h"
#import "YBIBLayoutDirectionManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YBImageBrowserCellProtocol <NSObject>

@required

- (void)yb_initializeBrowserCellWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize;

@optional

- (void)yb_browserLayoutDirectionChanged:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize;

@property (nonatomic, copy) void(^yb_browserDismissBlock)(void);

@property (nonatomic, copy) void(^yb_browserToolBarHiddenBlock)(BOOL hidden);

@property (nonatomic, copy) void(^yb_browserScrollEnabledBlock)(BOOL enabled);

@property (nonatomic, copy) void(^yb_browserChangeAlphaBlock)(CGFloat alpha, CGFloat duration);

- (void)yb_browserPageIndexChanged:(NSUInteger)pageIndex ownIndex:(NSUInteger)ownIndex;

- (void)yb_browserBodyIsInTheCenter:(BOOL)isIn;

- (void)yb_browserInitializeFirst:(BOOL)isFirst;

- (void)yb_browserStatusBarOrientationBefore:(UIInterfaceOrientation)orientation;

- (__kindof UIView *)yb_browserCurrentForegroundView;

- (void)yb_browserSetGestureInteractionProfile:(YBIBGestureInteractionProfile *)giProfile;

@end

NS_ASSUME_NONNULL_END
