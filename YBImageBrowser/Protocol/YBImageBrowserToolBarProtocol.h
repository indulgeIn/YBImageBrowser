//
//  YBImageBrowserToolBarProtocol.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBIBLayoutDirectionManager.h"
#import "YBImageBrowserCellDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YBImageBrowserToolBarProtocol <NSObject>

@required

- (void)yb_browserUpdateLayoutWithDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize;

@optional

- (void)yb_browserPageIndexChanged:(NSUInteger)pageIndex totalPage:(NSUInteger)totalPage data:(id<YBImageBrowserCellDataProtocol>)data;

@property (nonatomic, copy) void(^yb_browserShowSheetViewBlock)(id<YBImageBrowserCellDataProtocol> data);

@end

NS_ASSUME_NONNULL_END
