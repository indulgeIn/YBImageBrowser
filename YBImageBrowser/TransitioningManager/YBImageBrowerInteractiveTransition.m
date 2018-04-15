//
//  YBImageBrowerInteractiveTransition.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/15.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowerInteractiveTransition.h"

@interface YBImageBrowerInteractiveTransition ()

@end

@implementation YBImageBrowerInteractiveTransition

#pragma mark UIViewControllerInteractiveTransitioning
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromController.view;
    UIView *toView = toController.view;
    
    
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGRAct:)];
    [containerView addGestureRecognizer:panGR];
    
}

- (void)panGRAct:(UIPanGestureRecognizer *)pan {
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGPoint point = [pan locationInView:[UIApplication sharedApplication].keyWindow];
    CGFloat scale = point.y / window.bounds.size.height;
    if (pan.state == UIGestureRecognizerStateBegan) {
        
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        if (scale > 0.6) {
            [self finishInteractiveTransition];
        } else {
            [self cancelInteractiveTransition];
        }
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        if (point.y > 200) {
            [self updateInteractiveTransition:scale];
        }
    }
    
}

@end
