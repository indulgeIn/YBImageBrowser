//
//  YBIBUtilities.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBUtilities.h"
#import <sys/utsname.h>


UIWindow *YBIBGetNormalWindow(void) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *temp in windows) {
            if (temp.windowLevel == UIWindowLevelNormal) {
                window = temp; break;
            }
        }
    }
    return window;
}

UIViewController *YBIBGetTopController(void) {
    UIViewController *topController = nil;
    UIWindow *window = YBIBGetNormalWindow();
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:UIViewController.class]) {
        topController = nextResponder;
    } else {
        topController = window.rootViewController;
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
    }
    return topController;
}


@implementation YBIBUtilities

+ (BOOL)isIphoneX {
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

+ (void)countTimeConsumingOfCode:(void(^)(void))code {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    code?code():nil;
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    YBIBLOG(@"TimeConsuming: %f ms", linkTime *1000.0);
}

@end
