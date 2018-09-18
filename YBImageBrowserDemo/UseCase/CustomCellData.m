//
//  CustomCellData.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/26.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "CustomCellData.h"
#import "CustomCell.h"

@interface CustomCellData () 
@end

@implementation CustomCellData

#pragma mark - <YBImageBrowserCellDataProtocol>

// required method

- (Class)yb_classOfBrowserCell {
    return CustomCell.class;
}

// optional method

- (BOOL)yb_browserAllowShowSheetView {
    return NO;
}

@end
