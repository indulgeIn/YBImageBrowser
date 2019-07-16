//
//  YBIBToastView.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/20.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (YBIBToast)

- (void)ybib_showHookToast:(NSString *)text;

- (void)ybib_showForkToast:(NSString *)text;

- (void)ybib_hideToast;

@end


typedef NS_ENUM(NSInteger, YBIBToastType) {
    YBIBToastTypeNone,
    YBIBToastTypeHook,
    YBIBToastTypeFork
};

@interface YBIBToastView : UIView

- (void)showWithText:(NSString *)text type:(YBIBToastType)type;

@end

NS_ASSUME_NONNULL_END
