//
//  YBImageBrowserCell.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserCell.h"

@interface YBImageBrowserCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation YBImageBrowserCell

#pragma mark life cycle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
    }
    return self;
}
- (void)prepareForReuse {
    [self.scrollView setZoomScale:1.0 animated:NO];
}

#pragma mark public

#pragma mark private
- (CGRect)countImageViewFrameWithImage:(UIImage *)image {
    
    CGSize imageSize = image.size;
    CGRect imageViewFrame = CGRectMake(0, 0, 0, 0);
    CGFloat scrollViewWidth = self.scrollView.bounds.size.width;
    CGFloat scrollViewHeight = self.scrollView.bounds.size.height;
    
    CGFloat selfScale = scrollViewWidth / scrollViewHeight;
    
    imageViewFrame.size.width = scrollViewWidth;
    imageViewFrame.size.height = scrollViewWidth * (imageSize.height / imageSize.width);
    
    if (imageSize.width / imageSize.height >= selfScale) {
        imageViewFrame.origin.y = (scrollViewHeight - imageViewFrame.size.height) / 2.0;
        self.scrollView.contentSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
    } else {
        imageViewFrame.origin.y = 0;
        self.scrollView.contentSize = CGSizeMake(scrollViewWidth, imageViewFrame.size.height);
    }
    
    return imageViewFrame;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGRect imageViewFrame = self.imageView.frame;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    if (imageViewFrame.size.height > scrollViewHeight) {
        imageViewFrame.origin.y = 0;
    } else {
        imageViewFrame.origin.y = (scrollViewHeight - imageViewFrame.size.height) / 2.0;
    }
    self.imageView.frame = imageViewFrame;
}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark getter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        _scrollView.maximumZoomScale = 5;
        _scrollView.minimumZoomScale = 1;
        _scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width, _scrollView.bounds.size.height);
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollView;
}

@end
