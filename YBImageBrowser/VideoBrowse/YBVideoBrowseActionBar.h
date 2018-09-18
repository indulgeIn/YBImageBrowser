//
//  YBVideoBrowseActionBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/28.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YBVideoBrowseActionBar;

@protocol YBVideoBrowseActionBarDelegate <NSObject>

- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar clickPlayButton:(UIButton *)playButton;
- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar clickPauseButton:(UIButton *)pauseButton;
- (void)yb_videoBrowseActionBar:(YBVideoBrowseActionBar *)actionBar changeValue:(float)value;

@end

@interface YBVideoBrowseActionBar : UIView

@property (nonatomic, weak) id<YBVideoBrowseActionBarDelegate> delegate;

- (CGRect)getFrameWithContainerSize:(CGSize)containerSize;

- (void)pause;
- (void)play;

- (void)setMaxValue:(float)value;
- (void)setCurrentValue:(float)value;

@end

NS_ASSUME_NONNULL_END
