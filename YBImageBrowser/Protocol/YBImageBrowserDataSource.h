//
//  YBImageBrowserDataSource.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/8/25.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "YBIBDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class YBImageBrowser;

@protocol YBImageBrowserDataSource <NSObject>

@required

/**
 返回数据源数量

 @param imageBrowser 图片浏览器
 @return 数量
 */
- (NSInteger)yb_numberOfCellsInImageBrowser:(YBImageBrowser *)imageBrowser;

/**
 返回当前下标对应的数据

 @param imageBrowser 图片浏览器
 @param index 当前下标
 @return 数据
 */
- (id<YBIBDataProtocol>)yb_imageBrowser:(YBImageBrowser *)imageBrowser dataForCellAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
