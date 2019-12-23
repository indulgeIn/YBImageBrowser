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
    UIView *originView = [super hitTest:point withEvent:event];
    if ([originView isKindOfClass:self.class]) {
        // Continue hit-testing if the view is kind of 'self.class'.
        return nil;
    }
    return originView;
}

@end
