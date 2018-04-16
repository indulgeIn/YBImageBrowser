//
//  YBImageBrowserAnimatedTransitioningManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/15.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserAnimatedTransitioning.h"

@interface YBImageBrowserAnimatedTransitioning () {
    __weak YBImageBrowser *browser;
}

@property (nonatomic, strong) UIImageView *animateImageView;

@end

@implementation YBImageBrowserAnimatedTransitioning

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
        
        __block CGRect fromFrame = CGRectZero;
        __block UIImage *image = nil;
        [self in_getShowInfoFromBrowser:browser complete:^(CGRect _fromFrame, UIImage *_fromImage, BOOL _cancel) {
            fromFrame = _fromFrame;
            image = _fromImage;
        }];
        if (CGRectEqualToRect(fromFrame, CGRectZero) || !image) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            return;
        }
        
        __block CGRect toFrame;
        [YBImageBrowserCell countWithContainerSize:containerView.bounds.size image:image screenOrientation:browser.so_screenOrientation verticalFillType:browser.verticalScreenImageViewFillType horizontalFillType:browser.horizontalScreenImageViewFillType completed:^(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale) {
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
        
        CGRect toFrame = [self getFrameInWindowWithView:[self getCurrentModelFromBrowser:browser].sourceImageView];
        UIImageView *fromImageView = [self getCurrentImageViewFromBrowser:browser];
        if (CGRectEqualToRect(toFrame, CGRectZero) || !fromImageView) {
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            return;
        }
        
        self.animateImageView.image = fromImageView.image;
        self.animateImageView.frame = [self getFrameInWindowWithView:fromImageView];
        [containerView addSubview:self.animateImageView];
        
        fromImageView.hidden = YES;
        
        [UIView animateWithDuration:duration animations:^{
            fromView.alpha = 0;
            self.animateImageView.frame = toFrame;
        } completion:^(BOOL finished) {
            [self.animateImageView removeFromSuperview];
            [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
}

#pragma mark public

- (void)setInfoWithImageBrowser:(YBImageBrowser *)browser {
    if (!browser) return;
    self->browser = browser;
}

#pragma mark private

//入场：从图片浏览器拿到初始化过后首先显示的数据
- (void)in_getShowInfoFromBrowser:(YBImageBrowser *)browser complete:(void(^)(CGRect fromFrame, UIImage *fromImage, BOOL cancel))complete {
    
    CGRect _fromFrame = CGRectZero;
    UIImage *_fromImage = nil;
    BOOL _cancel = NO;
    
    YBImageBrowserModel *firstModel;
    NSArray *models = browser.dataArray;
    NSUInteger index = browser.currentIndex;
    
    if (models && models.count > browser.currentIndex) {
        
        //用户设置了数据源数组
        firstModel = models[index];
        _fromFrame = firstModel.sourceImageView ? [self getFrameInWindowWithView:firstModel.sourceImageView] : CGRectZero;
        _fromImage = [self in_getPosterImageWithModel:firstModel preview:NO];
        
    } else if (browser.dataSource) {
        
        //用户使用了数据源代理
        UIImageView *tempImageView = [browser.dataSource respondsToSelector:@selector(imageViewOfTouchForImageBrowser:)] ? [browser.dataSource imageViewOfTouchForImageBrowser:browser] : nil;
        _fromFrame = tempImageView ? [self getFrameInWindowWithView:tempImageView] : CGRectZero;
        _fromImage = tempImageView.image;
        
    } else {
        YBLOG_ERROR(@"you must perform selector(setDataArray:) or implementation protocol(dataSource) of YBImageBrowser to configuration data of user interface")
        _cancel = YES;
    }
    
    if (complete) complete(_fromFrame, _fromImage, _cancel);
}

//入场：从 model 里面拿到做动画 image（配置数据源数组时用）
- (UIImage *)in_getPosterImageWithModel:(YBImageBrowserModel *)model preview:(BOOL)preview {
    if (!preview && model.sourceImageView && model.sourceImageView.image) {
        return model.sourceImageView.image;
    }
    if (model.image) {
        return model.image;
    } else if (model.animatedImage) {
        return model.animatedImage.posterImage ?: nil;
    } else {
        if (!preview && model.previewModel) {
            return [self in_getPosterImageWithModel:model preview:YES];
        } else {
            return nil;
        }
    }
}

//拿到 view 基于屏幕的 frame
- (CGRect)getFrameInWindowWithView:(UIView *)view {
    return view ? [view convertRect:view.bounds toView:YB_NORMALWINDOW] : CGRectZero;
}

//从图片浏览器拿到当前显示的 model
- (YBImageBrowserModel *)getCurrentModelFromBrowser:(YBImageBrowser *)browser {
    return [self getCurrentCellFromBrowser:browser].model;
}

//从图片浏览器拿到当前显示的 imageView
- (UIImageView *)getCurrentImageViewFromBrowser:(YBImageBrowser *)browser {
    return [self getCurrentCellFromBrowser:browser].imageView;
}

//从图片浏览器拿到当前显示的 cell
- (YBImageBrowserCell *)getCurrentCellFromBrowser:(YBImageBrowser *)browser {
    if (!browser) return nil;
    YBImageBrowserView *browserView = [browser valueForKey:YBImageBrowser_KVCKey_browserView];
    if (!browserView) return nil;
    YBImageBrowserCell *cell = (YBImageBrowserCell *)[browserView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:browserView.currentIndex inSection:0]];
    return cell;
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
