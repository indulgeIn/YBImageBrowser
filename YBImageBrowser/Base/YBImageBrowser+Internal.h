//
//  YBImageBrowser+Internal.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/7.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBImageBrowserView.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBImageBrowser ()

@property (nonatomic, strong) YBImageBrowserView *browserView;

@property (nonatomic, weak, nullable) id hiddenSourceObject;

@end

NS_ASSUME_NONNULL_END
