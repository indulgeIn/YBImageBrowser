//
//  YBIBVideoActionBar.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/11.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBVideoActionBar.h"
#import "YBIBIconManager.h"


@interface YBVideoBrowseActionSlider : UISlider
@end
@implementation YBVideoBrowseActionSlider
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setThumbImage:YBIBIconManager.sharedManager.videoDragCircleImage() forState:UIControlStateNormal];
        self.minimumTrackTintColor = UIColor.whiteColor;
        self.maximumTrackTintColor = [UIColor.whiteColor colorWithAlphaComponent:0.5];
        self.layer.shadowColor = UIColor.darkGrayColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 1);
        self.layer.shadowOpacity = 1;
        self.layer.shadowRadius = 4;
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


@interface YBIBVideoActionBar ()
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UILabel *preTimeLabel;
@property (nonatomic, strong) UILabel *sufTimeLabel;
@property (nonatomic, strong) YBVideoBrowseActionSlider *slider;
@end

@implementation YBIBVideoActionBar {
    BOOL _dragging;
}

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _dragging = NO;
        [self addSubview:self.playButton];
        [self addSubview:self.preTimeLabel];
        [self addSubview:self.sufTimeLabel];
        [self addSubview:self.slider];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width, height = self.bounds.size.height, labelWidth = 55, buttonWidth = 44, labelOffset = 10;
    CGFloat imageWidth = YBIBIconManager.sharedManager.videoPlayImage().size.width;
    CGFloat offset = (buttonWidth - imageWidth) * 0.5;
    
    self.playButton.frame = CGRectMake(10, 0, buttonWidth, height);
    self.preTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame) + labelOffset - offset, 0, labelWidth, height);
    self.sufTimeLabel.frame = CGRectMake(width - labelWidth - labelOffset, 0, labelWidth, height);
    self.slider.frame = CGRectMake(CGRectGetMaxX(self.preTimeLabel.frame), 0, CGRectGetMinX(self.sufTimeLabel.frame) - CGRectGetMaxX(self.preTimeLabel.frame), height);
}

#pragma mark - public

+ (CGFloat)defaultHeight {
    return 44;
}

- (void)setMaxValue:(float)value {
    self.slider.maximumValue = value;
    self.sufTimeLabel.attributedText = [self.class timeformatFromSeconds:value];
}

- (void)setCurrentValue:(float)value {
    if (!_dragging) {
        [self.slider setValue:value animated:YES];
    }
    self.preTimeLabel.attributedText = [self.class timeformatFromSeconds:value];
}

- (void)pause {
    self.playButton.selected = NO;
}

- (void)play {
    _dragging = NO;
    self.playButton.selected = YES;
    self.slider.userInteractionEnabled = YES;
}

#pragma mark - private

+ (NSAttributedString *)timeformatFromSeconds:(NSInteger)seconds {
    NSInteger hour = seconds / 3600, min = (seconds % 3600) / 60, sec = seconds % 60;
    NSString *text = seconds > 3600 ? [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hour, (long)min, (long)sec] : [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec];
    
    NSShadow *shadow = [NSShadow new];
    shadow.shadowBlurRadius = 4;
    shadow.shadowOffset = CGSizeMake(0, 1);
    shadow.shadowColor = UIColor.darkGrayColor;
    NSAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSShadowAttributeName:shadow, NSFontAttributeName:[UIFont boldSystemFontOfSize:11]}];
    return attr;
}

#pragma mark - touch event

- (void)clickPlayButton:(UIButton *)button {
    button.userInteractionEnabled = NO;
    if (button.selected) {
        [self.delegate yb_videoActionBar:self clickPauseButton:button];
    } else {
        [self.delegate yb_videoActionBar:self clickPlayButton:button];
    }
    button.userInteractionEnabled = YES;
}

- (void)respondsToSliderTouchFinished:(UISlider *)slider {
    [self.delegate yb_videoActionBar:self changeValue:slider.value];
}

- (void)respondsToSliderTouchDown:(UISlider *)slider {
    _dragging = YES;
    slider.userInteractionEnabled = NO;
}

#pragma mark - getters

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:YBIBIconManager.sharedManager.videoPlayImage() forState:UIControlStateNormal];
        [_playButton setImage:YBIBIconManager.sharedManager.videoPauseImage() forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(clickPlayButton:) forControlEvents:UIControlEventTouchUpInside];
        _playButton.layer.shadowColor = UIColor.darkGrayColor.CGColor;
        _playButton.layer.shadowOffset = CGSizeMake(0, 1);
        _playButton.layer.shadowOpacity = 1;
        _playButton.layer.shadowRadius = 4;
    }
    return _playButton;
}

- (UILabel *)preTimeLabel {
    if (!_preTimeLabel) {
        _preTimeLabel = [UILabel new];
        _preTimeLabel.attributedText = [self.class timeformatFromSeconds:0];
        _preTimeLabel.adjustsFontSizeToFitWidth = YES;
        _preTimeLabel.textAlignment = NSTextAlignmentCenter;
        _preTimeLabel.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.9];
    }
    return _preTimeLabel;
}

- (UILabel *)sufTimeLabel {
    if (!_sufTimeLabel) {
        _sufTimeLabel = [UILabel new];
        _sufTimeLabel.attributedText = [self.class timeformatFromSeconds:0];
        _sufTimeLabel.adjustsFontSizeToFitWidth = YES;
        _sufTimeLabel.textAlignment = NSTextAlignmentCenter;
        _sufTimeLabel.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.9];
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

- (BOOL)isTouchInside {
    return self.slider.isTouchInside;
}

@end
