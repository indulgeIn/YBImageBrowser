//
//  YBIBFileManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/29.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBFileManager.h"
#import "YBImageBrowser.h"

// The best order for path scale search.
static NSArray *_NSBundlePreferredScales() {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[@1,@2,@3];
        } else if (screenScale <= 2) {
            scales = @[@2,@3,@1];
        } else {
            scales = @[@3,@2,@1];
        }
    });
    return scales;
}

// Add scale modifier to the file name (without path extension), from @"name" to @"name@2x".
static NSString *_NSStringByAppendingNameScale(NSString *string, CGFloat scale) {
    if (!string) return nil;
    if (fabs(scale - 1) <= __FLT_EPSILON__ || string.length == 0 || [string hasSuffix:@"/"]) return string.copy;
    return [string stringByAppendingFormat:@"@%@x", @(scale)];
}


@implementation YBIBFileManager

+ (NSBundle *)yBImageBrowserBundle {
    static NSBundle *imageBrowserBundle = nil;
    if (imageBrowserBundle == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:YBImageBrowser.class];
        NSString *path = [bundle pathForResource:@"YBImageBrowser" ofType:@"bundle"];
        imageBrowserBundle = [NSBundle bundleWithPath:path];
    }
    return imageBrowserBundle;
}

+ (UIImage *)getImageWithName:(NSString *)name {
    //Imitate 'YYImage', but don't need to determine image type, they are all 'png'.
    NSString *res = name, *path = nil;
    CGFloat scale = 1;
    NSArray *scales = _NSBundlePreferredScales();
    for (int s = 0; s < scales.count; s++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        NSString *scaledName = _NSStringByAppendingNameScale(res, scale);
        path = [[self yBImageBrowserBundle] pathForResource:scaledName ofType:@"png"];
        if (path) break;
    }
    if (!path.length) return nil;
    return [UIImage imageWithContentsOfFile:path];
}


@end
