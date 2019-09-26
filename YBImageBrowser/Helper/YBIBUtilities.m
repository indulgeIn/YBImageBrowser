//
//  YBIBUtilities.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "YBIBUtilities.h"
#import <sys/utsname.h>


UIWindow * _Nullable YBIBNormalWindow(void) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *temp in windows) {
            if (temp.windowLevel == UIWindowLevelNormal) {
                return temp;
            }
        }
    }
    return window;
}

UIViewController * _Nullable YBIBTopController(void) {
    return YBIBTopControllerByWindow(YBIBNormalWindow());
}

UIViewController * _Nullable YBIBTopControllerByWindow(UIWindow *window) {
    if (!window) return nil;
        
    UIViewController *top = nil;
    id nextResponder;
    if (window.subviews.count > 0) {
        UIView *frontView = [window.subviews objectAtIndex:0];
        nextResponder = frontView.nextResponder;
    }
    if (nextResponder && [nextResponder isKindOfClass:UIViewController.class]) {
        top = nextResponder;
    } else {
        top = window.rootViewController;
    }
    
    while ([top isKindOfClass:UITabBarController.class] || [top isKindOfClass:UINavigationController.class] || top.presentedViewController) {
        if ([top isKindOfClass:UITabBarController.class]) {
            top = ((UITabBarController *)top).selectedViewController;
        } else if ([top isKindOfClass:UINavigationController.class]) {
            top = ((UINavigationController *)top).topViewController;
        } else if (top.presentedViewController) {
            top = top.presentedViewController;
        }
    }
    return top;
}

BOOL YBIBLowMemory(void) {
    static BOOL lowMemory = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned long long physicalMemory = [[NSProcessInfo processInfo] physicalMemory];
        lowMemory = physicalMemory > 0 && physicalMemory < 1024 * 1024 * 1500;
    });
    return lowMemory;
}

BOOL YBIBIsIphoneXSeries(void) {
    return YBIBStatusbarHeight() > 20;
}

CGFloat YBIBStatusbarHeight(void) {
    CGFloat height = 0;
    if (@available(iOS 11.0, *)) {
        height = UIApplication.sharedApplication.delegate.window.safeAreaInsets.top;
    }
    if (height <= 0) {
        height = UIApplication.sharedApplication.statusBarFrame.size.height;
    }
    if (height <= 0) {
        height = 20;
    }
    return height;
}

CGFloat YBIBSafeAreaBottomHeight(void) {
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = UIApplication.sharedApplication.delegate.window.safeAreaInsets.bottom;
    }
    return bottom;
}

UIImage *YBIBSnapshotView(UIView *view) {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

UIEdgeInsets YBIBPaddingByBrowserOrientation(UIDeviceOrientation orientation) {
    UIEdgeInsets padding = UIEdgeInsetsZero;
    if (!YBIBIsIphoneXSeries()) return padding;
    
    UIDeviceOrientation barOrientation = (UIDeviceOrientation)UIApplication.sharedApplication.statusBarOrientation;
    
    if (UIDeviceOrientationIsLandscape(orientation)) {
        BOOL same = orientation == barOrientation;
        BOOL reverse = !same && UIDeviceOrientationIsLandscape(barOrientation);
        if (same) {
            padding.bottom = YBIBSafeAreaBottomHeight();
            padding.top = 0;
        } else if (reverse) {
            padding.top = YBIBSafeAreaBottomHeight();
            padding.bottom = 0;
        }
        padding.left = padding.right = MAX(YBIBSafeAreaBottomHeight(), YBIBStatusbarHeight());
    } else {
        if (orientation == UIDeviceOrientationPortrait) {
            padding.top = YBIBStatusbarHeight();
            padding.bottom = barOrientation == UIDeviceOrientationPortrait ? YBIBSafeAreaBottomHeight() : 0;
        } else {
            padding.bottom = YBIBStatusbarHeight();
            padding.top = barOrientation == UIDeviceOrientationPortrait ? YBIBSafeAreaBottomHeight() : 0;
        }
        padding.left = padding.right = UIDeviceOrientationIsLandscape(barOrientation) ? YBIBSafeAreaBottomHeight() : 0 ;
    }
    return padding;
}


@implementation YBIBUtilities

@end
