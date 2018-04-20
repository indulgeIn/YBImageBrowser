//
//  NSBundle+YBImageBrowser.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/20.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "NSBundle+YBImageBrowser.h"
#import "YBImageBrowser.h"

static NSBundle *imageBrowserBundle = nil;

@implementation NSBundle (YBImageBrowser)

+ (instancetype)yBImageBrowserBundle
{
    if (imageBrowserBundle == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:YBImageBrowser.class];
        NSString *path = [bundle pathForResource:@"YBImageBrowser" ofType:@"bundle"];
        imageBrowserBundle = [NSBundle bundleWithPath:path];
    }
    return imageBrowserBundle;
}

@end
