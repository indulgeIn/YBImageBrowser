//
//  YBImageBrowserToolBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"

@class YBImageBrowserToolBar;

@protocol YBImageBrowserToolBarDelegate <NSObject>

- (void)yBImageBrowserToolBar:(YBImageBrowserToolBar *)imageBrowserToolBar didClickRightButton:(UIButton *)button;

@end

@interface YBImageBrowserToolBar : UIView

@property (nonatomic, weak) id <YBImageBrowserToolBarDelegate> delegate;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *rightButton;

- (void)resetUserInterfaceLayout;

- (void)setTitleLabelWithCurrentIndex:(NSUInteger)index totalCount:(NSUInteger)totalCount;

@end
