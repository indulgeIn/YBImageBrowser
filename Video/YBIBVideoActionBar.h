//
//  YBIBVideoActionBar.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/11.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YBIBVideoActionBar;

@protocol YBIBVideoActionBarDelegate <NSObject>
@required

- (void)yb_videoActionBar:(YBIBVideoActionBar *)actionBar clickPlayButton:(UIButton *)playButton;

- (void)yb_videoActionBar:(YBIBVideoActionBar *)actionBar clickPauseButton:(UIButton *)pauseButton;

- (void)yb_videoActionBar:(YBIBVideoActionBar *)actionBar changeValue:(float)value;

@end

@interface YBIBVideoActionBar : UIView

@property (nonatomic, weak) id<YBIBVideoActionBarDelegate> delegate;

- (void)setMaxValue:(float)value;

- (void)setCurrentValue:(float)value;

- (void)pause;

- (void)play;

+ (CGFloat)defaultHeight;

@property (nonatomic, assign, readonly) BOOL isTouchInside;

@end

NS_ASSUME_NONNULL_END
