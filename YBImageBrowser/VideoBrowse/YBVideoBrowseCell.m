//
//  YBVideoBrowseCell.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/28.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBVideoBrowseCell.h"
#import <AVFoundation/AVFoundation.h>
#import "YBVideoBrowseCellData.h"
#import "YBIBPhotoAlbumManager.h"
#import "YBIBUtilities.h"
#import "YBIBFileManager.h"
#import "YBVideoBrowseActionBar.h"
#import "YBVideoBrowseTopBar.h"
#import "YBImageBrowserTipView.h"
#import "YBImageBrowserProgressView.h"
#import "YBImageBrowserCellProtocol.h"
#import "YBVideoBrowseCellData+Internal.h"
#import "YBIBCopywriter.h"

@interface YBVideoBrowseCell () <YBVideoBrowseActionBarDelegate, YBVideoBrowseTopBarDelegate, YBImageBrowserCellProtocol, UIGestureRecognizerDelegate> {
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    AVPlayerItem *_playerItem;
    
    YBImageBrowserLayoutDirection _layoutDirection;
    CGSize _containerSize;
    BOOL _playing;
    BOOL _currentIndexIsSelf;
    BOOL _bodyInCenter;
    BOOL _active;
    BOOL _outTransitioning;
    
    CGPoint _gestureInteractionStartPoint;
    // Gestural interaction is in progress.
    BOOL _gestureInteracting;
    YBIBGestureInteractionProfile *_giProfile;
    
    UIInterfaceOrientation _statusBarOrientationBefore;
}
@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIImageView *firstFrameImageView;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) YBVideoBrowseActionBar *actionBar;
@property (nonatomic, strong) YBVideoBrowseTopBar *topBar;
@property (nonatomic, strong) YBVideoBrowseCellData *cellData;
@end

@implementation YBVideoBrowseCell

@synthesize yb_browserScrollEnabledBlock = _yb_browserScrollEnabledBlock;
@synthesize yb_browserDismissBlock = _yb_browserDismissBlock;
@synthesize yb_browserChangeAlphaBlock = _yb_browserChangeAlphaBlock;
@synthesize yb_browserToolBarHiddenBlock = _yb_browserToolBarHiddenBlock;

#pragma mark - life cycle

- (void)dealloc {
    [self removeObserverForDataState];
    [self removeObserverForSystem];
    [self cancelPlay];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initVars];
        [self addGesture];
        [self addObserverForSystem];
        
        [self.contentView addSubview:self.baseView];
        [self.baseView addSubview:self.firstFrameImageView];
        [self.baseView addSubview:self.playButton];
    }
    return self;
}

- (void)prepareForReuse {
    [self initVars];
    [self removeObserverForDataState];
    [self cancelPlay];
    self.firstFrameImageView.image = nil;
    self.playButton.hidden = YES;
    [self.baseView yb_hideProgressView];
    [self.contentView yb_hideProgressView];
    [super prepareForReuse];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    _outTransitioning = NO;
}

- (void)initVars {
    _layoutDirection = YBImageBrowserLayoutDirectionUnknown;
    _containerSize = CGSizeMake(1, 1);
    _playing = NO;
    _currentIndexIsSelf = NO;
    _bodyInCenter = YES;
    _gestureInteractionStartPoint = CGPointZero;
    _gestureInteracting = NO;
    _active = YES;
    _outTransitioning = NO;
}

#pragma mark - <YBImageBrowserCellProtocol>

- (void)yb_initializeBrowserCellWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    _containerSize = containerSize;
    _layoutDirection = layoutDirection;
    _currentIndexIsSelf = YES;
    
    if (![data isKindOfClass:YBVideoBrowseCellData.class]) return;
    self.cellData = data;
    
    [self addObserverForDataState];
    
    [self updateLayoutWithContainerSize:containerSize];
}

- (void)yb_browserLayoutDirectionChanged:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    _containerSize = containerSize;
    _layoutDirection = layoutDirection;
    
    if (_gestureInteracting) {
        [self restoreGestureInteractionWithDuration:0];
    }
    
    [self updateLayoutWithContainerSize:containerSize];
}

