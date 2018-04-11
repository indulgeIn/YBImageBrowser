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
    UIScrollView *scrollView = self.scrollView;
    CGPoint point = [tap locationInView:self.imageView];
    if (scrollView.zoomScale == scrollView.maximumZoomScale) {
        [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
    } else {
        //让指定区域竟可能大的显示在可视区域
        [scrollView zoomToRect:CGRectMake(point.x + scrollView.contentOffset.x, point.y + scrollView.contentOffset.y, 1, 1) animated:YES];
    }
}

#pragma mark public
- (void)reLoad {
    [self loadImageWithModel:self.model isPreview:NO];
}

#pragma mark private
- (void)loadImageWithModel:(YBImageBrowserModel *)model isPreview:(BOOL)isPreview {
    if (!model) return;
    
    if (model.image) {
        
        //展示图片
        self.imageView.frame = [self getFrameOfImageViewWithImage:model.image];
        self.imageView.image = model.image;
        
    } else if (model.animatedImage) {
        
        //展示gif
        self.imageView.frame = [self getFrameOfImageViewWithImage:model.animatedImage];
        self.imageView.animatedImage = model.animatedImage;
        
    } else if (model.url) {
        
        //读取缓存
        UIImage *cacheImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:model.imageUrl];
        if (cacheImage) {
            model.image = cacheImage;
            [self loadImageWithModel:model isPreview:NO];
            return;
        }
        
        //若该缩略图无缓存，放弃下载逻辑以节约资源
        if (isPreview) return;
        
        //展示缩略图
        if (model.previewModel) {
            [self loadImageWithModel:model.previewModel isPreview:YES];
        }
        
        //下载逻辑
        SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.url options:SDWebImageDownloaderLowPriority|SDWebImageDownloaderScaleDownLargeImages progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
            if (self.model != model) return;
            CGFloat progress = receivedSize*1.0/expectedSize;
            if (progress < 0) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.progressBar.superview) {
                    [self.contentView addSubview:self.progressBar];
                }
                self.progressBar.progress = progress;
            });
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            
            //下载失败，展示错误 HUD
            if (error) {
                self.isLoadFailed = YES;
                if (self.model == model) {
                    [self.progressBar showLoadFailedGraphics];
                }
                return;
            }
            self.isLoadFailed = NO;
            
            //将下载完成的图片存入内存/磁盘
            if (YBImageBrowser_isGif(data)) {
                model.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
            } else {
                model.image = image;
                [[SDImageCache sharedImageCache] storeImage:image forKey:model.imageUrl completion:nil];
            }
            
            //移除 HUD 并且刷新图片
            if (self.model == model) {
                if (self.progressBar.superview) {
                    [self.progressBar removeFromSuperview];
                }
                [self loadImageWithModel:model isPreview:NO];
            }
            
        }];
        
        //将 token 给集合视图
        if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowserCell:didAddDownLoaderTaskWithToken:)]) {
            [_delegate yBImageBrowserCell:self didAddDownLoaderTaskWithToken:token];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notice_hide object:nil];
    }
}

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

#pragma mark setter
- (void)setModel:(YBImageBrowserModel *)model {
    if (!model) return;
    _model = model;
    [self loadImageWithModel:model isPreview:NO];
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
