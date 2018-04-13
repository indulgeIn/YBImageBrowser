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
    [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notificationName_hideSelf object:nil];
}

- (void)respondsToTapOfDouble:(UITapGestureRecognizer *)tap {
    UIScrollView *scrollView = self.scrollView;
    UIView *zoomView = [self viewForZoomingInScrollView:scrollView];
    CGPoint point = [tap locationInView:zoomView];
    if (!CGRectContainsPoint(zoomView.bounds, point)) {
        return;
    }
    if (scrollView.zoomScale == scrollView.maximumZoomScale) {
        [scrollView setZoomScale:1 animated:YES];
    } else {
        //让指定区域尽可能大的显示在可视区域
        [scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];
    }
}

#pragma mark public

- (void)reLoad {
    if (![[self.model valueForKey:YBImageBrowser_KVCKey_isLoading] boolValue]) {
        [self loadImageWithModel:self.model isPreview:NO];
    }
}

- (void)resetUserInterfaceLayout {
    UIScrollView *scrollView = self.scrollView;
    [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
    scrollView.frame = self.bounds;
    scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width, scrollView.bounds.size.height);
    self.progressBar.frame = self.bounds;
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
            [model setValue:cacheImage forKey:@"image"];
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
        [self downloadImageWithModel:model];
    }
}

- (void)downloadImageWithModel:(YBImageBrowserModel *)model {
    
    NSURL *url = model.url;
    
    [model setValue:@(YES) forKey:YBImageBrowser_KVCKey_isLoading];
    
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:SDWebImageDownloaderLowPriority|SDWebImageDownloaderScaleDownLargeImages progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        if (self.model != model || expectedSize <= 0) return;
        CGFloat progress = receivedSize * 1.0 / expectedSize;
        if (progress < 0) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.progressBar.superview) {
                [self.contentView addSubview:self.progressBar];
            }
            self.progressBar.progress = progress;
        });
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        [model setValue:@(NO) forKey:YBImageBrowser_KVCKey_isLoading];
        
        //下载失败，展示错误 HUD
        if (error) {
            [model setValue:@(YES) forKey:YBImageBrowser_KVCKey_isLoadFailed];
            if (self.model == model) {
                [self.progressBar showLoadFailedGraphics];
            }
            return;
        }
        [model setValue:@(NO) forKey:YBImageBrowser_KVCKey_isLoadFailed];
        
        //将下载完成的图片存入内存/磁盘
        if ([YBImageBrowserTool isGif:data]) {
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
    
    //将 token 给集合视图统一处理
    if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowserCell:didAddDownLoaderTaskWithToken:)]) {
        [_delegate yBImageBrowserCell:self didAddDownLoaderTaskWithToken:token];
    }
}

- (CGRect)getFrameOfImageViewWithImage:(id)image {
    
    CGSize imageSize = [FLAnimatedImage sizeForImage:image];
    CGFloat scrollViewWidth = self.scrollView.bounds.size.width;
    CGFloat scrollViewHeight = self.scrollView.bounds.size.height;
    CGFloat scrollViewScale = scrollViewWidth / scrollViewHeight;
    
    CGFloat width = 0, height = 0, x = 0, y = 0, minimumZoomScale = 1;
    CGSize contentSize = CGSizeZero;
    
    YBImageBrowserImageViewFillType currentFillType = scrollViewScale < 1 ? self.verticalScreenImageViewFillType : self.horizontalScreenImageViewFillType;
    
    switch (currentFillType) {
        case YBImageBrowserImageViewFillTypeFullWidth: {
            
            width = scrollViewWidth;
            height = scrollViewWidth * (imageSize.height / imageSize.width);
            if (imageSize.width / imageSize.height >= scrollViewScale) {
                x = 0;
                y = (scrollViewHeight - height) / 2.0;
                contentSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
                minimumZoomScale = 1;
            } else {
                x = 0;
                y = 0;
                contentSize = CGSizeMake(scrollViewWidth, height);
                minimumZoomScale = scrollViewHeight / height;
            }
        }
            break;
        case YBImageBrowserImageViewFillTypeCompletely: {
            
            if (imageSize.width / imageSize.height >= scrollViewScale) {
                width = scrollViewWidth;
                height = scrollViewWidth * (imageSize.height / imageSize.width);
                x = 0;
                y = (scrollViewHeight - height) / 2.0;
            } else {
                height = scrollViewHeight;
                width = scrollViewHeight * (imageSize.width / imageSize.height);
                x = (scrollViewWidth - width) / 2.0;
                y = 0;
            }
            contentSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
            minimumZoomScale = 1;
        }
            break;
        default:
            break;
    }
    
    self.scrollView.contentSize = contentSize;
    self.scrollView.minimumZoomScale = minimumZoomScale;
    
    return CGRectMake(x, y, width, height);
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {

    CGRect imageViewFrame = self.imageView.frame;
    CGFloat width = imageViewFrame.size.width, height = imageViewFrame.size.height;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    CGFloat scrollViewWidth = scrollView.bounds.size.width;
    
    if (height > scrollViewHeight) {
        imageViewFrame.origin.y = 0;
    } else {
        imageViewFrame.origin.y = (scrollViewHeight - height) / 2.0;
    }
    if (width > scrollViewWidth) {
        imageViewFrame.origin.x = 0;
    } else {
        imageViewFrame.origin.x = (scrollViewWidth - width) / 2.0;
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
    if ([[model valueForKey:YBImageBrowser_KVCKey_needUpdateUI] boolValue]) {
        [self resetUserInterfaceLayout];
        [model setValue:@(NO) forKey:YBImageBrowser_KVCKey_needUpdateUI];
    }
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
