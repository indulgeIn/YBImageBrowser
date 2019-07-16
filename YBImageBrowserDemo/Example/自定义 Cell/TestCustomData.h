//
//  TestCustomData.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBIBDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface TestCustomData : NSObject <YBIBDataProtocol>

@property (nonatomic, copy) NSString *text;

@end

NS_ASSUME_NONNULL_END
