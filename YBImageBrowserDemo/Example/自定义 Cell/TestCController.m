//
//  TestCController.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestCController.h"
#import "YBImageBrowser.h"
#import "TestCustomData.h"

static NSString *kAdvertKey = @"广告位";

@interface TestCController () <YBImageBrowserDelegate>

@end

@implementation TestCController

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        NSMutableArray *array = [NSMutableArray array];
        [array addObjectsFromArray:[BaseFileManager imageURLs]];
        [array addObject:kAdvertKey];
        self.dataArray = array;
    }
    return self;
}

+ (NSString *)yb_title {
    return @"自定义 Cell";
}

#pragma mark - <YBImageBrowserDelegate>

- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser pageChanged:(NSInteger)page data:(id<YBIBDataProtocol>)data {
    // 当是自定义的 Cell 时，隐藏右边的操作按钮
    // 对于工具栏的处理自定义一个 id<YBIBToolViewHandler> 是最灵活的方式，默认实现很多时候可能满足不了需求
    imageBrowser.defaultToolViewHandler.topView.operationButton.hidden = [data isKindOfClass:TestCustomData.self];
}

#pragma mark - override

- (void)selectedIndex:(NSInteger)index {
    
    NSMutableArray *datas = [NSMutableArray array];
    [self.dataArray enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:kAdvertKey]) {
            
            // 自定义的广告 Cell
            TestCustomData *data = [TestCustomData new];
            data.text = @"这是一个广告";
            [datas addObject:data];
            
        } else {
            
            // 网络图片
            YBIBImageData *data = [YBIBImageData new];
            data.imageURL = [NSURL URLWithString:obj];
            data.projectiveView = [self viewAtIndex:idx];
            [datas addObject:data];
            
        }
    }];
    
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSourceArray = datas;
    browser.currentPage = index;
    browser.delegate = self;
    [browser show];
}

@end
