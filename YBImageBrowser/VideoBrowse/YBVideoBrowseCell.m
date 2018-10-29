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
    BOOL _isPlaying;
    BOOL _currentIndexIsSelf;
    BOOL _bodyIsInCenter;
    BOOL _isActive;
    
    CGPoint _gestureInteractionStartPoint;
    // Gestural interaction is in progress.
    BOOL _isGestureInteraction;
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

- (void)initVars {
    self->_layoutDirection = YBImageBrowserLayoutDirectionUnknown;
    self->_containerSize = CGSizeMake(1, 1);
    self->_isPlaying = NO;
    self->_currentIndexIsSelf = NO;
    self->_bodyIsInCenter = YES;
    self->_gestureInteractionStartPoint = CGPointZero;
    self->_isGestureInteraction = NO;
    self->_isActive = YES;
}

#pragma mark - <YBImageBrowserCellProtocol>

- (void)yb_initializeBrowserCellWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    self->_containerSize = containerSize;
    self->_layoutDirection = layoutDirection;
    self->_currentIndexIsSelf = YES;
    
    if (![data isKindOfClass:YBVideoBrowseCellData.class]) return;
    self.cellData = data;
    
    [self addObserverForDataState];
    
    [self updateLayoutWithContainerSize:containerSize];
}

- (void)yb_browserLayoutDirectionChanged:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    self->_containerSize = containerSize;
    self->_layoutDirection = layoutDirection;
    
    if (self->_isGestureInteraction) {
        [self restoreGestureInteractionWithDuration:0];
    }
    
    [self updateLayoutWithContainerSize:containerSize];
}

- (void)yb_browserPageIndexChanged:(NSUInteger)pageIndex ownIndex:(NSUInteger)ownIndex {
    if (pageIndex != ownIndex) {
        if (self->_isPlaying) {
            [self.baseView yb_hideProgressView];
            [self cancelPlay];
            [self.cellData loadData];
        }
        [self restoreGestureInteractionWithDuration:0];
        self->_currentIndexIsSelf = NO;
    } else {
        self->_currentIndexIsSelf = YES;
        [self autoPlay];
    }
}

- (void)yb_browserInitializeFirst:(BOOL)isFirst {
    if (isFirst) {
        [self autoPlay];
    }
}

- (void)yb_browserBodyIsInTheCenter:(BOOL)isIn {
    self->_bodyIsInCenter = isIn;
    if (!isIn) {
        self->_gestureInteractionStartPoint = CGPointZero;
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
    self->_giProfile = giProfile;
}

- (void)yb_browserStatusBarOrientationBefore:(UIInterfaceOrientation)orientation {
    self->_statusBarOrientationBefore = orientation;
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - <YBVideoBrowseActionBarDelegate>

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar clickPlayButton:(UIButton *)playButton {
    if (self->_player) {
        [self->_player play];
        [self.actionBar play];
    }
}

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar clickPauseButton:(UIButton *)pauseButton {
    if (self->_player) {
        [self->_player pause];
        [self.actionBar pause];
    }
}

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar changeValue:(float)value {
    [self videoJumpWithScale:value];
}

#pragma mark - <YBVideoBrowseTopBarDelegate>

- (void)yb_videoBrowseTopBar:(YBVideoBrowseTopBar *)topBar clickCancelButton:(UIButton *)button {
    self.yb_browserDismissBlock();
}

#pragma mark - private

- (void)updateLayoutWithContainerSize:(CGSize)containerSize {
    self.baseView.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);
    self.firstFrameImageView.frame = [self.cellData.class getImageViewFrameWithImageSize:self.cellData.firstFrame.size];
    self.playButton.center = self.baseView.center;
    if (self->_playerLayer) {
        self->_playerLayer.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);
    }
    self.actionBar.frame = [self.actionBar getFrameWithContainerSize:containerSize];
    self.topBar.frame = [self.topBar getFrameWithContainerSize:containerSize];
}

