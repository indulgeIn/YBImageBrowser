//
//  YBImageBrowserToolBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserScreenOrientationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowserToolBar;

@protocol YBImageBrowserToolBarDelegate <NSObject>

- (void)yBImageBrowserToolBar:(YBImageBrowserToolBar *)imageBrowserToolBar didClickRightButton:(UIButton *)button;

@end

@interface YBImageBrowserToolBar : UIView <YBImageBrowserScreenOrientationProtocol>

@property (nonatomic, weak) id <YBImageBrowserToolBarDelegate> delegate;

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIButton *rightButton;

- (void)setTitleLabelWithCurrentIndex:(NSUInteger)index totalCount:(NSUInteger)totalCount;

- (void)setRightButtonHide:(BOOL)hide;
- (void)setRightButtonImage:(nullable UIImage *)image;
- (void)setRightButtonTitle:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