- (void)yb_browserPageIndexChanged:(NSUInteger)pageIndex ownIndex:(NSUInteger)ownIndex {
    if (pageIndex != ownIndex) {
        if (_playing) {
            [self.baseView yb_hideProgressView];
            [self cancelPlay];
            [self.cellData loadData];
        }
        [self restoreGestureInteractionWithDuration:0];
        _currentIndexIsSelf = NO;
    } else {
        _currentIndexIsSelf = YES;
        [self autoPlay];
    }
}

- (void)yb_browserInitializeFirst:(BOOL)isFirst {
    if (isFirst) {
        [self autoPlay];
    }
}

- (void)yb_browserBodyIsInTheCenter:(BOOL)isIn {
    _bodyInCenter = isIn;
    if (!isIn) {
        _gestureInteractionStartPoint = CGPointZero;
    }
}

- (UIView *)yb_browserCurrentForegroundView {
    [self restorePlay];
    if (self.cellData.firstFrame) {
        self.playButton.hidden = YES;
        return self.firstFrameImageView;
    }
    return self.baseView;
}

- (void)yb_browserSetGestureInteractionProfile:(YBIBGestureInteractionProfile *)giProfile {
    _giProfile = giProfile;
}

- (void)yb_browserStatusBarOrientationBefore:(UIInterfaceOrientation)orientation {
    _statusBarOrientationBefore = orientation;
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - <YBVideoBrowseActionBarDelegate>

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar clickPlayButton:(UIButton *)playButton {
    if (_player) {
        [_player play];
        [self.actionBar play];
    }
}

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar clickPauseButton:(UIButton *)pauseButton {
    if (_player) {
        [_player pause];
        [self.actionBar pause];
    }
}

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar changeValue:(float)value {
    [self videoJumpWithScale:value];
}

#pragma mark - <YBVideoBrowseTopBarDelegate>

- (void)yb_videoBrowseTopBar:(YBVideoBrowseTopBar *)topBar clickCancelButton:(UIButton *)button {
    [self browserDismiss];
}

#pragma mark - private

- (void)browserDismiss {
    _outTransitioning = YES;
    [self.contentView yb_hideProgressView];
    [self yb_hideProgressView];
    self.yb_browserDismissBlock();
    _gestureInteracting = NO;
}

- (void)updateLayoutWithContainerSize:(CGSize)containerSize {
    self.baseView.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);
    self.firstFrameImageView.frame = [self.cellData.class getImageViewFrameWithImageSize:self.cellData.firstFrame.size];
    self.playButton.center = self.baseView.center;
    if (_playerLayer) {
        _playerLayer.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);
    }
    self.actionBar.frame = [self.actionBar getFrameWithContainerSize:containerSize];
    self.topBar.frame = [self.topBar getFrameWithContainerSize:containerSize];
}

- (void)startPlay {
    if (!self.cellData.avAsset || _playing) return;
    
    [self cancelPlay];
    
    _playing = YES;
    
    _playerItem = [AVPlayerItem playerItemWithAsset:self.cellData.avAsset];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = CGRectMake(0, 0, _containerSize.width, _containerSize.height);
    [self.baseView.layer addSublayer:_playerLayer];
    
    [self addObserverForPlayer];
    
    self.playButton.hidden = YES;
    
    [self.baseView yb_showProgressViewLoading];
}

- (void)cancelPlay {
    [self restoreTooBar];
    [self restorePlay];
    [self restoreAsset];
}

- (void)restorePlay {
    if (_actionBar) self.actionBar.hidden = YES;
    if (_topBar) self.topBar.hidden = YES;
    
    [self removeObserverForPlayer];
    
    if (_player) {
        [_player pause];
        _player = nil;
    }
    if (_playerLayer) {
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
    }
    _playerItem = nil;
    
    _playing = NO;
}

- (void)restoreAsset {
    AVAsset *asset = self.cellData.avAsset;
    if ([asset isKindOfClass:AVURLAsset.class]) {
        self.cellData.avAsset = [AVURLAsset assetWithURL:((AVURLAsset *)asset).URL];
    }
}

