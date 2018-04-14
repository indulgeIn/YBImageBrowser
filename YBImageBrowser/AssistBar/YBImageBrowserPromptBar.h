//
//  YBImageBrowserPromptBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

@class YBImageBrowserPromptBar;

@interface UIView (YBImageBrowserPromptBar)

@property (nonatomic, strong) YBImageBrowserPromptBar *promptBar;

- (void)showHookWithText:(NSString *)text;
- (void)showForkWithText:(NSString *)text;

@end

typedef NS_ENUM(NSInteger, YBImageBrowserPromptBarType) {
    YBImageBrowserPromptBarTypeHook, //正确的勾勾
    YBImageBrowserPromptBarTypeFork  //错误的叉叉
};

@interface YBImageBrowserPromptBar : UIView

@property (nonatomic, strong, readonly) UILabel *textLabel;

- (instancetype)initWithFrame:(CGRect)frame barType:(YBImageBrowserPromptBarType)barType;

- (void)drawView;

- (void)resetUserInterfaceLayout_textLabel;

@end
