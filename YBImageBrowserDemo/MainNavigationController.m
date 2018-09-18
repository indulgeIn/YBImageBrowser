//
//  MainNavigationController.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/17.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "MainNavigationController.h"

@interface MainNavigationController ()

@end

@implementation MainNavigationController

- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

@end
