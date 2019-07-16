//
//  YBIBDataMediator.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/6.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBDataMediator.h"
#import "YBImageBrowser+Internal.h"

@implementation YBIBDataMediator {
    __weak YBImageBrowser *_browser;
    NSCache<NSNumber *, id<YBIBDataProtocol>> *_dataCache;
}

#pragma mark - life cycle

- (instancetype)initWithBrowser:(YBImageBrowser *)browser {
    if (self = [super init]) {
        _browser = browser;
        _dataCache = [NSCache new];
    }
    return self;
}

#pragma mark - public

- (NSInteger)numberOfCells {
    return _browser.dataSource ? [_browser.dataSource yb_numberOfCellsInImageBrowser:_browser] : _browser.dataSourceArray.count;
}

- (id<YBIBDataProtocol>)dataForCellAtIndex:(NSInteger)index {
    if (index < 0 || index > self.numberOfCells - 1) return nil;
    
    id<YBIBDataProtocol> data = [_dataCache objectForKey:@(index)];
    if (!data) {
        data = _browser.dataSource ? [_browser.dataSource yb_imageBrowser:_browser dataForCellAtIndex:index] : _browser.dataSourceArray[index];
        [_dataCache setObject:data forKey:@(index)];
        [_browser implementGetBaseInfoProtocol:data];
    }
    return data;
}

- (void)clear {
    [_dataCache removeAllObjects];
}

- (void)preloadWithPage:(NSInteger)page {
    if (_preloadCount == 0) return;
    
    NSInteger left = -(_preloadCount / 2), right = _preloadCount - ABS(left);
    for (NSInteger i = left; i <= right; ++i) {
        if (i == 0) continue;
        id<YBIBDataProtocol> targetData = [self dataForCellAtIndex:page + i];
        if ([targetData respondsToSelector:@selector(yb_preload)]) {
            [targetData yb_preload];
        }
    }
}

#pragma mark - getters & setters

- (void)setDataCacheCountLimit:(NSUInteger)dataCacheCountLimit {
    _dataCacheCountLimit = dataCacheCountLimit;
    _dataCache.countLimit = dataCacheCountLimit;
}

@end
