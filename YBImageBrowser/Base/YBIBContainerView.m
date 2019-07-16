//
//  YBIBContainerView.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/11.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBContainerView.h"

@implementation YBIBContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *subView in self.subviews.reverseObjectEnumerator) {
        CGPoint subPoint = [self convertPoint:point toView:subView];
        UIView *view = [subView hitTest:subPoint withEvent:event];
        if (view) return view;
    }
    return nil;
}

@end
