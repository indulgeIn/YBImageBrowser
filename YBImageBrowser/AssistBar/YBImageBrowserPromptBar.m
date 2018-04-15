//
//  YBImageBrowserPromptBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserPromptBar.h"
#import <objc/runtime.h>

#define FONT_TEXTLABLE [UIFont systemFontOfSize:14]

@implementation UIView (YBImageBrowserPromptBar)

- (void)yb_showHookPromptWithText:(NSString *)text {
    [self showWithText:text type:YBImageBrowserPromptBarTypeHook];
}

- (void)yb_showForkPromptWithText:(NSString *)text {
    [self showWithText:text type:YBImageBrowserPromptBarTypeFork];
}

- (void)showWithText:(NSString *)text type:(YBImageBrowserPromptBarType)type {
    
    YBImageBrowserPromptBar *promptBar = self.ybImageBrowserPromptBar;
    if (!promptBar) {
        promptBar = [[YBImageBrowserPromptBar alloc] initWithFrame:CGRectZero barType:type];
        self.ybImageBrowserPromptBar = promptBar;
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:promptBar];
    }
    
    [self addSubview:promptBar];
    
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:FONT_TEXTLABLE}];
    CGFloat selfWidth = self.bounds.size.width;
    CGFloat width = [YBImageBrowserUtilities getWidthWithAttStr:attr] + 20 + 5, height = 100;;
    if (width > selfWidth - 30) {
        width = selfWidth - 30;
    }
    if (width < 100) {
        width = 100;
    }
    promptBar.bounds = CGRectMake(0, 0, width, height);
    promptBar.center = self.center;
    promptBar.barType = type;
    [promptBar resetUserInterfaceLayout_textLabel];
    promptBar.textLabel.text = text;
    [promptBar drawView];
    
    [promptBar performSelector:@selector(removePromptBar:) withObject:promptBar afterDelay:2];
}

- (void)removePromptBar:(YBImageBrowserPromptBar *)promptBar {
    if (promptBar && promptBar.superview) {
        [promptBar removeFromSuperview];
    }
}

- (void)yb_hidePromptImmediately {
    YBImageBrowserPromptBar *promptBar = self.ybImageBrowserPromptBar;
    if (!promptBar || !promptBar.superview) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:promptBar];
    [self removePromptBar:promptBar];
}

- (void)setYbImageBrowserPromptBar:(YBImageBrowserPromptBar *)ybImageBrowserPromptBar {
    objc_setAssociatedObject(self, "YBImageBrowserPromptBar", ybImageBrowserPromptBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YBImageBrowserPromptBar *)ybImageBrowserPromptBar {
    return objc_getAssociatedObject(self, "YBImageBrowserPromptBar");
}

@end


@interface YBImageBrowserPromptBar ()

@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) UIBezierPath *bezierPath;
@property (nonatomic, strong) CABasicAnimation *baseAnimation;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation YBImageBrowserPromptBar

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame barType:(YBImageBrowserPromptBarType)barType {
    self = [super initWithFrame:frame];
    if (self) {
        self.barType = barType;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.userInteractionEnabled = NO;
        self.layer.cornerRadius = 7;
        [self addSubview:self.textLabel];
    }
    return self;
}

#pragma mark public
- (void)resetUserInterfaceLayout_textLabel {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    self.textLabel.frame = CGRectMake(10, height-30, width-10*2, 20);
}

#pragma mark draw

- (void)drawView {
    
    if (_shapeLayer && _shapeLayer.superlayer) {
        [_shapeLayer removeFromSuperlayer];
        [_shapeLayer removeAnimationForKey:@"strokeEnd"];
        _shapeLayer = nil;
        _baseAnimation = nil;
        _bezierPath = nil;
    }
    
    CGFloat r = 13.0;
    CGFloat x = self.bounds.size.width / 2.0;
    CGFloat y = (self.bounds.size.height - 25) / 2.0 ;
    
    if (_barType == YBImageBrowserPromptBarTypeHook) {
        [self.bezierPath moveToPoint:CGPointMake(x - r - r / 2, y)];
        [self.bezierPath addLineToPoint:CGPointMake(x - r / 2, y + r)];
        [self.bezierPath addLineToPoint:CGPointMake(x + r * 2 - r / 2, y - r)];
    } else if (_barType == YBImageBrowserPromptBarTypeFork) {
        [self.bezierPath moveToPoint:CGPointMake(x - r, y - r)];
        [self.bezierPath addLineToPoint:CGPointMake(x + r, y + r)];
        [self.bezierPath moveToPoint:CGPointMake(x - r, y + r)];
        [self.bezierPath addLineToPoint:CGPointMake(x + r, y - r)];
    }
    
    self.shapeLayer.path = self.bezierPath.CGPath;
    [self.layer addSublayer:self.shapeLayer];
    [self.shapeLayer addAnimation:self.baseAnimation forKey:@"strokeEnd"];
}

#pragma mark getter

- (CAShapeLayer *)shapeLayer {
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        _shapeLayer.fillColor = [UIColor clearColor].CGColor;
        _shapeLayer.lineWidth = 5.0;
        _shapeLayer.lineCap = @"round";
        _shapeLayer.lineJoin = @"round";
        _shapeLayer.strokeStart = 0.0;
        _shapeLayer.strokeEnd = 0.0;
    }
    return _shapeLayer;
}

- (UIBezierPath *)bezierPath {
    if (!_bezierPath) {
        _bezierPath = [UIBezierPath bezierPath];
    }
    return _bezierPath;
}

- (CABasicAnimation *)baseAnimation {
    if (!_baseAnimation) {
        _baseAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        [_baseAnimation setFromValue:@0.0];
        [_baseAnimation setToValue:@1.0];
        [_baseAnimation setDuration:0.3];
        _baseAnimation.removedOnCompletion = NO;
        _baseAnimation.fillMode = kCAFillModeBoth;
    }
    return _baseAnimation;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = FONT_TEXTLABLE;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _textLabel;
}

@end
