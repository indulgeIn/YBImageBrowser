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
#import <objc/message.h>
#import "YBImageBrowserDownloader.h"
#import "YBImageBrowser.h"

@interface YBImageBrowserCell () <UIScrollViewDelegate> {
    //动画相关
    CGFloat startScaleWidthInAnimationView; //开始拖动时比例
    CGFloat startScaleheightInAnimationView;    //开始拖动时比例
    CGRect frameOfOriginalOfImageView;  //开始拖动时图片frame
    CGPoint startOffsetOfScrollView;    //开始拖动时scrollview的偏移
    CGFloat lastPointX; //上一次触摸点x值
    CGFloat lastPointY; //上一次触摸点y值
    CGFloat totalOffsetXOfAnimateImageView; //总共的拖动偏移x
    CGFloat totalOffsetYOfAnimateImageView; //总共的拖动偏移y
    BOOL animateImageViewIsStart;   //拖动动效是否第一次触发
    BOOL isCancelAnimate;   //正在取消拖动动效
    BOOL isZooming; //是否正在释放
}

@property (nonatomic, strong) FLAnimatedImageView *imageView;   //显示的图片
@property (nonatomic, strong) UIImageView *animateImageView;    //做动画的图片
@property (nonatomic, strong) UIImageView *localImageView;  //用于显示大图的局部图片
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) YBImageBrowserProgressBar *progressBar;

@end

@implementation YBImageBrowserCell

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

#pragma mark life cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        isCancelAnimate = NO;
        animateImageViewIsStart = NO;
        _autoCountMaximumZoomScale = YES;
        [self addGesture];
        [self addNotification];
        [self.contentView addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
        [self addSubview:self.localImageView];
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
    [self hideLocalImageView];
    [super prepareForReuse];
}

#pragma mark notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yBImageBrowser_notification_willToRespondsDeviceOrientation) name:YBImageBrowser_notification_willToRespondsDeviceOrientation object:nil];
}

