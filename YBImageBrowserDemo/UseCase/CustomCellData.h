//
//  CustomCellData.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/26.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBImageBrowserCellDataProtocol.h"

@interface CustomCellData : NSObject <YBImageBrowserCellDataProtocol>

@property (nonatomic, copy) NSString *text;

@end
