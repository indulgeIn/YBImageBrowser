//
//  TestCustomData.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestCustomData.h"
#import "TestCustomCell.h"

@implementation TestCustomData

#pragma mark - <YBIBDataProtocol>

- (Class)yb_classOfCell {
    return TestCustomCell.self;
}

@end
