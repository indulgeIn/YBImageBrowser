//
//  YBIBDataMediator.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/6.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBImageBrowser.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBIBDataMediator : NSObject

- (instancetype)initWithBrowser:(YBImageBrowser *)browser;

@property (nonatomic, assign) NSUInteger dataCacheCountLimit;

- (NSInteger)numberOfCells;

- (id<YBIBDataProtocol>)dataForCellAtIndex:(NSInteger)index;

- (void)clear;

@property (nonatomic, assign) NSUInteger preloadCount;

- (void)preloadWithPage:(NSInteger)page;

@end

NS_ASSUME_NONNULL_END
