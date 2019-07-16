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
    static BOOL isIphoneX = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *platformSet = [NSSet setWithObjects:@"iPhone10,3", @"iPhone10,6", @"iPhone11,8", @"iPhone11,2", @"iPhone11,4", @"iPhone11,6", nil];
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        if ([platform isEqualToString:@"x86_64"] || [platform isEqualToString:@"i386"]) {
            platform = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
        }
        isIphoneX = [platformSet containsObject:platform];
    });
    return isIphoneX;
}

CGFloat YBIBStatusbarHeight(void) {
    return YBIBIsIphoneXSeries() ? 44 : 20;
}

CGFloat YBIBSafeAreaHeight(void) {
    return YBIBIsIphoneXSeries() ? 34 : 0;
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
            padding.bottom = YBIBSafeAreaHeight();
            padding.top = 0;
        } else if (reverse) {
            padding.top = YBIBSafeAreaHeight();
            padding.bottom = 0;
        }
        padding.left = padding.right = MAX(YBIBSafeAreaHeight(), YBIBStatusbarHeight());
    } else {
        if (orientation == UIDeviceOrientationPortrait) {
            padding.top = YBIBStatusbarHeight();
            padding.bottom = barOrientation == UIDeviceOrientationPortrait ? YBIBSafeAreaHeight() : 0;
        } else {
            padding.bottom = YBIBStatusbarHeight();
            padding.top = barOrientation == UIDeviceOrientationPortrait ? YBIBSafeAreaHeight() : 0;
        }
        padding.left = padding.right = UIDeviceOrientationIsLandscape(barOrientation) ? YBIBSafeAreaHeight() : 0 ;
    }
    return padding;
}


@implementation YBIBUtilities

@end
