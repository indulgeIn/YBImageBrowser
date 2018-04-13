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

@end

@implementation YBImageBrowserToolBar

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
    self.titleLabel.text = [NSString stringWithFormat:@"%ld/%ld", index, totalCount];
}

- (void)resetUserInterfaceLayout {
    self.frame = CGRectMake(0, 0, self.superview.frame.size.width, YB_HEIGHT_TOOLBAR);
    CGFloat selfWidth = self.frame.size.width;
    CGFloat selfHeight = self.frame.size.height;
    CGFloat titleLabelToLeft = 80, buttonWidth = 50;
    self.titleLabel.frame = CGRectMake(titleLabelToLeft, 0, selfWidth - 2 * titleLabelToLeft, selfHeight);
    self.rightButton.frame = CGRectMake(selfWidth - buttonWidth, 0, buttonWidth, selfHeight);
    gradient.frame = self.bounds;
}

#pragma mark private

- (void)addGradient {
    gradient = [CAGradientLayer layer];
    gradient.startPoint = CGPointMake(0.5, 0);
    gradient.endPoint = CGPointMake(0.5, 0.9);
    gradient.colors = @[(id)[UIColor colorWithRed:0  green:0  blue:0 alpha:0.5].CGColor, (id)[UIColor colorWithRed:0  green:0  blue:0 alpha:0].CGColor];
    gradient.frame = self.bounds;
    [self.layer addSublayer:gradient];
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
    }
    return _titleLabel;
}

- (UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton setImage:[UIImage imageNamed:@"ybImageBrowser_more"] forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(clickRightButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightButton;
}


@end
