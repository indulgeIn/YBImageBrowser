//
//  YBImageBrowserUtilities.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

NSString * const YBImageBrowser_KVCKey_browserView = @"browserView";
NSString * const YBImageBrowser_notification_willToRespondsDeviceOrientation = @"YBImageBrowser_notification_willToRespondsDeviceOrientation";
NSString * const YBImageBrowser_notification_changeAlpha = @"YBImageBrowser_notification_changeAlpha";
NSString * const YBImageBrowser_notificationKey_changeAlpha = @"YBImageBrowser_notificationKey_changeAlpha";
NSString * const YBImageBrowser_notification_hideBrowerView = @"YBImageBrowser_notification_hideBrowerView";
NSString * const YBImageBrowser_notification_showBrowerView = @"YBImageBrowser_notification_showBrowerView";
NSString * const YBImageBrowser_notification_willShowBrowerViewWithTimeInterval = @"YBImageBrowser_notification_willShowBrowerViewWithTimeInterval";
NSString * const YBImageBrowser_notificationKey_willShowBrowerViewWithTimeInterval = @"YBImageBrowser_notification_willShowBrowerViewWithTimeInterval";

@implementation YBImageBrowserUtilities

+ (BOOL)isGif:(NSData *)data {
    return [[self getTypeOfImageData:data] isEqualToString:@"gif"];
}

+ (NSString *)getTypeOfImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x4D:
            return @"tiff";
        case 0x52:
            if ([data length] < 12)
                return nil;
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"])
                return @"webp";
            return nil;
    }
    return nil;
}

+ (UIViewController *)getTopController {
    UIViewController *topController = nil;
    UIWindow *window = [self getNormalWindow];
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:UIViewController.class])
        topController = nextResponder;
    else {
        topController = window.rootViewController;
        while (topController.presentedViewController)
            topController = topController.presentedViewController;
    }
    return topController;
}

+ (UIWindow *)getNormalWindow {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * temp in windows) {
            if (temp.windowLevel == UIWindowLevelNormal) {
                window = temp;
                break;
            }
        }
    }
    return window;
}

+ (CGFloat)getWidthWithAttStr:(NSAttributedString *)attStr {
    return [attStr boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width;
}

+ (UIImage *)scaleToSizeWithImage:(UIImage *)image size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

+ (UIImage *)cutToRectWithImage:(UIImage *)image rect:(CGRect)rect {
    CGImageRef _cgImage = image.CGImage;
    CGImageRef cgImage = CGImageCreateWithImageInRect(_cgImage, rect);
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return resultImage;
}

+ (void)countTimeConsumingOfCode:(void(^)(void))code {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    code?code():nil;
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    YBLOG(@"TimeConsuming: %f ms", linkTime *1000.0);
}


@end
