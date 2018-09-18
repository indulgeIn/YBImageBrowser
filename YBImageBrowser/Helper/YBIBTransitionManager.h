//
//  YBIBTransitionManager.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/4.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowser.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBIBTransitionManager : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) YBImageBrowser *imageBrowser;

@property (nonatomic, assign, readonly) BOOL isTransitioning;

@end

NS_ASSUME_NONNULL_END
