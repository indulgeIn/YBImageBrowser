//
//  YBImageBrowserCell.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserCell.h"
#import "YBImageBrowserTool.h"
#import "YBImageBrowserProgressBar.h"

@interface YBImageBrowserCell () <UIScrollViewDelegate>

@property (nonatomic, strong) FLAnimatedImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) YBImageBrowserModel *model;
@property (nonatomic, strong) YBImageBrowserProgressBar *progressBar;

@end

@implementation YBImageBrowserCell

#pragma mark life cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isLoadFailed = NO;
        [self.contentView addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
        [self addGesture];
    }
    return self;
}
- (void)prepareForReuse {
    [self.scrollView setZoomScale:1.0 animated:NO];
    self.imageView.image = nil;
    self.imageView.animatedImage = nil;
    if (self.progressBar.superview) {
        [self.progressBar removeFromSuperview];
    }
}

#pragma mark gesture
- (void)addGesture {
    UITapGestureRecognizer *tapOfSingle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapOfSingle:)];
    tapOfSingle.numberOfTapsRequired = 1;
    UITapGestureRecognizer *tapOfDouble = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapOfDouble:)];
    tapOfDouble.numberOfTapsRequired = 2;
    
    [tapOfSingle requireGestureRecognizerToFail:tapOfDouble];
    
    [self.scrollView addGestureRecognizer:tapOfSingle];
    [self.scrollView addGestureRecognizer:tapOfDouble];
}
- (void)respondsToTapOfSingle:(UITapGestureRecognizer *)tap {
    [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notice_hide object:nil];
}
- (void)respondsToTapOfDouble:(UITapGestureRecognizer *)tap {
    UIScrollView *scrollView = (UIScrollView *)tap.view;
    CGPoint point = [tap locationInView:scrollView];
    if (scrollView.zoomScale == scrollView.maximumZoomScale) {
        [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
    } else {
        [scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];
    }
}

#pragma mark public
- (void)reLoad {
    [self loadImageWithModel:self.model];
}
- (void)loadImageWithModel:(YBImageBrowserModel *)model {
    if (!model) return;
    _model = model;
    
    if (model.image) {
        
        self.imageView.frame = [self getFrameOfImageViewWithImage:model.image];
        self.imageView.image = model.image;
        
    } else if (model.animatedImage) {
        
        self.imageView.frame = [self getFrameOfImageViewWithImage:model.animatedImage];
        self.imageView.animatedImage = model.animatedImage;
        
    } else if (model.url) {
        
        //优先显示缩略图
        [SDImageCache sharedImageCache];
        
        //下载逻辑
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.url options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
            if (self.model != model) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.progressBar.superview) {
                    [self.contentView addSubview:self.progressBar];
                }
                self.progressBar.progress = receivedSize*1.0/expectedSize;
            });
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            
            if (error) {
                self.isLoadFailed = YES;
                if (self.model == model) {
                    [self.progressBar showLoadFailedGraphics];
                }
                return;
            }
            self.isLoadFailed = NO;
            
            if (YBImageBrowser_isGif(data)) {
                model.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
            } else {
                model.image = image;
            }
            
            if (self.model == model) {
                if (self.progressBar.superview) {
                    [self.progressBar removeFromSuperview];
                }
                [self loadImageWithModel:model];
            }
            
        }];
    }
}

#pragma mark private
- (CGRect)getFrameOfImageViewWithImage:(id)image {
    
    CGSize imageSize = [FLAnimatedImage sizeForImage:image];
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
- (FLAnimatedImageView *)imageView {
    if (!_imageView) {
        _imageView = [FLAnimatedImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
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
- (YBImageBrowserProgressBar *)progressBar {
    if (!_progressBar) {
        _progressBar = [[YBImageBrowserProgressBar alloc] initWithFrame:self.bounds];
    }
    return _progressBar;
}

@end
