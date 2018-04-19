//
//  YBImageBrowserUtilities.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

#if DEBUG
#define YBLOG(format, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
#define YBLOG(format, ...) nil
#endif

#define YBLOG_WARNING(discribe) YBLOG(@"%@ ⚠️ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)
#define YBLOG_ERROR(discribe) YBLOG(@"%@ ❌ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)

#define YB_MAINTHREAD_SYNC(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}
#define YB_MAINTHREAD_ASYNC(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

#define YB_READIMAGE_FROMFILE(fileName, fileType) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:fileType]]

#define YB_NORMALWINDOW [YBImageBrowserUtilities getNormalWindow]

#define YB_STATUSBAR_ORIENTATION [UIApplication sharedApplication].statusBarOrientation
#define YB_SCREEN_HEIGHT (((YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortrait) || (YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortraitUpsideDown)) ? [UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width)
#define YB_SCREEN_WIDTH (((YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortrait) || (YB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortraitUpsideDown)) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)

#define YB_IS_IPHONEX (YB_SCREEN_HEIGHT == 812)
#define YB_HEIGHT_EXTRABOTTOM (YB_IS_IPHONEX ? 34.0 : 0)
#define YB_HEIGHT_STATUSBAR (YB_IS_IPHONEX ? 44.0 : 20.0)

#define YB_HEIGHT_TOOLBAR (YB_HEIGHT_STATUSBAR + 44)

FOUNDATION_EXTERN NSString * const YBImageBrowser_KVCKey_browserView;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notification_willToRespondsDeviceOrientation;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notification_changeAlpha;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notificationKey_changeAlpha;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notification_hideBrowerView;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notification_showBrowerView;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notification_willShowBrowerViewWithTimeInterval;
FOUNDATION_EXTERN NSString * const YBImageBrowser_notificationKey_willShowBrowerViewWithTimeInterval;

typedef NS_ENUM(NSUInteger, YBImageBrowserImageViewFillType) {
    YBImageBrowserImageViewFillTypeFullWidth,   //宽度抵满屏幕宽度，高度不定
    YBImageBrowserImageViewFillTypeCompletely   //保证图片完整显示情况下最大限度填充
};

typedef NS_ENUM(NSUInteger, YBImageBrowserScreenOrientation) {
    YBImageBrowserScreenOrientationUnknown, //未知
    YBImageBrowserScreenOrientationVertical, //屏幕竖直方向展示
    YBImageBrowserScreenOrientationHorizontal   //屏幕水平方向展示
};

typedef NS_ENUM(NSUInteger, YBImageBrowserAnimation) {
    YBImageBrowserAnimationNone,    //无动画
    YBImageBrowserAnimationFade,    //渐隐
    YBImageBrowserAnimationMove     //移动
};


@interface YBImageBrowserUtilities : NSObject

+ (BOOL)isGif:(NSData *)data;
+ (UIViewController *)getTopController;
+ (UIWindow *)getNormalWindow;
+ (CGFloat)getWidthWithAttStr:(NSAttributedString *)attStr;
+ (UIImage *)scaleToSizeWithImage:(UIImage *)image size:(CGSize)size;
+ (UIImage *)cutToRectWithImage:(UIImage *)image rect:(CGRect)rect;
+ (void)countTimeConsumingOfCode:(void(^)(void))code;

@end