- (void)yBImageBrowser_notification_willToRespondsDeviceOrientation {
    if (self.animateImageView.superview) {
        [self.animateImageView removeFromSuperview];
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
    if (_delegate && [_delegate respondsToSelector:@selector(applyForHiddenByYBImageBrowserCell:)]) {
        [_delegate applyForHiddenByYBImageBrowserCell:self];
    }
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

- (void)reDownloadImageUrl {
    if ([[self.model valueForKey:YBImageBrowserModel_KVCKey_isLoadFailed] boolValue] && ![[self.model valueForKey:YBImageBrowserModel_KVCKey_isLoading] boolValue]) {
        [self downLoadImageWithModel:self.model];
    }
}

#pragma mark private

- (void)showLocalImageViewWithImage:(UIImage *)image {
    if (self.localImageView.isHidden) {
        self.localImageView.hidden = NO;
    }
    self.localImageView.frame = self.bounds;
    self.localImageView.image = image;
}

- (void)hideLocalImageView {
    if (!self.localImageView.isHidden) {
        self.localImageView.hidden = YES;
    }
}

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

//加载图片主逻辑
- (void)loadImageWithModel:(YBImageBrowserModel *)model isPreview:(BOOL)isPreview {
    if (!model) return;
    
    if (model.image) {
        
        //展示图片
        //若是压缩过后的图片，用原图计算缩放比例
        if (model.needCutToShow) {
            [self countLayoutWithImage:[model valueForKey:YBImageBrowserModel_KVCKey_largeImage] completed:nil];
        } else {
            [self countLayoutWithImage:model.image completed:nil];
        }
        self.imageView.image = model.image;
        
    } else if (model.needCutToShow) {
        
        //若该缩略图需要压缩，放弃压缩逻辑以节约资源
        if (isPreview) return;
        //展示缩略图
        if (model.previewModel) {
            [self loadImageWithModel:model.previewModel isPreview:YES];
        }
        
        //压缩
        [self scaleImageWithModel:model];
        
    } else if (model.animatedImage) {
        
        //展示gif
        [self countLayoutWithImage:model.animatedImage completed:nil];
        self.imageView.animatedImage = model.animatedImage;
        
    } else if (model.url) {
        
        //判断是否存在缓存
        [YBImageBrowserDownloader memeryImageDataExistWithKey:model.url.absoluteString exist:^(BOOL exist) {
            YB_MAINTHREAD_ASYNC(^{
                if (exist) {
                    //缓存存在
                    [self queryCacheWithModel:model];
                } else {
                    //缓存不存在
                    //若该缩略图无缓存，放弃下载逻辑以节约资源
                    if (isPreview) return;
                    //展示缩略图
                    if (model.previewModel) {
                        [self loadImageWithModel:model.previewModel isPreview:YES];
                    }
                    //下载逻辑
                    [self downLoadImageWithModel:model];
                }
            })
        }];
        
    }
}

//查找缓存
- (void)queryCacheWithModel:(YBImageBrowserModel *)model {
    [YBImageBrowserDownloader queryCacheOperationForKey:model.url.absoluteString completed:^(UIImage * _Nullable image, NSData * _Nullable data) {
        YB_MAINTHREAD_ASYNC(^{
            if ([YBImageBrowserUtilities isGif:data]) {
                if (data) {
                    model.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                    if (self.model == model) {
                        [self loadImageWithModel:model isPreview:NO];
                    }
                }
            } else {
                if (image) {
                    model.image = image;
                    if (self.model == model) {
                        [self loadImageWithModel:model isPreview:NO];
                    }
                }
            }
        })
    }];
}

//压缩
- (void)scaleImageWithModel:(YBImageBrowserModel *)model {
    
    UIImage *largeImage = [model valueForKey:YBImageBrowserModel_KVCKey_largeImage];
    
    [self countLayoutWithImage:largeImage completed:^(CGRect imageFrame) {
        
        [self showProgressBar];
        [self.progressBar showWithText:self.isScaleImageText];
        
        YBImageBrowserModelScaleImageSuccessBlock successBlock = ^(YBImageBrowserModel *backModel) {
            if (self && self.model == backModel) {
                [self hideProgressBar];
                self.imageView.image = backModel.image;
            }
        };
        ((void(*)(id, SEL, CGRect, YBImageBrowserModelScaleImageSuccessBlock)) objc_msgSend)(model, sel_registerName(YBImageBrowserModel_SELName_scaleImage), imageFrame, successBlock);
    }];
}

//裁剪
- (void)cutImage {
    
    UIScrollView *scrollView = self.scrollView;
    
    CGFloat scale = ((UIImage *)[self.model valueForKey:YBImageBrowserModel_KVCKey_largeImage]).size.width / self.scrollView.contentSize.width;
    CGFloat x = scrollView.contentOffset.x * scale,
    y = scrollView.contentOffset.y * scale,
    width = scrollView.bounds.size.width * scale,
    height = scrollView.bounds.size.height * scale;
    
    if (width > YBImageBrowser.maxDisplaySize || height > YBImageBrowser.maxDisplaySize) {
        return;
    }
    
    YBImageBrowserModelCutImageSuccessBlock successBlock = ^(YBImageBrowserModel *backModel, UIImage *targetImage){
        if (self && self.model == backModel) {
            [self showLocalImageViewWithImage:targetImage];
        }
    };
    ((void(*)(id, SEL, CGRect, YBImageBrowserModelCutImageSuccessBlock)) objc_msgSend)(self.model, sel_registerName(YBImageBrowserModel_SELName_cutImage), CGRectMake(x, y, width, height), successBlock);
}

//下载
- (void)downLoadImageWithModel:(YBImageBrowserModel *)model {
    
    [self showProgressBar];
    
    YBImageBrowserModelDownloadProgressBlock progressBlock = ^(YBImageBrowserModel * _Nonnull backModel, NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        //下载中，进度显示
        if (self.model != backModel || expectedSize <= 0) return;
        CGFloat progress = receivedSize * 1.0 / expectedSize;
        if (progress < 0) return;
        YB_MAINTHREAD_ASYNC(^{
            [self showProgressBar];
            self.progressBar.progress = progress;
        })
    };
    
    YBImageBrowserModelDownloadSuccessBlock successBlock = ^(YBImageBrowserModel * _Nonnull backModel, UIImage * _Nullable image, NSData * _Nullable data, BOOL finished) {
        //下载成功，移除 ProgressBar 并且刷新图片
        if (self.model == backModel) {
            [self hideProgressBar];
            [self loadImageWithModel:backModel isPreview:NO];
        }
    };
    
    YBImageBrowserModelDownloadFailedBlock failedBlock = ^(YBImageBrowserModel * _Nonnull backModel, NSError * _Nullable error, BOOL finished) {
        //下载失败，更新 ProgressBar 为错误提示
        if (self.model == backModel) {
            [self showProgressBar];
            [self.progressBar showWithText:self.loadFailedText];
        }
    };
    
    ((void(*)(id, SEL, YBImageBrowserModelDownloadProgressBlock, YBImageBrowserModelDownloadSuccessBlock, YBImageBrowserModelDownloadFailedBlock)) objc_msgSend)(model, sel_registerName(YBImageBrowserModel_SELName_download), progressBlock, successBlock, failedBlock);
}

- (void)countLayoutWithImage:(id)image completed:(void(^)(CGRect imageFrame))completed {
    [YBImageBrowserCell countWithContainerSize:self.scrollView.bounds.size image:image screenOrientation:_so_screenOrientation verticalFillType:self.verticalScreenImageViewFillType horizontalFillType:self.horizontalScreenImageViewFillType completed:^(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale, CGFloat maximumZoomScale) {
        
        self.scrollView.contentSize = CGSizeMake(contentSize.width, contentSize.height);
        self.scrollView.minimumZoomScale = minimumZoomScale;
        if (self.autoCountMaximumZoomScale) {
            self.scrollView.maximumZoomScale = maximumZoomScale * 1.2;  //多给用户缩放 0.2 倍
        } else {
            self.scrollView.maximumZoomScale = self.model.maximumZoomScale;
        }
        self.imageView.frame = imageFrame;
        
        if (completed) completed(imageFrame);
    }];
}

//计算图片大小核心代码
+ (void)countWithContainerSize:(CGSize)containerSize image:(id)image screenOrientation:(YBImageBrowserScreenOrientation)screenOrientation verticalFillType:(YBImageBrowserImageViewFillType)verticalFillType horizontalFillType:(YBImageBrowserImageViewFillType)horizontalFillType completed:(void(^)(CGRect _imageFrame, CGSize _contentSize, CGFloat _minimumZoomScale, CGFloat _maximumZoomScale))completed {
    
    CGSize imageSize = [FLAnimatedImage sizeForImage:image];
    CGFloat containerWidth = containerSize.width;
    CGFloat containerHeight = containerSize.height;
    CGFloat containerScale = containerWidth / containerHeight;
    
    CGFloat width = 0, height = 0, x = 0, y = 0, minimumZoomScale = 1, maximumZoomScale = 1;
    CGSize contentSize = CGSizeZero;
    
    //计算最大缩放比例
    CGFloat widthScale = imageSize.width / containerWidth,
    heightScale = imageSize.height / containerHeight,
    maxScale = widthScale > heightScale ? widthScale : heightScale;
    maximumZoomScale = maxScale > 1 ? maxScale : 1;
    
    //其他计算
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
    
    if (completed) completed(CGRectMake(x, y, width, height), contentSize, minimumZoomScale, maximumZoomScale);
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self dragAnimation_respondsToScrollViewPanGesture];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cutImage) object:nil];
    [self performSelector:@selector(cutImage) withObject:nil afterDelay:0.25];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    isZooming = YES;
    [self hideLocalImageView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self hideLocalImageView];
    [self dragAnimation_recordInfoWithScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    isZooming = NO;
    [self dragAnimation_removeAnimationImageViewWithScrollView:scrollView container:self];
}

