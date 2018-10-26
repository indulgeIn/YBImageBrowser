//
//  YBIBTransitionManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/4.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBTransitionManager.h"
#import "YBImageBrowser+Internal.h"
#import "YBIBUtilities.h"
#import "YBImageBrowserCellProtocol.h"

@interface YBIBTransitionManager () {
    BOOL _isEnter;
}
@property (nonatomic, strong) UIImageView *animateImageView;
@property (nonatomic, assign) BOOL isTransitioning;
@end

@implementation YBIBTransitionManager

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isTransitioning = NO;
        self->_isEnter = NO;
    }
    return self;
}

#pragma mark <UIViewControllerAnimatedTransitioning>

- (void)animationEnded:(BOOL)transitionCompleted {
    if (self.imageBrowser && self.imageBrowser.delegate && [self.imageBrowser.delegate respondsToSelector:@selector(yb_imageBrowser:transitionAnimationEndedWithIsEnter:)]) {
        [self.imageBrowser.delegate yb_imageBrowser:self.imageBrowser transitionAnimationEndedWithIsEnter:self->_isEnter];
    }
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return self.imageBrowser.transitionDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromController.view;
    UIView *toView = toController.view;
    
    // Enter
    if (toController.isBeingPresented) {
        self->_isEnter = YES;
        self.isTransitioning = YES;
        switch (self.imageBrowser.enterTransitionType) {
            case YBImageBrowserTransitionTypeNone: {
                [containerView addSubview:toView];
                [self completeTransition:transitionContext isEnter:YES];
            }
                break;
            case YBImageBrowserTransitionTypeFade: {
                [containerView addSubview:toView];
                [containerView addSubview:self.animateImageView];
                [self enter_configAnimateImageView];
                self.animateImageView.frame = [self enter_toFrame];
                self.animateImageView.alpha = 0;
                toView.alpha = 0;
                [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                    self.animateImageView.alpha = 1;
                    toView.alpha = 1;
                } completion:^(BOOL finished) {
                    [self.animateImageView removeFromSuperview];
                    [self completeTransition:transitionContext isEnter:YES];
                }];
            }
                break;
            case YBImageBrowserTransitionTypeCoherent: {
                if ([self enter_configAnimateImageView]) {
                    [containerView addSubview:toView];
                    [containerView addSubview:self.animateImageView];
                    toView.alpha = 0;
                    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                        toView.alpha = 1;
                        self.animateImageView.frame = [self enter_toFrame];
                    } completion:^(BOOL finished) {
                        [self.animateImageView removeFromSuperview];
                        [self completeTransition:transitionContext isEnter:YES];
                    }];
                } else {
                    [containerView addSubview:toView];
                    [self completeTransition:transitionContext isEnter:YES];
                }
            }
                break;
        }
    }
    
    // Out
    if (fromController.isBeingDismissed) {
        self->_isEnter = NO;
        self.isTransitioning = YES;
        switch (self.imageBrowser.outTransitionType) {
            case YBImageBrowserTransitionTypeNone: {
                [self completeTransition:transitionContext isEnter:NO];
            }
                break;
            case YBImageBrowserTransitionTypeFade: {
                UIView *fromAnimateView = [self out_fromAnimateView];
                [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                    fromAnimateView.alpha = 0;
                    fromView.alpha = 0;
                } completion:^(BOOL finished) {
                    [self completeTransition:transitionContext isEnter:NO];
                }];
            }
                break;
            case YBImageBrowserTransitionTypeCoherent: {
                UIView *fromAnimateView = [self out_fromAnimateView];
                if (fromAnimateView) {
                    CGRect fromFrame = fromAnimateView.frame;
                    CGRect toFrame = [self out_toFrameWithView:fromAnimateView.superview];
                    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                        
                        fromView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
                        id sourceObj = [self out_toSourceObj];
                        if ([sourceObj isKindOfClass:UIView.class])
                            fromAnimateView.contentMode = ((UIImageView *)sourceObj).contentMode;
                        
                        if ([fromAnimateView isKindOfClass:UIImageView.class]) {
                            fromAnimateView.frame = toFrame;
                        } else {
                            CGFloat scale = MAX(toFrame.size.width / fromFrame.size.width, toFrame.size.height / fromFrame.size.height);
                            fromAnimateView.center = CGPointMake(toFrame.size.width * fromAnimateView.layer.anchorPoint.x + toFrame.origin.x, toFrame.size.height * fromAnimateView.layer.anchorPoint.y + toFrame.origin.y);;
                            fromAnimateView.transform = CGAffineTransformScale(fromAnimateView.transform, scale, scale);
                        }
                    } completion:^(BOOL finished) {
                        [self completeTransition:transitionContext isEnter:NO];
                    }];
                } else {
                    [self completeTransition:transitionContext isEnter:NO];
                }
            }
                break;
        }
    }
}

