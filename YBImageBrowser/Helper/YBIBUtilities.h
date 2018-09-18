//
//  YBIBUtilities.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#if DEBUG
#define YBIBLOG(format, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
#define YBIBLOG(format, ...) nil
#endif

#define YBIBLOG_WARNING(discribe) YBIBLOG(@"%@ ⚠️ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)
#define YBIBLOG_ERROR(discribe)   YBIBLOG(@"%@ ❌ SEL-%@ %@", self.class, NSStringFromSelector(_cmd), discribe)


#define YBIB_GET_QUEUE_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define YBIB_GET_QUEUE_MAIN_ASYNC(block) YBIB_GET_QUEUE_ASYNC(dispatch_get_main_queue(), block)


#define YBIB_STATUSBAR_ORIENTATION    [UIApplication sharedApplication].statusBarOrientation
#define YBIMAGEBROWSER_HEIGHT       ((YBIB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortrait || YBIB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortraitUpsideDown) ? [UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width)
#define YBIMAGEBROWSER_WIDTH        ((YBIB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortrait || YBIB_STATUSBAR_ORIENTATION == UIInterfaceOrientationPortraitUpsideDown) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height)


#define YBIB_IS_IPHONEX           [YBIBUtilities isIphoneX]
#define YBIB_HEIGHT_EXTRABOTTOM   (YBIB_IS_IPHONEX ? 34.0 : 0)
#define YBIB_HEIGHT_STATUSBAR     (YBIB_IS_IPHONEX ? 44.0 : 20.0)


UIWindow *YBIBGetNormalWindow(void);

UIViewController *YBIBGetTopController(void);


NS_ASSUME_NONNULL_BEGIN

@interface YBIBUtilities : NSObject

+ (BOOL)isIphoneX;

+ (void)countTimeConsumingOfCode:(void(^)(void))code;

@end

NS_ASSUME_NONNULL_END
