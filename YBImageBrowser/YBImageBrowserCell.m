//
//  YBImageBrowserCell.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserCell.h"
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface YBImageBrowserCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation YBImageBrowserCell

#pragma mark life cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
    }
    return self;
}
- (void)prepareForReuse {
    [self.scrollView setZoomScale:1.0 animated:NO];
    self.imageView.image = nil;
}

#pragma mark public
- (void)loadImageWithModel:(YBImageBrowserModel *)model {
    
    if (model.image) {
        
        [self configImageViewWithImage:model.image];
        
    } else if (model.url) {
        
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.url options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            
            if (error) {
                
            } else {
                model.image = image;
                [self configImageViewWithImage:image];
            }
            
        }];
    }
}

#pragma mark private
- (void)configImageViewWithImage:(UIImage *)image {
    
    CGSize imageSize = image.size;
    CGRect imageViewFrame = CGRectMake(0, 0, 0, 0);
    CGFloat scrollViewWidth = self.scrollView.bounds.size.width;
    CGFloat scrollViewHeight = self.scrollView.bounds.size.height;
    
    CGFloat scrollViewScale = scrollViewWidth / scrollViewHeight;
    
    imageViewFrame.size.width = scrollViewWidth;
    imageViewFrame.size.height = scrollViewWidth * (imageSize.height / imageSize.width);
    
    if (imageSize.width / imageSize.height >= scrollViewScale) {
        imageViewFrame.origin.y = (scrollViewHeight - imageViewFrame.size.height) / 2.0;
        self.scrollView.contentSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
    } else {
        imageViewFrame.origin.y = 0;
        self.scrollView.contentSize = CGSizeMake(scrollViewWidth, imageViewFrame.size.height);
    }
    
    self.imageView.frame = imageViewFrame;
    self.imageView.image = image;

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
