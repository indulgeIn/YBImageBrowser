//
//  YBVideoBrowseTopBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YBVideoBrowseTopBar;

@protocol YBVideoBrowseTopBarDelegate <NSObject>

- (void)yb_videoBrowseTopBar:(YBVideoBrowseTopBar *)topBar clickCancelButton:(UIButton *)button;

@end

@interface YBVideoBrowseTopBar : UIView

@property (nonatomic, weak) id<YBVideoBrowseTopBarDelegate> delegate;

- (CGRect)getFrameWithContainerSize:(CGSize)containerSize;

@end

NS_ASSUME_NONNULL_END
