//
//  YBImageBrowserModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserModel.h"

@implementation YBImageBrowserModel

#pragma mark setter
- (void)setImageName:(NSString *)imageName {
    if (!imageName) return;
    _imageName = imageName;
    _image = [UIImage imageNamed:imageName];
}
- (void)setGifName:(NSString *)gifName {
    if (!gifName) return;
    _gifName = gifName;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:gifName ofType:@"gif"];
    if (!filePath) return;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) return;
    _animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
}
- (void)setImageUrl:(NSString *)imageUrl {
    if (!imageUrl) return;
    _imageUrl = imageUrl;
    _url = [NSURL URLWithString:imageUrl];
}

@end