- (void)startPlay {
    if (!self.cellData.avAsset || self->_isPlaying) return;
    
    [self cancelPlay];
    
    self->_isPlaying = YES;
    
    self->_playerItem = [AVPlayerItem playerItemWithAsset:self.cellData.avAsset];
    self->_player = [AVPlayer playerWithPlayerItem:self->_playerItem];
    self->_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self->_player];
    self->_playerLayer.frame = CGRectMake(0, 0, self->_containerSize.width, self->_containerSize.height);
    [self.baseView.layer addSublayer:self->_playerLayer];
    
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
    if (self->_actionBar) self.actionBar.hidden = YES;
    if (self->_topBar) self.topBar.hidden = YES;
    
    [self removeObserverForPlayer];
    
    if (self->_player) {
        [self->_player pause];
        self->_player = nil;
    }
    if (self->_playerLayer) {
        [self->_playerLayer removeFromSuperlayer];
        self->_playerLayer = nil;
    }
    self->_playerItem = nil;
    
    self->_isPlaying = NO;
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
    CMTime startTime = CMTimeMakeWithSeconds(scale, self->_player.currentTime.timescale);
    AVPlayer *tmpPlayer = self->_player;
    [self->_player seekToTime:startTime toleranceBefore:CMTimeMake(1, 1000) toleranceAfter:CMTimeMake(1, 1000) completionHandler:^(BOOL finished) {
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
            self.firstFrameImageView.image = data.firstFrame;
            self.firstFrameImageView.frame = [self.cellData.class getImageViewFrameWithImageSize:self.cellData.firstFrame.size];
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
    if (!self->_isActive) return;
    
    self.playButton.hidden = YES;
    switch (self->_playerItem.status) {
        case AVPlayerItemStatusReadyToPlay: {
            
            [self->_player play];
            
            [self.baseView addSubview:self.actionBar];
            [self.baseView addSubview:self.topBar];
            self.actionBar.hidden = NO;
            self.topBar.hidden = NO;
            self.yb_browserToolBarHiddenBlock(YES);
            
            [self.actionBar play];
            double max = CMTimeGetSeconds(self->_playerItem.duration);
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
    [self->_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    __weak typeof(self) wSelf = self;
    [self->_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        float currentTime = time.value / time.timescale;
        [sSelf.actionBar setCurrentValue:currentTime];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self->_playerItem];
}

- (void)removeObserverForPlayer {
    [self->_playerItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self->_playerItem];
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
    if (noti.object == self->_playerItem) {
        YBVideoBrowseCellData *data = self.cellData;
        if (data.repeatPlayCount > 0) {
            --data.repeatPlayCount;
            [self videoJumpWithScale:0];
            [self->_player play];
        } else {
            [self cancelPlay];
            [self.cellData loadData];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self->_playerItem) {
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
    self->_isActive = NO;
    if (self->_player && self->_isPlaying) {
        [self->_player pause];
        [self.actionBar pause];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    self->_isActive = YES;
}

- (void)didChangeStatusBarFrame {
    if ([UIApplication sharedApplication].statusBarFrame.size.height > YBIB_HEIGHT_STATUSBAR) {
        if (self->_player && self->_isPlaying) {
            [self->_player pause];
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
            if (self->_player && self->_isPlaying) {
//                [self->_player pause];
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
    if (self->_isPlaying) {
        self.actionBar.hidden = !self.actionBar.isHidden;
        self.topBar.hidden = !self.topBar.isHidden;
    } else {
        self.yb_browserDismissBlock();
    }
}

- (void)respondsToPanGesture:(UIPanGestureRecognizer *)pan {
    if ((!self.firstFrameImageView.image && !self->_isPlaying) || self->_giProfile.disable) return;
    
    CGPoint point = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        
        self->_gestureInteractionStartPoint = point;
        
    } else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateRecognized || pan.state == UIGestureRecognizerStateFailed) {
        
        // END
        if (self->_isGestureInteraction) {
            CGPoint velocity = [pan velocityInView:self.baseView];
            
            BOOL velocityArrive = ABS(velocity.y) > self->_giProfile.dismissVelocityY;
            BOOL distanceArrive = ABS(point.y - self->_gestureInteractionStartPoint.y) > self->_containerSize.height * self->_giProfile.dismissScale;
            
            BOOL shouldDismiss = distanceArrive || velocityArrive;
            if (shouldDismiss) {
                self.yb_browserDismissBlock();
            } else {
                [self restoreGestureInteractionWithDuration:self->_giProfile.restoreDuration];
            }
        }
        
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        
        CGPoint velocityPoint = [pan velocityInView:self.baseView];
        CGFloat triggerDistance = self->_giProfile.triggerDistance;
        
        BOOL distanceArrive = ABS(point.y - self->_gestureInteractionStartPoint.y) > triggerDistance && (ABS(point.x - self->_gestureInteractionStartPoint.x) < triggerDistance && ABS(velocityPoint.x) < 500);
        
        BOOL shouldStart = !self->_isGestureInteraction && distanceArrive && self->_currentIndexIsSelf && self->_bodyIsInCenter;
        // START
        if (shouldStart) {
            if (self->_actionBar) self.actionBar.hidden = YES;
            if (self->_topBar) self.topBar.hidden = YES;
            
            if ([UIApplication sharedApplication].statusBarOrientation != self->_statusBarOrientationBefore) {
                self.yb_browserDismissBlock();
            } else {
                self->_gestureInteractionStartPoint = point;
                
                CGRect startFrame = self.baseView.bounds;
                CGFloat anchorX = (point.x - startFrame.origin.x) / startFrame.size.width,
                anchorY = (point.y - startFrame.origin.y) / startFrame.size.height;
                self.baseView.layer.anchorPoint = CGPointMake(anchorX, anchorY);
                self.baseView.userInteractionEnabled = NO;
                
                self.yb_browserScrollEnabledBlock(NO);
                self.yb_browserToolBarHiddenBlock(YES);
                
                self->_isGestureInteraction = YES;
            }
        }
        
        // CHANGE
        if (self->_isGestureInteraction) {
            self.baseView.center = point;
            CGFloat scale = 1 - ABS(point.y - self->_gestureInteractionStartPoint.y) / (self->_containerSize.height * 1.2);
            if (scale > 1) scale = 1;
            if (scale < 0.35) scale = 0.35;
            self.baseView.transform = CGAffineTransformMakeScale(scale, scale);
            
            CGFloat alpha = 1 - ABS(point.y - self->_gestureInteractionStartPoint.y) / (self->_containerSize.height * 1.1);
            if (alpha > 1) alpha = 1;
            if (alpha < 0) alpha = 0;
            self.yb_browserChangeAlphaBlock(alpha, 0);
        }
    }
}

- (void)restoreGestureInteractionWithDuration:(NSTimeInterval)duration {
    if (self->_actionBar) self.actionBar.hidden = NO;
    if (self->_topBar) self.topBar.hidden = NO;
    
    self.yb_browserChangeAlphaBlock(1, duration);
    
    void (^animations)(void) = ^{
        self.baseView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.baseView.center = CGPointMake(self->_containerSize.width / 2, self->_containerSize.height / 2);
        self.baseView.transform = CGAffineTransformIdentity;
    };
    void (^completion)(BOOL finished) = ^(BOOL finished){
        self.yb_browserScrollEnabledBlock(YES);
        if (!self->_isPlaying) self.yb_browserToolBarHiddenBlock(NO);
        
        self.baseView.userInteractionEnabled = YES;
        
        self->_gestureInteractionStartPoint = CGPointZero;
        self->_isGestureInteraction = NO;
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
