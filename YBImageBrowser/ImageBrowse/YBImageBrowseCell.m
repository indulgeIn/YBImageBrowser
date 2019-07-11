//
//  YBImageBrowseCell.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowseCell.h"
#import "YBImageBrowseCellData.h"
#import "YBIBWebImageManager.h"
#import <objc/runtime.h>
#import "YBIBPhotoAlbumManager.h"
#import "YBImageBrowserTipView.h"
#import "YBImageBrowserProgressView.h"
#import "YBImageBrowserCellProtocol.h"
#import "YBImageBrowseCellData+Internal.h"
#import "YBIBUtilities.h"
#import "YBIBCopywriter.h"

@interface YBImageBrowseCell () <YBImageBrowserCellProtocol, UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    YBImageBrowserLayoutDirection _layoutDirection;
    CGSize _containerSize;
    BOOL _zooming;
    BOOL _dragging;
    BOOL _bodyInCenter;
    BOOL _outTransitioning;
    
    CGPoint _gestureInteractionStartPoint;
    BOOL _gestureInteracting;
    YBIBGestureInteractionProfile *_giProfile;
    
    UIInterfaceOrientation _statusBarOrientationBefore;
}
@property (nonatomic, strong) UIScrollView *mainContentView;
@property (nonatomic, strong) YYAnimatedImageView *mainImageView;
@property (nonatomic, strong) UIImageView *tailoringImageView;
@property (nonatomic, strong) YBImageBrowserProgressView *progressView;
@property (nonatomic, strong) YBImageBrowseCellData *cellData;
@end

@implementation YBImageBrowseCell

@synthesize yb_browserDismissBlock = _yb_browserDismissBlock;
@synthesize yb_browserScrollEnabledBlock = _yb_browserScrollEnabledBlock;
@synthesize yb_browserChangeAlphaBlock = _yb_browserChangeAlphaBlock;
@synthesize yb_browserToolBarHiddenBlock = _yb_browserToolBarHiddenBlock;

#pragma mark - life cycle

- (void)dealloc {
    [self removeObserverForDataState];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initVars];
        
        [self.contentView addSubview:self.mainContentView];
        [self.mainContentView addSubview:self.mainImageView];
        [self addGesture];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    _outTransitioning = NO;
}

- (void)prepareForReuse {
    [self initVars];
    [self removeObserverForDataState];
    
    self.mainContentView.zoomScale = 1;
    self.mainImageView.image = nil;
    [self.contentView yb_hideProgressView];
    [self hideTailoringImageView];
    
    [super prepareForReuse];
}

- (void)initVars {
    _zooming = NO;
    _dragging = NO;
    _bodyInCenter = YES;
    _outTransitioning = NO;
    _layoutDirection = YBImageBrowserLayoutDirectionUnknown;
    _containerSize = CGSizeMake(1, 1);
    
    _gestureInteractionStartPoint = CGPointZero;
    _gestureInteracting = NO;
}

#pragma mark - <YBImageBrowserCellProtocol>

- (void)yb_initializeBrowserCellWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    _containerSize = containerSize;
    _layoutDirection = layoutDirection;
    
    if (![data isKindOfClass:YBImageBrowseCellData.class]) return;
    self.cellData = data;
    
    [self addObserverForDataState];
    
    [self updateLayoutWithContainerSize:containerSize];
}

- (void)yb_browserLayoutDirectionChanged:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    _containerSize = containerSize;
    _layoutDirection = layoutDirection;
    
    [self hideTailoringImageView];
    
    if (_gestureInteracting) {
        [self restoreGestureInteractionWithDuration:0];
    }
    
    [self updateLayoutWithContainerSize:containerSize];
    [self updateMainContentViewLayoutWithContainerSize:containerSize fillType:[self.cellData getFillTypeWithLayoutDirection:layoutDirection]];
}

- (void)yb_browserBodyIsInTheCenter:(BOOL)isIn {
    _bodyInCenter = isIn;
}