- (void)restoreTooBar {
    if (self.yb_browserToolBarHiddenBlock) {
        self.yb_browserToolBarHiddenBlock(NO);
    }
}

- (void)autoPlay {
    YBVideoBrowseCellData *data = self.cellData;
    if (data.autoPlayCount > 0) {
        --data.autoPlayCount;
        [self startPlay];
    }
}

- (void)videoJumpWithScale:(float)scale {
    CMTime startTime = CMTimeMakeWithSeconds(scale, _player.currentTime.timescale);
    AVPlayer *tmpPlayer = _player;
    [_player seekToTime:startTime toleranceBefore:CMTimeMake(1, 1000) toleranceAfter:CMTimeMake(1, 1000) completionHandler:^(BOOL finished) {
        if (finished && tmpPlayer == self->_player) {
            [self->_player play];
            [self.actionBar play];
        }
    }];
}

- (void)cellDataDownloadStateChanged {
    YBVideoBrowseCellData *data = self.cellData;
    YBVideoBrowseCellDataDownloadState dataDownloadState = data.dataDownloadState;
    switch (dataDownloadState) {
        case YBVideoBrowseCellDataDownloadStateIsDownloading: {
            [self.contentView yb_showProgressViewWithValue:self.cellData.downloadingVideoProgress];
        }
            break;
        case YBVideoBrowseCellDataDownloadStateComplete: {
            [self.contentView yb_hideProgressView];
        }
            break;
        default:
            break;
    }
}

- (void)cellDataStateChanged {
    YBVideoBrowseCellData *data = self.cellData;
    YBVideoBrowseCellDataState dataState = data.dataState;
    switch (dataState) {
        case YBVideoBrowseCellDataStateInvalid: {
            [self.baseView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].videoIsInvalid click:nil];
        }
            break;
        case YBVideoBrowseCellDataStateFirstFrameReady: {
            if (self.firstFrameImageView.image != data.firstFrame) {
                self.firstFrameImageView.image = data.firstFrame;
                self.firstFrameImageView.frame = [self.cellData.class getImageViewFrameWithImageSize:self.cellData.firstFrame.size];
            }
            self.playButton.hidden = NO;
        }
            break;
        case YBVideoBrowseCellDataStateIsLoadingPHAsset: {
            [self.baseView yb_showProgressViewLoading];
        }
            break;
        case YBVideoBrowseCellDataStateLoadPHAssetSuccess: {
            [self.baseView yb_hideProgressView];
        }
            break;
        case YBVideoBrowseCellDataStateLoadPHAssetFailed: {
            [self.baseView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].videoIsInvalid click:nil];
        }
            break;
        case YBVideoBrowseCellDataStateIsLoadingFirstFrame: {
            [self.baseView yb_showProgressViewLoading];
        }
            break;
        case YBVideoBrowseCellDataStateLoadFirstFrameSuccess: {
            [self.baseView yb_hideProgressView];
        }
            break;
        case YBVideoBrowseCellDataStateLoadFirstFrameFailed: {
            // Get video first frame failed, also show the 'playButton'.
            [self.baseView yb_hideProgressView];
            self.playButton.hidden = NO;
        }
            break;
        default:
            break;
    }
}

- (void)avPlayerItemStatusChanged {
    if (!_active) return;
    
    self.playButton.hidden = YES;
    switch (_playerItem.status) {
        case AVPlayerItemStatusReadyToPlay: {
            
            [_player play];
            
            [self.baseView addSubview:self.actionBar];
            [self.baseView addSubview:self.topBar];
            self.actionBar.hidden = NO;
            self.topBar.hidden = NO;
            self.yb_browserToolBarHiddenBlock(YES);
            
            [self.actionBar play];
            double max = CMTimeGetSeconds(_playerItem.duration);
            [self.actionBar setMaxValue:isnan(max) || isinf(max) ? 0 : max];
            
            [self.baseView yb_hideProgressView];
        }
            break;
        case AVPlayerItemStatusUnknown: {
            [self.baseView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].videoError click:nil];
            [self cancelPlay];
        }
            break;
        case AVPlayerItemStatusFailed: {
            [self.baseView yb_showProgressViewWithText:[YBIBCopywriter shareCopywriter].videoError click:nil];
            [self cancelPlay];
        }
            break;
    }
}

