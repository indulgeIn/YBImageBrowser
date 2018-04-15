//
//  YBImageBrowserAnimatedTransitioningManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/15.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserAnimatedTransitioningManager.h"

@interface YBImageBrowserAnimatedTransitioningManager () 

@property (nonatomic, strong) UIImageView *animateImageView;

@end

@implementation YBImageBrowserAnimatedTransitioningManager

#pragma mark UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromController.view;
    UIView *toView = toController.view;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    //入场动效
    if (toController.isBeingPresented) {
        
        [containerView addSubview:toView];
        
        CGRect fromFrame = [self getFrameInWindowWithImageView:self.currentModel.sourceImageView];
        UIImage *image = [self getPosterImageWithModel:self.currentModel preview:NO];
        if (CGRectEqualToRect(fromFrame, CGRectZero) || !image) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            return;
        }
        
        __block CGRect toFrame;
        [YBImageBrowserCell countWithContainerSize:containerView.bounds.size image:image screenOrientation:self.imageBrowser.so_screenOrientation verticalFillType:self.imageBrowser.verticalScreenImageViewFillType horizontalFillType:self.imageBrowser.horizontalScreenImageViewFillType completed:^(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale) {
            toFrame = imageFrame;
        }];
        
        self.animateImageView.image = image;
        self.animateImageView.frame = fromFrame;
        [containerView addSubview:self.animateImageView];
        toView.alpha = 0;
        [UIView animateWithDuration:duration animations:^{
            toView.alpha = 1;
            self.animateImageView.frame = toFrame;
        } completion:^(BOOL finished) {
            [self.animateImageView removeFromSuperview];
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
    
    //出场动效
    if (fromController.isBeingDismissed) {
        
        CGRect toFrame = [self getFrameInWindowWithImageView:self.currentModel.sourceImageView];
        UIImageView *fromImageView = [self getCurrentImageViewFromBrowser:self.imageBrowser];
        if (CGRectEqualToRect(toFrame, CGRectZero) || !fromImageView) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            return;
        }
        
        self.animateImageView.image = fromImageView.image;
        self.animateImageView.frame = [self getFrameInWindowWithImageView:fromImageView];
        [containerView addSubview:self.animateImageView];
        
        fromImageView.hidden = YES;
        
        [UIView animateWithDuration:duration animations:^{
            fromView.alpha = 0;
            self.animateImageView.frame = toFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
    
}

#pragma mark private

//从来源的图片视图拿到基于屏幕的frame
- (CGRect)getFrameInWindowWithImageView:(UIImageView *)imageView {
    if (imageView) {
        return [imageView convertRect:imageView.bounds toView:[YBImageBrowserUtilities getNormalWindow]];
    } else {
        return CGRectZero;
    }
}

//从model里面拿到做动画的图片
- (UIImage *)getPosterImageWithModel:(YBImageBrowserModel *)model preview:(BOOL)preview {
    if (!preview && model.sourceImageView && model.sourceImageView.image) {
        return model.sourceImageView.image;
    }
    if (model.image) {
        return model.image;
    } else if (model.animatedImage) {
        return model.animatedImage.posterImage ?: nil;
    } else {
        if (!preview && model.previewModel) {
            return [self getPosterImageWithModel:model preview:YES];
        } else {
            return nil;
        }
    }
}


//根据图片浏览器拿到屏幕上展示的 UIImageView（本来可以通过点击的回调直接拿到，但是考虑到用户可能会通过代码调用移除）
- (UIImageView *)getCurrentImageViewFromBrowser:(YBImageBrowser *)browser {
    if (!browser) return nil;
     YBImageBrowserView *browserView = [browser valueForKey:@"browserView"];
    if (!browserView) return nil;
    YBImageBrowserCell *cell = (YBImageBrowserCell *)[browserView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:browserView.currentIndex inSection:0]];
    if (!cell) return nil;
    return cell.imageView;
}

#pragma mark getter

- (UIImageView *)animateImageView {
    if (!_animateImageView) {
        _animateImageView = [UIImageView new];
        _animateImageView.contentMode = UIViewContentModeScaleAspectFill;
        _animateImageView.layer.masksToBounds = YES;
    }
    return _animateImageView;
}


@end