- (UIView *)yb_browserCurrentForegroundView {
    return self.mainImageView;
}

- (void)yb_browserSetGestureInteractionProfile:(YBIBGestureInteractionProfile *)giProfile {
    _giProfile = giProfile;
}

- (void)yb_browserStatusBarOrientationBefore:(UIInterfaceOrientation)orientation {
    _statusBarOrientationBefore = orientation;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.cellData.zoomScale = scrollView.zoomScale;
    
    CGRect imageViewFrame = self.mainImageView.frame;
    CGFloat width = imageViewFrame.size.width,
    height = imageViewFrame.size.height,
    sHeight = scrollView.bounds.size.height,
    sWidth = scrollView.bounds.size.width;
    if (height > sHeight) {
        imageViewFrame.origin.y = 0;
    } else {
        imageViewFrame.origin.y = (sHeight - height) / 2.0;
    }
    if (width > sWidth) {
        imageViewFrame.origin.x = 0;
    } else {
        imageViewFrame.origin.x = (sWidth - width) / 2.0;
    }
    self.mainImageView.frame = imageViewFrame;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.mainImageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self cutImage];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    _zooming = YES;
    [self hideTailoringImageView];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    _zooming = NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _dragging = YES;
    [self hideTailoringImageView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _dragging = NO;
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - gesture

- (void)addGesture {
    UITapGestureRecognizer *tapSingle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapSingle:)];
    tapSingle.numberOfTapsRequired = 1;
    UITapGestureRecognizer *tapDouble = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapDouble:)];
    tapDouble.numberOfTapsRequired = 2;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToPan:)];
    pan.maximumNumberOfTouches = 1;
    pan.delegate = self;
    
    [tapSingle requireGestureRecognizerToFail:tapDouble];
    [tapSingle requireGestureRecognizerToFail:pan];
    [tapDouble requireGestureRecognizerToFail:pan];
    
    [self.mainContentView addGestureRecognizer:tapSingle];
    [self.mainContentView addGestureRecognizer:tapDouble];
    [self.mainContentView addGestureRecognizer:pan];
}

- (void)respondsToTapSingle:(UITapGestureRecognizer *)tap {
    [self browserDismiss];
}

- (void)respondsToTapDouble:(UITapGestureRecognizer *)tap {
    [self hideTailoringImageView];
    
    UIScrollView *scrollView = self.mainContentView;
    UIView *zoomView = [self viewForZoomingInScrollView:scrollView];
    CGPoint point = [tap locationInView:zoomView];
    if (!CGRectContainsPoint(zoomView.bounds, point)) return;
    if (scrollView.zoomScale == scrollView.maximumZoomScale) {
        [scrollView setZoomScale:1 animated:YES];
    } else {
        [scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];
    }
}

- (BOOL)currentIsLargeImageBrowsing {
    CGFloat sHeight = self.mainContentView.bounds.size.height,
    sWidth = self.mainContentView.bounds.size.width,
    sContentHeight = self.mainContentView.contentSize.height,
    sContentWidth = self.mainContentView.contentSize.width;
    return sContentHeight > sHeight || sContentWidth > sWidth;
}

