//
//  YBImageBrowserDataSource.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBImageBrowserCellDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowserView;

@protocol YBImageBrowserDataSource <NSObject>

@required

- (NSUInteger)yb_numberOfCellForImageBrowserView:(YBImageBrowserView *)imageBrowserView;

- (id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
