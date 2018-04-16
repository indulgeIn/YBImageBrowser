//
//  YBImageBrowserPromptBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowserPromptBar;

@interface UIView (YBImageBrowserPromptBar)

@property (nonatomic, strong, readonly) YBImageBrowserPromptBar *ybImageBrowserPromptBar;

/**
 显示勾勾的弹框

 @param text 显示文案
 */
- (void)yb_showHookPromptWithText:(NSString *)text;

/**
 显示叉叉的弹框

 @param text 显示文案
 */
- (void)yb_showForkPromptWithText:(NSString *)text;

/**
 立刻消失
 */
- (void)yb_hidePromptImmediately;

@end


typedef NS_ENUM(NSInteger, YBImageBrowserPromptBarType) {
    YBImageBrowserPromptBarTypeHook,
    YBImageBrowserPromptBarTypeFork
};

@interface YBImageBrowserPromptBar : UIView

@property (nonatomic, strong, readonly) UILabel *textLabel;

@property (nonatomic, assign) YBImageBrowserPromptBarType barType;

- (instancetype _Nullable)initWithFrame:(CGRect)frame barType:(YBImageBrowserPromptBarType)barType;

- (void)drawView;

- (void)resetUserInterfaceLayout_textLabel;

@end

NS_ASSUME_NONNULL_END
