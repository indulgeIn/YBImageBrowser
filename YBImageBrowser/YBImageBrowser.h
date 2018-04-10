//
//  YBImageBrowser.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserModel.h"

@interface YBImageBrowser : UIView

@property (nonatomic, strong) NSArray<YBImageBrowserModel *> *dataArray;

- (void)show;
- (void)showToView:(UIView *)view;

- (void)hide;

@end