- (void)respondsToPan:(UIPanGestureRecognizer *)pan {
    if ((CGRectIsEmpty(self.mainImageView.frame) || !self.mainImageView.image) || _giProfile.disable) return;
    
    CGPoint point = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        
        _gestureInteractionStartPoint = point;
        
    } else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateRecognized || pan.state == UIGestureRecognizerStateFailed) {
        
        // END
        if (_gestureInteracting) {
            CGPoint velocity = [pan velocityInView:self.mainContentView];
            
            BOOL velocityArrive = ABS(velocity.y) > _giProfile.dismissVelocityY;
            BOOL distanceArrive = ABS(point.y - _gestureInteractionStartPoint.y) > _containerSize.height * _giProfile.dismissScale;
            
            BOOL shouldDismiss = distanceArrive || velocityArrive;
            if (shouldDismiss) {
                [self browserDismiss];
            } else {
                [self restoreGestureInteractionWithDuration:_giProfile.restoreDuration];
            }
        }
        
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        
        CGPoint velocity = [pan velocityInView:self.mainContentView];
        CGFloat triggerDistance = _giProfile.triggerDistance;
        
        BOOL startPointValid = !CGPointEqualToPoint(_gestureInteractionStartPoint, CGPointZero);
        BOOL distanceArrive = ABS(point.x - _gestureInteractionStartPoint.x) < triggerDistance && ABS(velocity.x) < 500;
        BOOL upArrive = point.y - _gestureInteractionStartPoint.y > triggerDistance && self.mainContentView.contentOffset.y <= 1;
        BOOL downArrive = point.y - _gestureInteractionStartPoint.y < -triggerDistance && self.mainContentView.contentOffset.y + self.mainContentView.bounds.size.height >= MAX(self.mainContentView.contentSize.height, self.mainContentView.bounds.size.height) - 1;
        
        BOOL shouldStart = startPointValid && !_gestureInteracting && (upArrive || downArrive) && distanceArrive && _bodyInCenter && !_zooming;
        // START
        if (shouldStart) {
            if ([UIApplication sharedApplication].statusBarOrientation != _statusBarOrientationBefore) {
                [self browserDismiss];
            } else {
                [self hideTailoringImageView];
                
                _gestureInteractionStartPoint = point;
                
                CGRect startFrame = self.mainContentView.frame;
                CGFloat anchorX = point.x / startFrame.size.width,
                anchorY = point.y / startFrame.size.height;
                self.mainContentView.layer.anchorPoint = CGPointMake(anchorX, anchorY);
                self.mainContentView.userInteractionEnabled = NO;
                self.mainContentView.scrollEnabled = NO;
                
                self.yb_browserScrollEnabledBlock(NO);
                self.yb_browserToolBarHiddenBlock(YES);
                
                _gestureInteracting = YES;
            }
        }
        
        // CHNAGE
        if (_gestureInteracting) {
            self.mainContentView.center = point;
            CGFloat scale = 1 - ABS(point.y - _gestureInteractionStartPoint.y) / (_containerSize.height * 1.2);
            if (scale > 1) scale = 1;
            if (scale < 0.35) scale = 0.35;
            self.mainContentView.transform = CGAffineTransformMakeScale(scale, scale);
            
            CGFloat alpha = 1 - ABS(point.y - _gestureInteractionStartPoint.y) / (_containerSize.height * 1.1);
            if (alpha > 1) alpha = 1;
            if (alpha < 0) alpha = 0;
            self.yb_browserChangeAlphaBlock(alpha, 0);
        }
    }
}

- (void)restoreGestureInteractionWithDuration:(NSTimeInterval)duration {
    self.yb_browserChangeAlphaBlock(1, duration);
    
    void (^animations)(void) = ^{
        CGPoint anchorPoint = self.mainContentView.layer.anchorPoint;
        self.mainContentView.center = CGPointMake(self->_containerSize.width * anchorPoint.x, self->_containerSize.height * anchorPoint.y);
        self.mainContentView.transform = CGAffineTransformIdentity;
    };
    void (^completion)(BOOL finished) = ^(BOOL finished){
        self.yb_browserScrollEnabledBlock(YES);
        self.yb_browserToolBarHiddenBlock(NO);
        
        self.mainContentView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.mainContentView.center = CGPointMake(self->_containerSize.width * 0.5, self->_containerSize.height * 0.5);
        self.mainContentView.userInteractionEnabled = YES;
        self.mainContentView.scrollEnabled = YES;
        
        self->_gestureInteractionStartPoint = CGPointZero;
        self->_gestureInteracting = NO;
        
        [self cutImage];
    };
    if (duration <= 0) {
        animations();
        completion(NO);
    } else {
        [UIView animateWithDuration:duration animations:animations completion:completion];
    }
}

#pragma mark - observe

