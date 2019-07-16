//
//  YBImageBrowser+Internal.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/1.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBIBContainerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBImageBrowser ()

@property (nonatomic, strong) YBIBContainerView *containerView;

- (void)implementGetBaseInfoProtocol:(id<YBIBGetBaseInfoProtocol>)obj;

@property (nonatomic, weak, nullable) id hiddenProjectiveView;

@end

NS_ASSUME_NONNULL_END