#pragma mark - observe

- (void)addObserverForPlayer {
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    __weak typeof(self) wSelf = self;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        float currentTime = time.value / time.timescale;
        [sSelf.actionBar setCurrentValue:currentTime];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)removeObserverForPlayer {
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)addObserverForDataState {
    [self.cellData addObserver:self forKeyPath:@"dataState" options:NSKeyValueObservingOptionNew context:nil];
    [self.cellData addObserver:self forKeyPath:@"dataDownloadState" options:NSKeyValueObservingOptionNew context:nil];
    [self.cellData loadData];
}

- (void)removeObserverForDataState {
    [self.cellData removeObserver:self forKeyPath:@"dataState"];
    [self.cellData removeObserver:self forKeyPath:@"dataDownloadState"];
}

- (void)videoPlayFinish:(NSNotification *)noti {
    if (noti.object == _playerItem) {
        YBVideoBrowseCellData *data = self.cellData;
        if (data.repeatPlayCount > 0) {
            --data.repeatPlayCount;
            [self videoJumpWithScale:0];
            [_player play];
        } else {
            [self cancelPlay];
            [self.cellData loadData];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (!_outTransitioning) {
        if (object == _playerItem) {
            if ([keyPath isEqualToString:@"status"]) {
                [self avPlayerItemStatusChanged];
            }
        } else if (object == self.cellData) {
            if ([keyPath isEqualToString:@"dataState"]) {
                [self cellDataStateChanged];
            } else if ([keyPath isEqualToString:@"dataDownloadState"]) {
                [self cellDataDownloadStateChanged];
            }
        }
    }
}

- (void)removeObserverForSystem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)addObserverForSystem {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)   name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    _active = NO;
    if (_player && _playing) {
        [_player pause];
        [self.actionBar pause];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    _active = YES;
}

- (void)didChangeStatusBarFrame {
    if ([UIApplication sharedApplication].statusBarFrame.size.height > YBIB_HEIGHT_STATUSBAR) {
        if (_player && _playing) {
            [_player pause];
            [self.actionBar pause];
        }
    }
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            if (_player && _playing) {
                [_player pause];
                [self.actionBar pause];
            }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            break;
    }
}

#pragma mark - gesture

- (void)addGesture {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapGesture:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToPanGesture:)];
    panGesture.cancelsTouchesInView = NO;
    panGesture.delegate = self;
    
    [tapGesture requireGestureRecognizerToFail:panGesture];
    
    [self.baseView addGestureRecognizer:tapGesture];
    [self.baseView addGestureRecognizer:panGesture];
}

- (void)respondsToTapGesture:(UITapGestureRecognizer *)tap {
    if (_playing) {
        self.actionBar.hidden = !self.actionBar.isHidden;
        self.topBar.hidden = !self.topBar.isHidden;
    } else {
        [self browserDismiss];
    }
}

