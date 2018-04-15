//
//  YBImageBrowserUtilities.h
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
#define YBLOG(format, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String]);
#define YBLOG_WARNING(discribe) YBLOG(@"%@ ⚠️ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)
#define YBLOG_ERROR(discribe) YBLOG(@"%@ ❌ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)
#else
#define YBLOG(format, ...) nil
#endif

#define YB_READIMAGE_FROMFILE(fileName, fileType) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:fileType]]

#define YB_STATUSBAR_ORIENTATION [UIApplication sharedApplication].statusBarOrientation
#define YB_SCREEN_HEIGHT (((YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortrait) || (YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortraitUpsideDown)) ? [UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width)
#define YB_SCREEN_WIDTH (((YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortrait) || (YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortraitUpsideDown)) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)

#define YB_IS_IPHONEX (YB_SCREEN_HEIGHT == 812)
#define YB_HEIGHT_EXTRABOTTOM (YB_IS_IPHONEX ? 34.0 : 0)
#define YB_HEIGHT_STATUSBAR (YB_IS_IPHONEX ? 44.0 : 20.0)

#define YB_HEIGHT_TOOLBAR (YB_HEIGHT_STATUSBAR + 44)

FOUNDATION_EXTERN NSString * const YBImageBrowser_notificationName_hideSelf;

typedef NS_ENUM(NSUInteger, YBImageBrowserImageViewFillType) {
    YBImageBrowserImageViewFillTypeFullWidth,   //宽度抵满屏幕宽度，高度不定
    YBImageBrowserImageViewFillTypeCompletely   //保证图片完整显示情况下最大限度填充
};

typedef NS_ENUM(NSUInteger, YBImageBrowserScreenOrientation) {
    YBImageBrowserScreenOrientationUnknown, //未知
    YBImageBrowserScreenOrientationVertical, //屏幕竖直方向展示
    YBImageBrowserScreenOrientationHorizontal   //屏幕水平方向展示
};

@interface YBImageBrowserUtilities : NSObject

+ (BOOL)isGif:(NSData *)data;
+ (UIViewController *)getTopController;
+ (UIWindow *)getNormalWindow;
+ (CGFloat)getWidthWithAttStr:(NSAttributedString *)attStr;

@end
