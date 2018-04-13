//
//  ViewController.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "ViewController.h"
#import "YBImageBrowser.h"
#import "YBImageBrowserTool.h"
#import "YBImageBrowserProgressBar.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)clickShowButton:(id)sender {
    
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.yb_supportedInterfaceOrientations = UIInterfaceOrientationMaskAllButUpsideDown;
    
    YBImageBrowserModel *model7 = [YBImageBrowserModel new];
    model7.imageName = @"imageLong";
    YBImageBrowserModel *model0 = [YBImageBrowserModel new];
    model0.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523386869420&di=015d95da30b54296e10cb63ee740d8d9&imgtype=0&src=http%3A%2F%2Fimg.zcool.cn%2Fcommunity%2F01c6e25889bd4ca8012060c80f8067.gif";
    YBImageBrowserModel *model1 = [YBImageBrowserModel new];
    model1.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523382489676&di=bcd55b2dd64141ced8c52b46309280da&imgtype=0&src=http%3A%2F%2Ff2.topitme.com%2F2%2Fb9%2F71%2F112660598401871b92l.jpg";
    YBImageBrowserModel *model2 = [YBImageBrowserModel new];
    model2.imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1523382505091&di=99b87c6efef2923946bd65989088515a&imgtype=0&src=http%3A%2F%2Ffb.topitme.com%2Fb%2Fde%2F53%2F112941542258053debo.jpg";
    YBImageBrowserModel *model4 = [YBImageBrowserModel new];
    model4.imageName = @"image0";
    YBImageBrowserModel *model5 = [YBImageBrowserModel new];
    model5.imageName = @"image1";
    YBImageBrowserModel *model6 = [YBImageBrowserModel new];
    model6.gifName = @"gif0";
    
    browser.dataArray = @[model7, model0, model1, model2, model4, model5, model6];

    [browser show];
    
    
}

- (IBAction)clickClearButton:(id)sender {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
}


@end