- (void)completeTransition:(nullable id <UIViewControllerContextTransitioning>)transitionContext isEnter:(BOOL)isEnter {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    self.isTransitioning = NO;
    if (!isEnter) {
        self.imageBrowser.hiddenSourceObject = nil;
    }
}

#pragma mark - private

- (BOOL)enter_configAnimateImageView {
    self.imageBrowser.hiddenSourceObject = nil;
    
    id<YBImageBrowserCellDataProtocol> data = [self.imageBrowser.browserView dataAtIndex:self.imageBrowser.currentIndex];
    if (!data) return NO;
    if (![data respondsToSelector:@selector(yb_browserCellSourceObject)]) return NO;
    id sourceObj = data.yb_browserCellSourceObject;
    if (!sourceObj) return NO;
    
    self.imageBrowser.hiddenSourceObject = sourceObj;
    
    CALayer *sourceLayer = nil;
    if ([sourceObj isKindOfClass:UIView.class]) {
        UIView *view = (UIView *)sourceObj;
        sourceLayer = view.layer;
        self.animateImageView.contentMode = view.contentMode;
        if ([view isKindOfClass:UIImageView.class]) {
            self.animateImageView.image = ((UIImageView *)view).image;
        } else {
            self.animateImageView.layer.contents = view.layer;
        }
    } else if ([sourceObj isKindOfClass:CALayer.class]) {
        sourceLayer = sourceObj;
        self.animateImageView.layer.contents = sourceLayer.contents;
    } else {
        return NO;
    }
    
    // Ensure the best transition effect.
    self.animateImageView.layer.masksToBounds = sourceLayer.masksToBounds;
    self.animateImageView.layer.cornerRadius = sourceLayer.cornerRadius;
    self.animateImageView.layer.backgroundColor = sourceLayer.backgroundColor;
    
    self.animateImageView.frame = [sourceObj convertRect:sourceLayer.bounds toView:YBIBGetNormalWindow()];
    
    return YES;
}

- (CGRect)enter_toFrame {
    id<YBImageBrowserCellDataProtocol> data = [self.imageBrowser.browserView dataAtIndex:self.imageBrowser.currentIndex];
    if (!data) return CGRectZero;
    CGSize size = self.animateImageView.image ? self.animateImageView.image.size : self.animateImageView.layer.bounds.size;
    if ([data respondsToSelector:@selector(yb_browserCurrentImageFrameWithImageSize:)]) {
        return [data yb_browserCurrentImageFrameWithImageSize:size];
    }
    return CGRectZero;
}

- (UIView *)out_fromAnimateView {
    UICollectionViewCell<YBImageBrowserCellProtocol> *cell = (UICollectionViewCell<YBImageBrowserCellProtocol> *)[self.imageBrowser.browserView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.imageBrowser.currentIndex inSection:0]];
    if (!cell) return nil;
    if ([cell respondsToSelector:@selector(yb_browserCurrentForegroundView)]) {
        return [cell yb_browserCurrentForegroundView];
    }
    return nil;
}

- (CGRect)out_toFrameWithView:(UIView *)view {
    CGFloat width = [UIScreen mainScreen].bounds.size.width,
    height = [UIScreen mainScreen].bounds.size.height;
    CGRect frame = CGRectMake(width / 2, height / 2, 1, 1);
    id sourceObj = [self out_toSourceObj];
    if (!sourceObj || ![sourceObj respondsToSelector:@selector(bounds)]) {
        return frame;
    }
    CGRect bounds = ((NSValue *)[sourceObj valueForKey:@"bounds"]).CGRectValue;
    CGRect result = [sourceObj convertRect:bounds toView:view];
    return result;
}

- (id)out_toSourceObj {
    id<YBImageBrowserCellDataProtocol> data = [self.imageBrowser.browserView dataAtIndex:self.imageBrowser.currentIndex];
    if (!data || ![data respondsToSelector:@selector(yb_browserCellSourceObject)]) {
        return nil;
    }
    id sourceObj = data.yb_browserCellSourceObject;
    return sourceObj;
}

#pragma mark - getter

- (UIImageView *)animateImageView {
    if (!_animateImageView) {
        _animateImageView = [UIImageView new];
    }
    return _animateImageView;
}

@end