- (void)respondsToPanGesture:(UIPanGestureRecognizer *)pan {
    if ((!self.firstFrameImageView.image && !_playing) || _giProfile.disable) return;
    
    CGPoint point = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        
        _gestureInteractionStartPoint = point;
        
    } else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateRecognized || pan.state == UIGestureRecognizerStateFailed) {
        
        // END
        if (_gestureInteracting) {
            CGPoint velocity = [pan velocityInView:self.baseView];
            
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
        
        CGPoint velocityPoint = [pan velocityInView:self.baseView];
        CGFloat triggerDistance = _giProfile.triggerDistance;
        
        BOOL distanceArrive = ABS(point.y - _gestureInteractionStartPoint.y) > triggerDistance && (ABS(point.x - _gestureInteractionStartPoint.x) < triggerDistance && ABS(velocityPoint.x) < 500);
        
        BOOL shouldStart = !_gestureInteracting && distanceArrive && _currentIndexIsSelf && _bodyInCenter;
        // START
        if (shouldStart) {
            if (_actionBar) self.actionBar.hidden = YES;
            if (_topBar) self.topBar.hidden = YES;
            
            if ([UIApplication sharedApplication].statusBarOrientation != _statusBarOrientationBefore) {
                [self browserDismiss];
            } else {
                _gestureInteractionStartPoint = point;
                
                CGRect startFrame = self.baseView.bounds;
                CGFloat anchorX = (point.x - startFrame.origin.x) / startFrame.size.width,
                anchorY = (point.y - startFrame.origin.y) / startFrame.size.height;
                self.baseView.layer.anchorPoint = CGPointMake(anchorX, anchorY);
                self.baseView.userInteractionEnabled = NO;
                
                self.yb_browserScrollEnabledBlock(NO);
                self.yb_browserToolBarHiddenBlock(YES);
                
                _gestureInteracting = YES;
            }
        }
        
        // CHANGE
        if (_gestureInteracting) {
            self.baseView.center = point;
            CGFloat scale = 1 - ABS(point.y - _gestureInteractionStartPoint.y) / (_containerSize.height * 1.2);
            if (scale > 1) scale = 1;
            if (scale < 0.35) scale = 0.35;
            self.baseView.transform = CGAffineTransformMakeScale(scale, scale);
            
            CGFloat alpha = 1 - ABS(point.y - _gestureInteractionStartPoint.y) / (_containerSize.height * 1.1);
            if (alpha > 1) alpha = 1;
            if (alpha < 0) alpha = 0;
            self.yb_browserChangeAlphaBlock(alpha, 0);
        }
    }
}

- (void)restoreGestureInteractionWithDuration:(NSTimeInterval)duration {
    if (_actionBar) self.actionBar.hidden = NO;
    if (_topBar) self.topBar.hidden = NO;
    
    self.yb_browserChangeAlphaBlock(1, duration);
    
    void (^animations)(void) = ^{
        CGPoint anchorPoint = self.baseView.layer.anchorPoint;
        self.baseView.center = CGPointMake(self->_containerSize.width * anchorPoint.x, self->_containerSize.height * anchorPoint.y);
        self.baseView.transform = CGAffineTransformIdentity;
    };
    void (^completion)(BOOL finished) = ^(BOOL finished){
        self.yb_browserScrollEnabledBlock(YES);
        if (!self->_playing) self.yb_browserToolBarHiddenBlock(NO);
        
        self.baseView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.baseView.center = CGPointMake(self->_containerSize.width * 0.5, self->_containerSize.height * 0.5);
        self.baseView.userInteractionEnabled = YES;
        
        self->_gestureInteractionStartPoint = CGPointZero;
        self->_gestureInteracting = NO;
    };
    if (duration <= 0) {
        animations();
        completion(NO);
    } else {
        [UIView animateWithDuration:duration animations:animations completion:completion];
    }
}

#pragma mark - touch event

- (void)clickPlayButton:(UIButton *)button {
    [self startPlay];
}

#pragma mark - getter

- (UIView *)baseView {
    if (!_baseView) {
        _baseView = [UIView new];
        _baseView.backgroundColor = [UIColor clearColor];
    }
    return _baseView;
}

- (UIImageView *)firstFrameImageView {
    if (!_firstFrameImageView) {
        _firstFrameImageView = [UIImageView new];
        _firstFrameImageView.contentMode = UIViewContentModeScaleAspectFit;
        _firstFrameImageView.layer.masksToBounds = YES;
    }
    return _firstFrameImageView;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *playImg = [YBIBFileManager getImageWithName:@"ybib_bigPlay"];
        _playButton.bounds = CGRectMake(0, 0, 80, 80);
        [_playButton setImage:playImg forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(clickPlayButton:) forControlEvents:UIControlEventTouchUpInside];
        _playButton.hidden = YES;
    }
    return _playButton;
}

- (YBVideoBrowseActionBar *)actionBar {
    if (!_actionBar) {
        _actionBar = [YBVideoBrowseActionBar new];
        _actionBar.delegate = self;
    }
    return _actionBar;
}

- (YBVideoBrowseTopBar *)topBar {
    if (!_topBar) {
        _topBar = [YBVideoBrowseTopBar new];
        _topBar.delegate = self;
    }
    return _topBar;
}

@end
