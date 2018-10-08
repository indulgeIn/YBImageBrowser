//
//  YBIBGestureInteractionProfile.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBGestureInteractionProfile.h"

@implementation YBIBGestureInteractionProfile

- (instancetype)init {
    self = [super init];
    if (self) {
        self.disable = NO;
        self.dismissScale = 0.22;
        self.dismissVelocityY = 800;
        self.restoreDuration = 0.15;
        self.triggerDistance = 3;
    }
    return self;
}

@end
