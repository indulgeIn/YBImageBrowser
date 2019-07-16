//
//  MainNavigationController.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/9/17.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "MainNavigationController.h"

@implementation MainNavigationController

- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}
 
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return [self.topViewController supportedInterfaceOrientations];
    return UIInterfaceOrientationMaskPortrait;
}

@end