#pragma mark drag animation

- (void)dragAnimation_recordInfoWithScrollView:(UIScrollView *)scrollView {
    if (self.cancelDragImageViewAnimation) return;
    
    CGPoint point = [scrollView.panGestureRecognizer locationInView:self];
    startOffsetOfScrollView = scrollView.contentOffset;
    frameOfOriginalOfImageView = [self.imageView convertRect:self.imageView.bounds toView:YB_NORMALWINDOW];
    startScaleWidthInAnimationView = (point.x - frameOfOriginalOfImageView.origin.x) / frameOfOriginalOfImageView.size.width;
    startScaleheightInAnimationView = (point.y - frameOfOriginalOfImageView.origin.y) / frameOfOriginalOfImageView.size.height;
}

- (void)dragAnimation_respondsToScrollViewPanGesture {
    if (self.cancelDragImageViewAnimation || isZooming) return;
    
    UIScrollView *scrollView = self.scrollView;
    UIPanGestureRecognizer *pan = scrollView.panGestureRecognizer;
    if (pan.numberOfTouches != 1) return;
    
    CGPoint point = [pan locationInView:self];
    BOOL shouldAddAnimationView = point.y > lastPointY && scrollView.contentOffset.y < -10 && !self.animateImageView.superview;
    if (shouldAddAnimationView) {
        [self dragAnimation_addAnimationImageViewWithPoint:point];
    }
    
    if (pan.state == UIGestureRecognizerStateChanged) {
        [self dragAnimation_performAnimationForAnimationImageViewWithPoint:point container:self];
    }
    
    lastPointY = point.y;
    lastPointX = point.x;
}

