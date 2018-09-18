//
//  YBImageBrowserTipView.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/1.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, YBImageBrowserTipType) {
    YBImageBrowserTipTypeNone,
    YBImageBrowserTipTypeHook,
    YBImageBrowserTipTypeFork
};

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowserTipView;

@interface UIView (YBImageBrowserTipView)

- (void)yb_showHookTipView:(NSString *)text;

- (void)yb_showForkTipView:(NSString *)text;

- (void)yb_hideTipView;

@property (nonatomic, strong, readonly) YBImageBrowserTipView *yb_tipView;

@end

@interface YBImageBrowserTipView : UIView

- (void)startAnimationWithText:(NSString *)text type:(YBImageBrowserTipType)tipType;

@end

NS_ASSUME_NONNULL_END
