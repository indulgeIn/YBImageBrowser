//
//  NSObject+YBImageBrowser.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/9/26.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "NSObject+YBImageBrowser.h"
#import <objc/runtime.h>

@implementation NSObject (YBImageBrowser)

static void *YBIBOriginAlphaKey = &YBIBOriginAlphaKey;
- (void)setYbib_originAlpha:(CGFloat)ybib_originAlpha {
    objc_setAssociatedObject(self, YBIBOriginAlphaKey, @(ybib_originAlpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)ybib_originAlpha {
    NSNumber *alpha = objc_getAssociatedObject(self, YBIBOriginAlphaKey);
    return alpha ? alpha.floatValue : 1;
}

@end
