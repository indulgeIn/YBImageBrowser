//
//  YBIBLoadingView.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/9/1.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "YBIBLoadingView.h"
#import "YBIBIconManager.h"
#import <objc/runtime.h>

@interface UIView ()
@property (nonatomic, strong, readonly) YBIBLoadingView *ybib_loading;
@end

@implementation UIView (YBIBLoading)

- (void)ybib_showLoadingWithProgress:(CGFloat)progress {
    [self ybib_addLoadingView];
    [self.ybib_loading showProgress:progress];
}

- (void)ybib_showLoading {
    [self ybib_addLoadingView];
    [self.ybib_loading show];
}

- (void)ybib_showLoadingWithText:(NSString *)text click:(void (^)(void))click {
    [self ybib_addLoadingView];
    [self.ybib_loading showText:text click:click];
}

- (void)ybib_addLoadingView {
    YBIBLoadingView *loading = self.ybib_loading;
    if (!loading.superview) {
        [self addSubview:loading];
        loading.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *layA = [NSLayoutConstraint constraintWithItem:loading attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint *layB = [NSLayoutConstraint constraintWithItem:loading attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        NSLayoutConstraint *layC = [NSLayoutConstraint constraintWithItem:loading attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        NSLayoutConstraint *layD = [NSLayoutConstraint constraintWithItem:loading attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        [self addConstraints:@[layA, layB, layC, layD]];
    }
}

- (void)ybib_hideLoading {
    YBIBLoadingView *loading = self.ybib_loading;
    if (loading && loading.superview) {
        [loading removeFromSuperview];
    }
}

static void *YBIBLoadingKey = &YBIBLoadingKey;
- (void)setYbib_loading:(YBIBLoadingView *)ybib_loading {
    objc_setAssociatedObject(self, YBIBLoadingKey, ybib_loading, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (YBIBLoadingView *)ybib_loading {
    YBIBLoadingView *loading = objc_getAssociatedObject(self, YBIBLoadingKey);
    if (!loading) {
        loading = [YBIBLoadingView new];
        self.ybib_loading = loading;
    }
    return loading;
}

@end


@interface YBIBProgressDrawView : UIView
@property (nonatomic, assign) CGFloat progress;
@end
@implementation YBIBProgressDrawView
- (void)drawRect:(CGRect)rect {
    if (self.isHidden) return;
    
    CGFloat progress = (isnan(_progress) || isinf(_progress) || _progress < 0) ? 0 : _progress;
    
    CGFloat radius = 17;
    CGFloat strokeWidth = 3;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    [[UIColor lightGrayColor] setStroke];
    UIBezierPath *bottomPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    bottomPath.lineWidth = 4.0;
    bottomPath.lineCapStyle = kCGLineCapRound;
    bottomPath.lineJoinStyle = kCGLineCapRound;
    [bottomPath stroke];
    
    [[UIColor whiteColor] setStroke];
    UIBezierPath *activePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI / 2.0 endAngle:M_PI * 2 * progress - M_PI / 2.0 clockwise:true];
    activePath.lineWidth = strokeWidth;
    activePath.lineCapStyle = kCGLineCapRound;
    activePath.lineJoinStyle = kCGLineCapRound;
    [activePath stroke];
    
    NSShadow *shadow = [NSShadow new];
    shadow.shadowBlurRadius = 4;
    shadow.shadowOffset = CGSizeMake(0, 1);
    shadow.shadowColor = UIColor.darkGrayColor;
    NSString *string = [NSString stringWithFormat:@"%.0lf%@", progress * 100, @"%"];
    NSMutableAttributedString *atts = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:10], NSForegroundColorAttributeName:[UIColor whiteColor], NSShadowAttributeName:shadow}];
    CGSize size = atts.size;
    [atts drawAtPoint:CGPointMake(center.x - size.width / 2.0, center.y - size.height / 2.0)];
}
@end


typedef NS_ENUM(NSUInteger, YBImageBrowserProgressType) {
    YBImageBrowserProgressTypeProgress,
    YBImageBrowserProgressTypeLoad,
    YBImageBrowserProgressTypeText
};

@interface YBIBLoadingView () {
    YBImageBrowserProgressType  _type;
}
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) YBIBProgressDrawView *drawView;
@property (nonatomic, copy) void(^clickTextLabelBlock)(void);
@end

@implementation YBIBLoadingView

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        self.userInteractionEnabled = NO;
        
        [self addSubview:self.drawView];
        [self addSubview:self.textLabel];
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)updateConstraints {
    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *layA = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:20];
    NSLayoutConstraint *layB = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-20];
    NSLayoutConstraint *layC = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *layE = [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *layF = [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    
    self.drawView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *layG = [NSLayoutConstraint constraintWithItem:self.drawView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *layH = [NSLayoutConstraint constraintWithItem:self.drawView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    NSLayoutConstraint *layI = [NSLayoutConstraint constraintWithItem:self.drawView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    NSLayoutConstraint *layJ = [NSLayoutConstraint constraintWithItem:self.drawView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    
    [self addConstraints:@[layA, layB, layC, layE, layF, layG, layH, layI, layJ]];
    [super updateConstraints];
}

#pragma mark public

- (void)showProgress:(CGFloat)progress {
    self.userInteractionEnabled = NO;
    _type = YBImageBrowserProgressTypeProgress;
    self.drawView.hidden = NO;
    self.textLabel.hidden = YES;
    self.imageView.hidden = YES;
    [self stopImageViewAnimation];
    
    self.drawView.progress = progress;
    [self.drawView setNeedsDisplay];
}

- (void)show {
    self.userInteractionEnabled = NO;
    _type = YBImageBrowserProgressTypeLoad;
    self.drawView.hidden = YES;
    self.textLabel.hidden = YES;
    self.imageView.hidden = NO;
    
    [self startImageViewAnimation];
    [self.drawView setNeedsDisplay];
}

- (void)startImageViewAnimation {
    CABasicAnimation *ra = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    ra.toValue = [NSNumber numberWithFloat:M_PI * 2];
    ra.duration = 1;
    ra.cumulative = YES;
    ra.repeatCount = HUGE_VALF;
    ra.removedOnCompletion = NO;
    ra.fillMode = kCAFillModeForwards;
    [self.imageView.layer addAnimation:ra forKey:@"ra"];
}

- (void)stopImageViewAnimation {
    [self.imageView.layer removeAllAnimations];
}

- (void)showText:(NSString *)text click:(void (^)(void))click {
    self.userInteractionEnabled = click ? YES : NO;
    _type = YBImageBrowserProgressTypeText;
    self.drawView.hidden = YES;
    self.textLabel.hidden = NO;
    self.imageView.hidden = YES;
    [self stopImageViewAnimation];
    
    self.textLabel.text = text;
    self.clickTextLabelBlock = click;
    [self.drawView setNeedsDisplay];
}

#pragma mark - touch event

- (void)respondsToTapTextlabel {
    if (self.clickTextLabelBlock) {
        self.clickTextLabelBlock();
    }
}

#pragma mark - getter

- (YBIBProgressDrawView *)drawView {
    if (!_drawView) {
        _drawView = [YBIBProgressDrawView new];
        _drawView.backgroundColor = [UIColor clearColor];
    }
    return _drawView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.numberOfLines = 0;
        _textLabel.font = [UIFont systemFontOfSize:14];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapTextlabel)];
        [_textLabel addGestureRecognizer:tapGesture];
        _textLabel.userInteractionEnabled = YES;
    }
    return _textLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.image = [YBIBIconManager sharedManager].loadingImage();
        _imageView.layer.shadowColor = UIColor.darkGrayColor.CGColor;
        _imageView.layer.shadowOffset = CGSizeMake(0, 1);
        _imageView.layer.shadowOpacity = 1;
        _imageView.layer.shadowRadius = 4;
    }
    return _imageView;
}

@end