- (void)dragAnimation_addAnimationImageViewWithPoint:(CGPoint)point {
    if (self.imageView.frame.size.width <= 0 || self.imageView.frame.size.height <= 0) return;
    
    if (!YBImageBrowser.isControllerPreferredForStatusBar) [[UIApplication sharedApplication] setStatusBarHidden:YBImageBrowser.statusBarIsHideBefore];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notification_hideBrowerView object:nil];
    
    animateImageViewIsStart = YES;
    totalOffsetYOfAnimateImageView = 0;
    totalOffsetXOfAnimateImageView = 0;
    self.animateImageView.image = self.imageView.image;
    self.animateImageView.frame = frameOfOriginalOfImageView;
    [YB_NORMALWINDOW addSubview:self.animateImageView];
}

- (void)dragAnimation_removeAnimationImageViewWithScrollView:(UIScrollView *)scrollView container:(UIView *)container {
    if (!self.animateImageView.superview) return;
    
    CGFloat maxHeight = container.bounds.size.height;
    if (maxHeight <= 0) return;
    if (scrollView.zoomScale <= 1) {
        scrollView.contentOffset = CGPointZero;
    }
    
    if (totalOffsetYOfAnimateImageView > maxHeight * _outScaleOfDragImageViewAnimation) {
        
        //移除图片浏览器
        [_delegate applyForHiddenByYBImageBrowserCell:self];
        
    } else {
        
        //复位
        if (isCancelAnimate) return;
        isCancelAnimate = YES;
        
        CGFloat duration = 0.25;
        [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notification_willShowBrowerViewWithTimeInterval object:nil userInfo:@{YBImageBrowser_notificationKey_willShowBrowerViewWithTimeInterval:@(duration)}];
        
        [UIView animateWithDuration:duration animations:^{
            self.animateImageView.frame = frameOfOriginalOfImageView;
        } completion:^(BOOL finished) {
            if (!YBImageBrowser.isControllerPreferredForStatusBar) [[UIApplication sharedApplication] setStatusBarHidden:!YBImageBrowser.showStatusBar];
            self.scrollView.contentOffset = self->startOffsetOfScrollView;
            [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notification_showBrowerView object:nil];
            [self.animateImageView removeFromSuperview];
            self->isCancelAnimate = NO;
        }];
    }
}

- (void)dragAnimation_performAnimationForAnimationImageViewWithPoint:(CGPoint)point container:(UIView *)container {
    if (!self.animateImageView.superview) return;
    
    CGFloat maxHeight = container.bounds.size.height;
    if (maxHeight <= 0) return;
    //偏移
    CGFloat offsetX = point.x - lastPointX,
    offsetY = point.y - lastPointY;
    if (animateImageViewIsStart) {
        offsetX = offsetY = 0;
        animateImageViewIsStart = NO;
    }
    totalOffsetXOfAnimateImageView += offsetX;
    totalOffsetYOfAnimateImageView += offsetY;
    //缩放比例
    CGFloat scale = (1 - totalOffsetYOfAnimateImageView / maxHeight);
    if (scale > 1) scale = 1;
    if (scale < 0) scale = 0;
    //执行变换
    CGFloat width = frameOfOriginalOfImageView.size.width * scale, height = frameOfOriginalOfImageView.size.height * scale;
    self.animateImageView.frame = CGRectMake(point.x - width * startScaleWidthInAnimationView, point.y - height * startScaleheightInAnimationView, width, height);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YBImageBrowser_notification_changeAlpha object:nil userInfo:@{YBImageBrowser_notificationKey_changeAlpha:@(scale)}];
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

- (void)setCancelDragImageViewAnimation:(BOOL)cancelDragImageViewAnimation {
    _cancelDragImageViewAnimation = cancelDragImageViewAnimation;
    self.scrollView.alwaysBounceVertical = !cancelDragImageViewAnimation;
    self.scrollView.alwaysBounceHorizontal = !cancelDragImageViewAnimation;
}

#pragma mark getter

- (FLAnimatedImageView *)imageView {
    if (!_imageView) {
        _imageView = [FLAnimatedImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (UIImageView *)localImageView {
    if (!_localImageView) {
        _localImageView = [UIImageView new];
        _localImageView.contentMode = UIViewContentModeScaleAspectFill;
        _localImageView.hidden = YES;
    }
    return _localImageView;
}

- (UIImageView *)animateImageView {
    if (!_animateImageView) {
        _animateImageView = [UIImageView new];
        _animateImageView.contentMode = UIViewContentModeScaleAspectFill;
        _animateImageView.layer.masksToBounds = YES;
    }
    return _animateImageView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        _scrollView.maximumZoomScale = 1;
        _scrollView.minimumZoomScale = 1;
        _scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width, _scrollView.bounds.size.height);
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.alwaysBounceVertical = YES;
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