- (void)addObserverForDataState {
    [self.cellData addObserver:self forKeyPath:@"dataState" options:NSKeyValueObservingOptionNew context:nil];
    [self.cellData loadData];
}

- (void)removeObserverForDataState {
    [self.cellData removeObserver:self forKeyPath:@"dataState"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (!_outTransitioning && object == self.cellData && [keyPath isEqualToString:@"dataState"]) {
        [self cellDataStateChanged];
    } 
}

#pragma mark - private

- (void)browserDismiss {
    _outTransitioning = YES;
    [self hideTailoringImageView];
    [self.contentView yb_hideProgressView];
    [self yb_hideProgressView];
    self.yb_browserDismissBlock();
    _gestureInteracting = NO;
}

- (void)cellDataStateChanged {
    YBImageBrowseCellData *data = self.cellData;
    YBImageBrowseCellDataState dataState = data.dataState;
    switch (dataState) {
        case YBImageBrowseCellDataStateInvalid: {
            [self.contentView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].imageIsInvalid click:nil];
        }
            break;
        case YBImageBrowseCellDataStateImageReady: {
            if (self.mainImageView.image != data.image) {
                self.mainImageView.image = data.image;
                [self updateMainContentViewLayoutWithContainerSize:_containerSize fillType:[data getFillTypeWithLayoutDirection:_layoutDirection]];
            }
        }
            break;
        case YBImageBrowseCellDataStateIsDecoding: {
            if (!self.mainImageView.image) {
                [self.contentView yb_showProgressViewLoading];
            }
        }
            break;
        case YBImageBrowseCellDataStateDecodeComplete: {
            [self.contentView yb_hideProgressView];
        }
            break;
        case YBImageBrowseCellDataStateCompressImageReady: {
            if (self.mainImageView.image != data.compressImage) {
                self.mainImageView.image = data.compressImage;
                [self updateMainContentViewLayoutWithContainerSize:_containerSize fillType:[data getFillTypeWithLayoutDirection:_layoutDirection]];
            }
        }
            break;
        case YBImageBrowseCellDataStateThumbImageReady: {
            // If the image has been display, discard the thumb image.
            if (!self.mainImageView.image) {
                self.mainImageView.image = data.thumbImage;
                [self updateMainContentViewLayoutWithContainerSize:_containerSize fillType:[data getFillTypeWithLayoutDirection:_layoutDirection]];
            }
        }
            break;
        case YBImageBrowseCellDataStateIsCompressingImage: {
            [self.contentView yb_showProgressViewLoading];
        }
            break;
        case YBImageBrowseCellDataStateCompressImageComplete: {
            [self.contentView yb_hideProgressView];
        }
            break;
        case YBImageBrowseCellDataStateIsLoadingPHAsset: {
            [self.contentView yb_showProgressViewLoading];
        }
            break;
        case YBImageBrowseCellDataStateLoadPHAssetSuccess: {
            [self.contentView yb_hideProgressView];
        }
            break;
        case YBImageBrowseCellDataStateLoadPHAssetFailed: {
            [self.contentView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].imageIsInvalid click:nil];
        }
            break;
        case YBImageBrowseCellDataStateIsDownloading: {
            [self.contentView yb_showProgressViewWithValue:data.downloadProgress];
        }
            break;
        case YBImageBrowseCellDataStateDownloadProcess: {
            [self.contentView yb_showProgressViewWithValue:data.downloadProgress];
        }
            break;
        case YBImageBrowseCellDataStateDownloadSuccess: {
            [self.contentView yb_hideProgressView];
        }
            break;
        case YBImageBrowseCellDataStateDownloadFailed: {
            [self.contentView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].downloadFailed click:nil];
        }
            break;
        default:
            break;
    }
}

- (void)updateLayoutWithContainerSize:(CGSize)containerSize {
    self.mainContentView.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);
}

