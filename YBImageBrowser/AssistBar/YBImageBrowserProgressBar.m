//
//  YBImageBrowserProgressBar.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserProgressBar.h"
#import <CoreText/CoreText.h>

@interface YBImageBrowserProgressBar () {
    UIColor *bottomPathColor;
    UIColor *activePathColor;
    CGFloat radius;
    CGFloat strokeWidth;
    NSDictionary *textAttributes;
    NSAttributedString *loadFailedAttr;
    BOOL isLoadFailed;
}
@end

@implementation YBImageBrowserProgressBar

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        self.userInteractionEnabled = NO;
        bottomPathColor = [UIColor lightGrayColor];
        activePathColor = [UIColor whiteColor];
        radius = 17;
        strokeWidth = 3;
        textAttributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:10], NSForegroundColorAttributeName:[UIColor whiteColor]};
        isLoadFailed = NO;
    }
    return self;
}

#pragma mark public

- (void)showWithText:(NSString *)text {
    isLoadFailed = YES;
    loadFailedAttr = [[NSMutableAttributedString alloc] initWithString:text?:@"图片加载失败了" attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:15], NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [self setNeedsDisplay];
}

#pragma mark setter

- (void)setProgress:(CGFloat)progress {
    _progress = progress ?: 0;
    isLoadFailed = NO;
    [self setNeedsDisplay];
}

#pragma mark drawRect

- (void)drawRect:(CGRect)rect {
    
    if (isLoadFailed) {
        [self showText];
        return;
    }
    [self showPregress];
}

- (void)showPregress {
    
    CGPoint selfCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    [bottomPathColor setStroke];
    UIBezierPath *bottomPath = [UIBezierPath bezierPathWithArcCenter:selfCenter radius:radius startAngle:0 endAngle:M_PI*2 clockwise:YES];
    bottomPath.lineWidth = 4.0;
    bottomPath.lineCapStyle = kCGLineCapRound;
    bottomPath.lineJoinStyle = kCGLineCapRound;
    [bottomPath stroke];
    
    [activePathColor setStroke];
    UIBezierPath *activePath = [UIBezierPath bezierPathWithArcCenter:selfCenter radius:radius startAngle:-M_PI/2.0 endAngle:M_PI*2*_progress-M_PI/2.0 clockwise:true];
    activePath.lineWidth = strokeWidth;
    activePath.lineCapStyle = kCGLineCapRound;
    activePath.lineJoinStyle = kCGLineCapRound;
    [activePath stroke];
    
    NSString *string = [NSString stringWithFormat:@"%.0lf%@", _progress*100, @"%"];
    NSMutableAttributedString *atts = [[NSMutableAttributedString alloc] initWithString:string attributes:textAttributes] ;
    CGSize size = atts.size;
    [atts drawAtPoint:CGPointMake(selfCenter.x-size.width/2.0, selfCenter.y-size.height/2.0)];
}

- (void)showText {
    CGPoint selfCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGSize size = loadFailedAttr.size;
    [loadFailedAttr drawAtPoint:CGPointMake(selfCenter.x-size.width/2.0, selfCenter.y-size.height/2.0)];
}

@end
