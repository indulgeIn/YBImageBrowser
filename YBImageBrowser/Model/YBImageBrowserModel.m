//
//  YBImageBrowserModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserModel.h"

NSString * const YBImageBrowser_KVCKey_image = @"image";
NSString * const YBImageBrowser_KVCKey_url = @"url";
NSString * const YBImageBrowser_KVCKey_animatedImage = @"animatedImage";
NSString * const YBImageBrowser_KVCKey_needUpdateUI = @"needUpdateUI";

@interface YBImageBrowserModel () {
    UIImage *image;
    NSURL *url;
    FLAnimatedImage *animatedImage;
    BOOL needUpdateUI;
}

@end

@implementation YBImageBrowserModel

#pragma mark life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        needUpdateUI = NO;
    }
    return self;
}

#pragma mark setter

- (void)setImageName:(NSString *)imageName {
    if (!imageName) return;
    _imageName = imageName;
    image = [UIImage imageNamed:imageName];
}

- (void)setGifName:(NSString *)gifName {
    if (!gifName) return;
    _gifName = gifName;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:gifName ofType:@"gif"];
    if (!filePath) return;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) return;
    animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
}

- (void)setImageUrl:(NSString *)imageUrl {
    if (!imageUrl) return;
    _imageUrl = imageUrl;
    url = [NSURL URLWithString:imageUrl];
}

@end
