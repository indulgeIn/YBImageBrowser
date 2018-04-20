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
        imageBrowserBundle = [NSBundle bundleForClass:YBImageBrowser.class];
    }
    return imageBrowserBundle;
}

@end
