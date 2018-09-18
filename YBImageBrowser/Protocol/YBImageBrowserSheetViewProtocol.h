//
//  YBImageBrowserSheetViewProtocol.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBImageBrowserCellDataProtocol.h"
#import "YBIBLayoutDirectionManager.h"

@protocol YBImageBrowserSheetViewProtocol <NSObject>

@required

- (void)yb_browserShowSheetViewWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize;

- (void)yb_browserHideSheetViewWithAnimation:(BOOL)animation;

- (NSInteger)yb_browserActionsCount;

@end
