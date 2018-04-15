//
//  YBImageBrowserCell.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserCell.h"
#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserProgressBar.h"

@interface YBImageBrowserCell () <UIScrollViewDelegate>

@property (nonatomic, strong) FLAnimatedImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) YBImageBrowserProgressBar *progressBar;

@end

@implementation YBImageBrowserCell

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

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
    UITapGestureRecognizer *tapSingle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapSingle:)];
    tapSingle.numberOfTapsRequired = 1;
    
    UITapGestureRecognizer *tapDouble = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapDouble:)];
    tapDouble.numberOfTapsRequired = 2;
    
    [tapSingle requireGestureRecognizerToFail:tapDouble];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToLongPress:)];
    
    [self.scrollView addGestureRecognizer:tapSingle];
    [self.scrollView addGestureRecognizer:tapDouble];
    [self.scrollView addGestureRecognizer:longPress];
}

- (void)respondsToTapSingle:(UITapGestureRecognizer *)tap {
    [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notificationName_hideSelf object:nil];
}

- (void)respondsToTapDouble:(UITapGestureRecognizer *)tap {
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

- (void)respondsToLongPress:(UILongPressGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateBegan) {
        if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowserCell:longPressBegin:)]) {
            [_delegate yBImageBrowserCell:self longPressBegin:tap];
        }
    }
}

#pragma mark public

- (void)reLoad {
    if (![[self.model valueForKey:YBImageBrowser_KVCKey_isLoading] boolValue]) {
        [self loadImageWithModel:self.model isPreview:NO];
    }
}

#pragma mark private

- (void)showProgressBar {
    if (!self.progressBar.superview) {
        [self.contentView addSubview:self.progressBar];
    }
}

- (void)hideProgressBar {
    if (self.progressBar.superview) {
        [self.progressBar removeFromSuperview];
    }
}

- (void)loadImageWithModel:(YBImageBrowserModel *)model isPreview:(BOOL)isPreview {
    if (!model) return;
    
    if (model.image) {
        
        //展示图片
        [self countLayoutWithImage:model.image];
        self.imageView.image = model.image;
        
    } else if (model.animatedImage) {
        
        //展示gif
        [self countLayoutWithImage:model.animatedImage];
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
            [self showProgressBar];
            self.progressBar.progress = progress;
        });
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        [model setValue:@(NO) forKey:YBImageBrowser_KVCKey_isLoading];
        
        //下载失败，展示错误 HUD
        if (error) {
            [model setValue:@(YES) forKey:YBImageBrowser_KVCKey_isLoadFailed];
            if (self.model == model) {
                [self showProgressBar];
                [self.progressBar showLoadFailedGraphicsWithText:self.loadFailedText];
            }
            return;
        }
        [model setValue:@(NO) forKey:YBImageBrowser_KVCKey_isLoadFailed];
        
        //将下载完成的图片存入内存/磁盘
        if ([YBImageBrowserUtilities isGif:data]) {
            model.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
        } else {
            model.image = image;
            [[SDImageCache sharedImageCache] storeImage:image forKey:model.imageUrl completion:nil];
        }
        
        //移除 HUD 并且刷新图片
        if (self.model == model) {
            [self hideProgressBar];
            [self loadImageWithModel:model isPreview:NO];
        }
        
    }];
    
    //将 token 给集合视图统一处理
    if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowserCell:didAddDownLoaderTaskWithToken:)]) {
        [_delegate yBImageBrowserCell:self didAddDownLoaderTaskWithToken:token];
    }
}

+ (void)countWithContainerSize:(CGSize)containerSize image:(id)image screenOrientation:(YBImageBrowserScreenOrientation)screenOrientation verticalFillType:(YBImageBrowserImageViewFillType)verticalFillType horizontalFillType:(YBImageBrowserImageViewFillType)horizontalFillType completed:(void(^)(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale))completed {
    
    CGSize imageSize = [FLAnimatedImage sizeForImage:image];
    CGFloat containerWidth = containerSize.width;
    CGFloat containerHeight = containerSize.height;
    CGFloat containerScale = containerWidth / containerHeight;
    
    CGFloat width = 0, height = 0, x = 0, y = 0, minimumZoomScale = 1;
    CGSize contentSize = CGSizeZero;
    
    YBImageBrowserImageViewFillType currentFillType = screenOrientation == YBImageBrowserScreenOrientationVertical ? verticalFillType : horizontalFillType;
    
    switch (currentFillType) {
        case YBImageBrowserImageViewFillTypeFullWidth: {
            
            width = containerWidth;
            height = containerWidth * (imageSize.height / imageSize.width);
            if (imageSize.width / imageSize.height >= containerScale) {
                x = 0;
                y = (containerHeight - height) / 2.0;
                contentSize = CGSizeMake(containerWidth, containerHeight);
                minimumZoomScale = 1;
            } else {
                x = 0;
                y = 0;
                contentSize = CGSizeMake(containerWidth, height);
                minimumZoomScale = containerHeight / height;
            }
        }
            break;
        case YBImageBrowserImageViewFillTypeCompletely: {
            
            if (imageSize.width / imageSize.height >= containerScale) {
                width = containerWidth;
                height = containerWidth * (imageSize.height / imageSize.width);
                x = 0;
                y = (containerHeight - height) / 2.0;
            } else {
                height = containerHeight;
                width = containerHeight * (imageSize.width / imageSize.height);
                x = (containerWidth - width) / 2.0;
                y = 0;
            }
            contentSize = CGSizeMake(containerWidth, containerHeight);
            minimumZoomScale = 1;
        }
            break;
        default:
            break;
    }
    
    if (completed) completed(CGRectMake(x, y, width, height), contentSize, minimumZoomScale);
}

- (void)countLayoutWithImage:(id)image {
    [self.class countWithContainerSize:self.scrollView.bounds.size image:image screenOrientation:_so_screenOrientation verticalFillType:self.verticalScreenImageViewFillType horizontalFillType:self.horizontalScreenImageViewFillType completed:^(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale) {
        self.scrollView.contentSize = contentSize;
        self.scrollView.minimumZoomScale = minimumZoomScale;
        self.imageView.frame = imageFrame;
    }];
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

#pragma mark YBImageBrowserScreenOrientationProtocol

- (void)so_setFrameInfoWithSuperViewScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation superViewSize:(CGSize)size {}

- (void)so_updateFrameWithScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation {
    if (screenOrientation == _so_screenOrientation) return;
    
    _so_isUpdateUICompletely = NO;
    
    _so_screenOrientation = screenOrientation;
    
    UIScrollView *scrollView = self.scrollView;
    [scrollView setZoomScale:1 animated:YES];
    scrollView.frame = self.bounds;
    scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width, scrollView.bounds.size.height);
    self.progressBar.frame = self.bounds;
    
    _so_isUpdateUICompletely = YES;
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
