//
//  YBVideoBrowseActionBar.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/28.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBVideoBrowseActionBar.h"
#import "YBIBUtilities.h"
#import "YBIBFileManager.h"


@interface YBVideoBrowseActionSlider : UISlider
@end
@implementation YBVideoBrowseActionSlider
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setThumbImage:[YBIBFileManager getImageWithName:@"ybib_circlePoint"] forState:UIControlStateNormal];
        self.minimumTrackTintColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1];
        self.maximumTrackTintColor = [[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1] colorWithAlphaComponent:0.5];
    }
    return self;
}
- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect frame = [super trackRectForBounds:bounds];
    return CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 2);
}
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    CGRect frame = [super thumbRectForBounds:bounds trackRect:rect value:value];
    return CGRectMake(frame.origin.x - 10, frame.origin.y - 10, frame.size.width + 20, frame.size.height + 20);
}
@end


static CGFloat kActionBarDefaultsHeight = 50.0;

@interface YBVideoBrowseActionBar () {
    BOOL _isDragging;
}
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UILabel *preTimeLabel;
@property (nonatomic, strong) UILabel *sufTimeLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) YBVideoBrowseActionSlider *slider;
@end

@implementation YBVideoBrowseActionBar

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_isDragging = NO;
        
        [self.layer addSublayer:self.gradientLayer];
        [self addSubview:self.playButton];
        [self addSubview:self.preTimeLabel];
        [self addSubview:self.sufTimeLabel];
        [self addSubview:self.slider];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat hExtra = 0;
    if (YBIB_IS_IPHONEX && [UIScreen mainScreen].bounds.size.height < [UIScreen mainScreen].bounds.size.width) hExtra += YBIB_HEIGHT_EXTRABOTTOM;
    
    CGFloat width = self.bounds.size.width, height = kActionBarDefaultsHeight, timeLabelWidth = 55;
    self.playButton.frame = CGRectMake(10 + hExtra, 0, height, height);
    self.preTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), 0, timeLabelWidth, height);
    self.sufTimeLabel.frame = CGRectMake(width - timeLabelWidth - hExtra, 0, timeLabelWidth, height);
    self.slider.frame = CGRectMake(CGRectGetMaxX(self.preTimeLabel.frame), 0, CGRectGetMinX(self.sufTimeLabel.frame) - CGRectGetMaxX(self.preTimeLabel.frame), height);
    self.gradientLayer.frame = self.bounds;
    [super layoutSubviews];
}

#pragma mark - public

- (CGRect)getFrameWithContainerSize:(CGSize)containerSize {
    CGFloat height = kActionBarDefaultsHeight + YBIB_HEIGHT_EXTRABOTTOM;
    return CGRectMake(0, containerSize.height - height, containerSize.width, height);
}

- (void)pause {
    self.playButton.selected = NO;
}

- (void)play {
    self.playButton.selected = YES;
    self->_isDragging = NO;
    self.slider.userInteractionEnabled = YES;
}

- (void)setMaxValue:(float)value {
    self.slider.maximumValue = value;
    self.sufTimeLabel.text = [self.class timeformatFromSeconds:value];
}

- (void)setCurrentValue:(float)value {
    if (!self->_isDragging) {
        [self.slider setValue:value animated:YES];
    }
    self.preTimeLabel.text = [self.class timeformatFromSeconds:value];
}

#pragma mark - tool

+ (NSString *)timeformatFromSeconds:(NSInteger)seconds {
    return seconds > 3600 ? [NSString stringWithFormat:@"%02ld:%02ld:%02ld", seconds / 3600, (seconds % 3600) / 60, seconds % 60] : [NSString stringWithFormat:@"%02ld:%02ld", (seconds % 3600) / 60, seconds % 60];
}

#pragma mark - touch event

- (void)clickPlayButton:(UIButton *)button {
    button.userInteractionEnabled = NO;
    if (button.selected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(yb_videoBrowseActionBar:clickPauseButton:)]) {
            [self.delegate yb_videoBrowseActionBar:self clickPauseButton:button];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(yb_videoBrowseActionBar:clickPlayButton:)]) {
            [self.delegate yb_videoBrowseActionBar:self clickPlayButton:button];
        }
    }
    button.userInteractionEnabled = YES;
}

- (void)respondsToSliderTouchFinished:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(yb_videoBrowseActionBar:changeValue:)]) {
        [self.delegate yb_videoBrowseActionBar:self changeValue:slider.value];
    }
}

- (void)respondsToSliderTouchDown:(UISlider *)slider {
    self->_isDragging = YES;
    slider.userInteractionEnabled = NO;
}

#pragma mark - getter

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[YBIBFileManager getImageWithName:@"ybib_play"] forState:UIControlStateNormal];
        [_playButton setImage:[YBIBFileManager getImageWithName:@"ybib_pause"] forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(clickPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (UILabel *)preTimeLabel {
    if (!_preTimeLabel) {
        _preTimeLabel = [UILabel new];
        _preTimeLabel.text = @"00:00";
        _preTimeLabel.adjustsFontSizeToFitWidth = YES;
        _preTimeLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:11];
        _preTimeLabel.textAlignment = NSTextAlignmentCenter;
        _preTimeLabel.textColor = [[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1] colorWithAlphaComponent:0.9];
    }
    return _preTimeLabel;
}

- (UILabel *)sufTimeLabel {
    if (!_sufTimeLabel) {
        _sufTimeLabel = [UILabel new];
        _sufTimeLabel.text = @"00:00";
        _sufTimeLabel.adjustsFontSizeToFitWidth = YES;
        _sufTimeLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:11];
        _sufTimeLabel.textAlignment = NSTextAlignmentCenter;
        _sufTimeLabel.textColor = [[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1] colorWithAlphaComponent:0.9];
    }
    return _sufTimeLabel;
}

- (YBVideoBrowseActionSlider *)slider {
    if (!_slider) {
        _slider = [YBVideoBrowseActionSlider new];
        [_slider addTarget:self action:@selector(respondsToSliderTouchFinished:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchUpOutside];
        [_slider addTarget:self action:@selector(respondsToSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    }
    return _slider;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.endPoint = CGPointMake(0.5, 0);
        _gradientLayer.startPoint = CGPointMake(0.5, 1);
        _gradientLayer.colors = @[(id)[UIColor colorWithRed:0  green:0  blue:0 alpha:0.3].CGColor, (id)[UIColor colorWithRed:0  green:0  blue:0 alpha:0].CGColor];
    }
    return _gradientLayer;
}

@end
