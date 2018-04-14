//
//  YBImageBrowserModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserModel.h"

NSString * const YBImageBrowser_KVCKey_needUpdateUI = @"needUpdateUI";
NSString * const YBImageBrowser_KVCKey_isLoading = @"isLoading";
NSString * const YBImageBrowser_KVCKey_isLoadFailed = @"isLoadFailed";

@interface YBImageBrowserModel () {
    BOOL needUpdateUI;
    BOOL isLoading;
    BOOL isLoadFailed;
}

@end

@implementation YBImageBrowserModel

#pragma mark life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        needUpdateUI = NO;
        isLoading = NO;
        isLoadFailed = NO;
    }
    return self;
}

#pragma mark public

- (void)setImageWithFileName:(NSString *)fileName fileType:(NSString *)type {
    _image = YB_READIMAGE_FROMFILE(fileName, type);
}

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
