//
//  TestBController.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestBController.h"
#import "YBImageBrowser.h"
#import "TestToolViewHandler.h"

@interface TestBController ()

@end

@implementation TestBController

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dataArray = [BaseFileManager imageURLs];
    }
    return self;
}

+ (NSString *)yb_title {
    return @"自定义工具视图（例查看原图）";
}

#pragma mark - override

- (void)selectedIndex:(NSInteger)index {
    
    NSMutableArray *datas = [NSMutableArray array];
    [self.dataArray enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YBIBImageData *data = [YBIBImageData new];
        data.imageURL = [NSURL URLWithString:obj];
        data.projectiveView = [self viewAtIndex:idx];
        // 这里放的是原图地址（实际业务中请按需关联）
        data.extraData = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1563259169388&di=80094a1dbee952cad67b72b0037eb2fc&imgtype=0&src=http%3A%2F%2F5b0988e595225.cdn.sohucs.com%2Fimages%2F20180313%2F49da94b727b54762947d625ba5f92196.jpeg"];
        [datas addObject:data];
        
    }];
    
    YBImageBrowser *browser = [YBImageBrowser new];
    // 自定义工具栏
    browser.toolViewHandlers = @[TestToolViewHandler.new];
    browser.dataSourceArray = datas;
    browser.currentPage = index;
    [browser show];
}

@end
