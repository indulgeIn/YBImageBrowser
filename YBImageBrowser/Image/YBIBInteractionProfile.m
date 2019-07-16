//
//  YBIBInteractionProfile.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/30.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBInteractionProfile.h"

@implementation YBIBInteractionProfile

- (instancetype)init {
    self = [super init];
    if (self) {
        _disable = NO;
        _dismissScale = 0.22;
        _dismissVelocityY = 800;
        _restoreDuration = 0.15;
        _triggerDistance = 3;
    }
    return self;
}

@end
