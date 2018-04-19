//
//  YBImageBrowserToolBar.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserToolBar.h"

@interface YBImageBrowserToolBar () {
    CAGradientLayer *gradient;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation YBImageBrowserToolBar

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addGradient];
        [self addSubview:self.titleLabel];
        [self addSubview:self.rightButton];
    }
    return self;
}

#pragma mark public

- (void)setTitleLabelWithCurrentIndex:(NSUInteger)index totalCount:(NSUInteger)totalCount {
    if (!totalCount) return;
    if (totalCount == 1) {
        self.titleLabel.hidden = YES;
    } else {
        if (self.titleLabel.isHidden) self.titleLabel.hidden = NO;
    }
    self.titleLabel.text = [NSString stringWithFormat:@"%ld/%ld", (unsigned long)index, (unsigned long)totalCount];
}

- (void)setRightButtonImage:(UIImage *)image {
    [self.rightButton setImage:image forState:UIControlStateNormal];
    if (!image) return;
    [self resetUserInterfaceLayout_rightButton];
}

- (void)setRightButtonHide:(BOOL)hide {
    self.rightButton.hidden = hide;
}

- (void)setRightButtonTitle:(NSString *)title {
    [self.rightButton setTitle:title forState:UIControlStateNormal];
    if (!title) return;
    [self resetUserInterfaceLayout_rightButton];
}

#pragma mark private

- (void)resetUserInterfaceLayout_titleLabel {
    CGFloat selfWidth = self.frame.size.width;
    CGFloat selfHeight = self.frame.size.height;
    CGFloat titleLabelToLeft = selfWidth / 3.0;
    self.titleLabel.frame = CGRectMake(titleLabelToLeft, 0, selfWidth - 2 * titleLabelToLeft, selfHeight);
    gradient.frame = self.bounds;
}

- (void)resetUserInterfaceLayout_rightButton {
    
    CGFloat buttonWidth = 0;
    if ([self.rightButton currentTitle] || [self.rightButton currentAttributedTitle]) {
        buttonWidth = [YBImageBrowserUtilities getWidthWithAttStr:self.rightButton.titleLabel.attributedText] + 15 * 2;
    }
    if ([self.rightButton currentImage]) {
        CGSize size = [self.rightButton currentImage].size;
        buttonWidth += size.width + 15 * 2;
    }
    if (!buttonWidth) {
        return;
    }
    
    CGFloat selfWidth = self.frame.size.width;
    CGFloat selfHeight = self.frame.size.height;
    CGFloat maxLimit = (selfWidth - self.titleLabel.bounds.size.width) / 2;
    
    buttonWidth = maxLimit < buttonWidth ? maxLimit : buttonWidth;
    
    self.rightButton.frame = CGRectMake(selfWidth - buttonWidth, 0, buttonWidth, selfHeight);
}

- (void)addGradient {
    gradient = [CAGradientLayer layer];
    gradient.startPoint = CGPointMake(0.5, 0);
    gradient.endPoint = CGPointMake(0.5, 0.9);
    gradient.colors = @[(id)[UIColor colorWithRed:0  green:0  blue:0 alpha:0.3].CGColor, (id)[UIColor colorWithRed:0  green:0  blue:0 alpha:0].CGColor];
    gradient.frame = self.bounds;
    [self.layer addSublayer:gradient];
}

#pragma mark YBImageBrowserScreenOrientationProtocol

- (void)so_setFrameInfoWithSuperViewScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation superViewSize:(CGSize)size {
    
    BOOL isVertical = screenOrientation == YBImageBrowserScreenOrientationVertical;
    CGRect rect0 = CGRectMake(0, 0, size.width, 44 + YB_HEIGHT_STATUSBAR), rect1 = CGRectMake(0, 0, size.height, 44 + YB_HEIGHT_STATUSBAR);
    _so_frameOfVertical = isVertical ? rect0 : rect1;
    _so_frameOfHorizontal = !isVertical ? rect0 : rect1;
}

- (void)so_updateFrameWithScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation {
    if (screenOrientation == _so_screenOrientation) return;
    
    _so_isUpdateUICompletely = NO;
    
    self.frame = screenOrientation == YBImageBrowserScreenOrientationVertical ? _so_frameOfVertical : _so_frameOfHorizontal;
    
    _so_screenOrientation = screenOrientation;
    
    [self resetUserInterfaceLayout_titleLabel];
    [self resetUserInterfaceLayout_rightButton];
    
    _so_isUpdateUICompletely = YES;
}

#pragma mark event

- (void)clickRightButton:(UIButton *)button {
    if (_delegate && [_delegate respondsToSelector:@selector(yBImageBrowserToolBar:didClickRightButton:)]) {
        [_delegate yBImageBrowserToolBar:self didClickRightButton:button];
    }
}

#pragma mark getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLabel;
}

- (UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton addTarget:self action:@selector(clickRightButton:) forControlEvents:UIControlEventTouchUpInside];
        _rightButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _rightButton;
}


@end
