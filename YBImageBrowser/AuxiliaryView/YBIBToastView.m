//
//  YBIBToastView.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/20.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBToastView.h"
#import <objc/runtime.h>

@interface UIView ()
@property (nonatomic, strong, readonly) YBIBToastView *ybib_toast;
@end

@implementation UIView (YBIBToast)

- (void)ybib_showHookToast:(NSString *)text {
    [self ybib_showToastWithText:text type:YBIBToastTypeHook hideAfterDelay:1.7];
}

- (void)ybib_showForkToast:(NSString *)text {
    [self ybib_showToastWithText:text type:YBIBToastTypeFork hideAfterDelay:1.7];
}

- (void)ybib_showToastWithText:(NSString *)text type:(YBIBToastType)type hideAfterDelay:(NSTimeInterval)delay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(ybib_hideToast) object:nil];
    
    YBIBToastView *toast = self.ybib_toast;
    if (!toast.superview) {
        [self addSubview:toast];
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *layA = [NSLayoutConstraint constraintWithItem:toast attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        NSLayoutConstraint *layB = [NSLayoutConstraint constraintWithItem:toast attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        NSLayoutConstraint *layC = [NSLayoutConstraint constraintWithItem:toast attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:40];
        NSLayoutConstraint *layD = [NSLayoutConstraint constraintWithItem:toast attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-40];
        [self addConstraints:@[layA, layB, layC, layD]];
    }
    
    [toast showWithText:text type:type];
    [self performSelector:@selector(ybib_hideToast) withObject:nil afterDelay:delay];
}

- (void)ybib_hideToast {
    YBIBToastView *toast = self.ybib_toast;
    if (toast && toast.superview) {
        [UIView animateWithDuration:0.25 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
            toast.alpha = 1;
        }];
    }
}

static void *YBIBToastKey = &YBIBToastKey;
- (void)setYbib_toast:(YBIBToastView *)ybib_toast {
    objc_setAssociatedObject(self, YBIBToastKey, ybib_toast, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (YBIBToastView *)ybib_toast {
    YBIBToastView *toast = objc_getAssociatedObject(self, YBIBToastKey);
    if (!toast) {
        toast = [YBIBToastView new];
        self.ybib_toast = toast;
    }
    return toast;
}

@end


@interface YBIBToastView () {
    YBIBToastType _type;
    CAShapeLayer *_shapeLayer;
}
@property (nonatomic, strong) UILabel *textLabel;
@end

@implementation YBIBToastView

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.userInteractionEnabled = NO;
        self.layer.cornerRadius = 7;
        
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)updateConstraints {
    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *layA = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:20];
    NSLayoutConstraint *layB = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-20];
    NSLayoutConstraint *layC = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-15];
    NSLayoutConstraint *layD = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:70];
    NSLayoutConstraint *layE = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60];
    [self addConstraints:@[layA, layB, layC, layD, layE]];
    [super updateConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self startAnimation];
}

#pragma mark - animation

- (void)showWithText:(NSString *)text type:(YBIBToastType)type {
    self.textLabel.text = text;
    _type = type;
    [self setNeedsLayout];
}

- (void)startAnimation {
    if (_shapeLayer && _shapeLayer.superlayer) {
        [_shapeLayer removeFromSuperlayer];
    }
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    _shapeLayer.fillColor = [UIColor clearColor].CGColor;
    _shapeLayer.lineWidth = 5.0;
    _shapeLayer.lineCap = @"round";
    _shapeLayer.lineJoin = @"round";
    _shapeLayer.strokeStart = 0.0;
    _shapeLayer.strokeEnd = 0.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    CGFloat r = 13.0;
    CGFloat x = self.bounds.size.width / 2.0;
    CGFloat y = 38.0;
    switch (_type) {
        case YBIBToastTypeHook: {
            [bezierPath moveToPoint:CGPointMake(x - r - r / 2, y)];
            [bezierPath addLineToPoint:CGPointMake(x - r / 2, y + r)];
            [bezierPath addLineToPoint:CGPointMake(x + r * 2 - r / 2, y - r)];
        }
            break;
        case YBIBToastTypeFork: {
            [bezierPath moveToPoint:CGPointMake(x - r, y - r)];
            [bezierPath addLineToPoint:CGPointMake(x + r, y + r)];
            [bezierPath moveToPoint:CGPointMake(x - r, y + r)];
            [bezierPath addLineToPoint:CGPointMake(x + r, y - r)];
        }
            break;
        default:break;
    }
    
    CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [baseAnimation setFromValue:@0.0];
    [baseAnimation setToValue:@1.0];
    [baseAnimation setDuration:0.3];
    baseAnimation.removedOnCompletion = NO;
    baseAnimation.fillMode = kCAFillModeBoth;
    
    _shapeLayer.path = bezierPath.CGPath;
    [self.layer addSublayer:_shapeLayer];
    [_shapeLayer addAnimation:baseAnimation forKey:@"strokeEnd"];
}

#pragma mark - getter

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont systemFontOfSize:14];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.numberOfLines = 0;
    }
    return _textLabel;
}

@end

