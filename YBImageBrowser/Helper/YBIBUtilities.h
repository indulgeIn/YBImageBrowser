//
//  YBIBUtilities.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


#define YBIB_DISPATCH_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define YBIB_DISPATCH_ASYNC_MAIN(block) YBIB_DISPATCH_ASYNC(dispatch_get_main_queue(), block)


#define YBIB_CODE_EXEC_TIME(KEY, ...) \
CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent(); \
__VA_ARGS__ \
CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime); \
NSLog(@"%@ Time-Consuming: %fms", KEY, linkTime * 1000.0);


UIWindow * _Nonnull YBIBNormalWindow(void);

UIViewController * _Nullable YBIBTopController(void);
UIViewController * _Nullable YBIBTopControllerByWindow(UIWindow *);

BOOL YBIBLowMemory(void);

BOOL YBIBIsIphoneXSeries(void);
CGFloat YBIBStatusbarHeight(void);
CGFloat YBIBSafeAreaHeight(void);

UIImage *YBIBSnapshotView(UIView *);

/// This is orientation of 'YBImageBrowser' not 'UIDevice'.
UIEdgeInsets YBIBPaddingByBrowserOrientation(UIDeviceOrientation);


@interface YBIBUtilities : NSObject

@end

NS_ASSUME_NONNULL_END
