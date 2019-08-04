//
//  TestEController.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestEController.h"
#import "TestImageBrowser.h"
#import "YBIBPhotoAlbumManager.h"

@interface TestEController ()

@end

@implementation TestEController

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [YBIBPhotoAlbumManager getPhotoAlbumAuthorizationSuccess:^{
            self.dataArray = [BaseFileManager imagePHAssets];
        } failed:^{}];
    }
    return self;
}

+ (NSString *)yb_title {
    return @"添加到控制器使用（以相册为例）";
}

#pragma mark - override

- (void)selectedIndex:(NSInteger)index {
    
    //使用控制器保证的图片浏览器
    TestImageBrowser *browser = [TestImageBrowser new];
    browser.imagePHAssets = self.dataArray;
    browser.selectIndex = index;
    [self.navigationController pushViewController:browser animated:YES];
    
}

@end
