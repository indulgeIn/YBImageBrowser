//
//  YBImageBrowser.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"


@interface YBImageBrowser : UIView

/**
 数据源（只赋值一次，试图更换数据源请另开辟内存）
 */
@property (nonatomic, strong) NSArray<YBImageBrowserModel *> *dataArray;

/**
 展示
 */
- (void)show;
- (void)showToView:(UIView *)view;

/**
 隐藏
 */
- (void)hide;


@end
