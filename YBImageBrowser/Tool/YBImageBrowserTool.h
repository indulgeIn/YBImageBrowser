//
//  YBImageBrowserTool.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/SDImageCache.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

#if DEBUG
#define YBLog(format, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String]);
#define YBLogWarning(discribe) YBLog(@"YBImageBrowser ~~~ ⚠️ ~~~ %@", discribe)
#define YBLogError(discribe) YBLog(@"YBImageBrowser ~~~ ❌ ~~~ %@", discribe)
#else
#define YBLog(FORMAT, ...) nil
#endif

FOUNDATION_EXTERN NSString * const YBImageBrowser_notificationName_hideSelf;

typedef NS_ENUM(NSUInteger, YBImageBrowserImageViewFillType) {
    YBImageBrowserImageViewFillTypeFullWidth,   //宽度抵满屏幕宽度，高度不定
    YBImageBrowserImageViewFillTypeCompletely   //保证图片完整显示情况下最大限度填充
};

@interface YBImageBrowserTool : NSObject

+ (BOOL)isGif:(NSData *)data;
+ (UIViewController *)getTopController;
+ (UIWindow *)getNormalWindow;

@end
