//
//  YBIBCellProtocol.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/5.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBGetBaseInfoProtocol.h"
#import "YBIBOrientationReceiveProtocol.h"
#import "YBIBOperateBrowserProtocol.h"

@protocol YBIBDataProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol YBIBCellProtocol <YBIBGetBaseInfoProtocol, YBIBOperateBrowserProtocol, YBIBOrientationReceiveProtocol>

@required

/// Cell 对应的 Data
@property (nonatomic, strong) id<YBIBDataProtocol> yb_cellData;

@optional

/**
 获取前景视图，出入场时需要用这个返回值做动效

 @return 前景视图
 */
- (__kindof UIView *)yb_foregroundView;

/**
 页码变化了
 */
- (void)yb_pageChanged;

/// 当前 Cell 的页码
@property (nonatomic, copy) NSInteger(^yb_selfPage)(void);

@end

NS_ASSUME_NONNULL_END
