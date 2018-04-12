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

FOUNDATION_EXTERN NSString * const YBImageBrowser_notice_hideSelf;

#ifndef YBLog
#if DEBUG
#define YBLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define YBLog(FORMAT, ...) nil
#endif
#endif

BOOL YBImageBrowser_isGif(NSData *data);

@interface YBImageBrowserTool : NSObject

+ (UIViewController *)getTopController;
+ (UIWindow *)getNormalWindow;

@end
