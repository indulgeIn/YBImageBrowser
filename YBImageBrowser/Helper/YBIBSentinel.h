//
//  YBIBSentinel.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/18.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Thread safe.
 */
@interface YBIBSentinel : NSObject

/// Returns the current value of the counter.
@property (readonly) int32_t value;

/**
 Increase the value atomically.
 @return The new value.
 */
- (int32_t)increase;

@end

NS_ASSUME_NONNULL_END