- (void)updateMainContentViewLayoutWithContainerSize:(CGSize)containerSize fillType:(YBImageBrowseFillType)fillType {
    CGSize imageSize;
    if (self.cellData.image) {
        imageSize = self.cellData.image.size;
    } else if (self.cellData.thumbImage) {
        imageSize = self.cellData.thumbImage.size;
    } else {
        return;
    }
    
    CGRect imageViewFrame = [self.cellData.class getImageViewFrameWithContainerSize:containerSize imageSize:imageSize fillType:fillType];
    
    self.mainContentView.zoomScale = 1;
    self.mainContentView.contentSize = [self.cellData.class getContentSizeWithContainerSize:containerSize imageViewFrame:imageViewFrame];
    self.mainContentView.minimumZoomScale = 1;
    self.mainContentView.maximumZoomScale = 1;
    if (self.cellData.image) {
        self.mainContentView.maximumZoomScale = self.cellData.maxZoomScale >= 1 ? self.cellData.maxZoomScale : [self.cellData.class getMaximumZoomScaleWithContainerSize:containerSize imageSize:imageSize fillType:fillType];
    }
    
    self.mainImageView.frame = imageViewFrame;
}

- (void)showTailoringImageView:(UIImage *)image {
    if (_gestureInteracting) return;
    if (!self.tailoringImageView.superview) {
        [self.contentView addSubview:self.tailoringImageView];
    }
    self.tailoringImageView.frame = CGRectMake(0, 0, _containerSize.width, _containerSize.height);
    self.tailoringImageView.hidden = NO;
    self.tailoringImageView.image = image;
}

- (void)hideTailoringImageView {
    // Don't use 'getter' method, because it's according to the need to load.
    if (_tailoringImageView) {
        self.tailoringImageView.hidden = YES;
    }
}

- (void)cutImage {
    if ([self.cellData needCompress] && !self.cellData.cutting && self.mainContentView.zoomScale > 1.15) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_cutImage) object:nil];
        [self performSelector:@selector(_cutImage) withObject:nil afterDelay:0.25];
    }
}

- (void)_cutImage {
    CGFloat scale = self.cellData.image.size.width / self.mainContentView.contentSize.width;
    CGFloat x = self.mainContentView.contentOffset.x * scale,
    y = self.mainContentView.contentOffset.y * scale,
    width = self.mainContentView.bounds.size.width * scale,
    height = self.mainContentView.bounds.size.height * scale;
    
    YBImageBrowseCellData *tmp = self.cellData;
    [self.cellData cuttingImageToRect:CGRectMake(x, y, width, height) complete:^(UIImage *image) {
        if (tmp == self.cellData && !self->_dragging) {
            [self showTailoringImageView:image];
        }
    }];
}

#pragma mark - getter

- (UIScrollView *)mainContentView {
    if (!_mainContentView) {
        _mainContentView = [UIScrollView new];
        _mainContentView.delegate = self;
        _mainContentView.showsHorizontalScrollIndicator = NO;
        _mainContentView.showsVerticalScrollIndicator = NO;
        _mainContentView.decelerationRate = UIScrollViewDecelerationRateFast;
        _mainContentView.maximumZoomScale = 1;
        _mainContentView.minimumZoomScale = 1;
        _mainContentView.alwaysBounceHorizontal = NO;
        _mainContentView.alwaysBounceVertical = NO;
        _mainContentView.layer.masksToBounds = NO;
        if (@available(iOS 11.0, *)) {
            _mainContentView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _mainContentView;
}

- (YYAnimatedImageView *)mainImageView {
    if (!_mainImageView) {
        _mainImageView = [YYAnimatedImageView new];
        _mainImageView.contentMode = UIViewContentModeScaleAspectFill;
        _mainImageView.layer.masksToBounds = YES;
    }
    return _mainImageView;
}

- (YBImageBrowserProgressView *)progressView {
    if (!_progressView) {
        _progressView = [YBImageBrowserProgressView new];
    }
    return _progressView;
}

- (UIImageView *)tailoringImageView {
    if (!_tailoringImageView) {
        _tailoringImageView = [UIImageView new];
        _tailoringImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _tailoringImageView;
}

@end
