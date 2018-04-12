//
//  YBImageBrowserTestVC.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"

@interface YBImageBrowserTestVC : UIViewController

/**
 数据源（只赋值一次，试图更换数据源请另开辟内存）
 */
@property (nonatomic, strong) NSArray<YBImageBrowserModel *> *dataArray;

/**
 展示
 */
- (void)show;

/**
 隐藏
 */
- (void)hide;

@end
