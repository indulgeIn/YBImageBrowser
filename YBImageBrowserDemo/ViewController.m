//
//  ViewController.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "ViewController.h"
#import "YBImageBrowser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
- (IBAction)clickShowButton:(id)sender {
    
    YBImageBrowser *browser = [YBImageBrowser new];
    
    YBImageBrowserModel *model0 = [YBImageBrowserModel new];
    model0.url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523386869420&di=015d95da30b54296e10cb63ee740d8d9&imgtype=0&src=http%3A%2F%2Fimg.zcool.cn%2Fcommunity%2F01c6e25889bd4ca8012060c80f8067.gif"];
    YBImageBrowserModel *model1 = [YBImageBrowserModel new];
    model1.url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523382489676&di=bcd55b2dd64141ced8c52b46309280da&imgtype=0&src=http%3A%2F%2Ff2.topitme.com%2F2%2Fb9%2F71%2F112660598401871b92l.jpg"];
    YBImageBrowserModel *model2 = [YBImageBrowserModel new];
    model2.url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523382505091&di=99b87c6efef2923946bd65989088515a&imgtype=0&src=http%3A%2F%2Ffb.topitme.com%2Fb%2Fde%2F53%2F112941542258053debo.jpg"];
    YBImageBrowserModel *model4 = [YBImageBrowserModel new];
    model4.image = [UIImage imageNamed:@"image0"];
    YBImageBrowserModel *model5 = [YBImageBrowserModel new];
    model5.image = [UIImage imageNamed:@"image1"];
    YBImageBrowserModel *model6 = [YBImageBrowserModel new];
    model6.image = [UIImage imageNamed:@"gif0.gif"];
    
    browser.dataArray = @[model0, model1, model2, model4, model5, model6];
    [browser show];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [browser hide];
    });
}

@end
