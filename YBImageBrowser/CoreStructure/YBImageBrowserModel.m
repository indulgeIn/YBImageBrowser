//
//  YBImageBrowserModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserModel.h"
#import "YBImageBrowserDownloader.h"

NSString * const YBImageBrowserModel_KVCKey_isLoading = @"isLoading";
NSString * const YBImageBrowserModel_KVCKey_isLoadFailed = @"isLoadFailed";
char * const YBImageBrowserModel_SELName_download = "downloadImageProgress:success:failed:";

@interface YBImageBrowserModel () {
    BOOL isLoading;
    BOOL isLoadFailed;
    BOOL isLoadSuccess;
    __weak id downloadToken;
    YBImageBrowserModelProgressBlock progressBlock;
    YBImageBrowserModelSuccessBlock successBlock;
    YBImageBrowserModelFailedBlock failedBlock;
}

@end

@implementation YBImageBrowserModel

#pragma mark life cycle

- (void)dealloc {
    if (downloadToken) {
        [YBImageBrowserDownloader cancelTaskWithDownloadToken:downloadToken];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        isLoading = NO;
        isLoadFailed = NO;
        isLoadSuccess = NO;
    }
    return self;
}

#pragma mark download

- (void)downloadImageProgress:(YBImageBrowserModelProgressBlock)progress success:(YBImageBrowserModelSuccessBlock)success failed:(YBImageBrowserModelFailedBlock)failed {
    
    YBImageBrowserModel *model = self;
    
    if (!model.url || isLoadSuccess) return;    //不用处理回调的情况
    
    progressBlock = progress;
    successBlock = success;
    failedBlock = failed;
    
    if (isLoading) return;      //仍然处理回调转接（预下载与正式下载可能会同时请求）
    
    isLoading = YES;
    
    downloadToken = [YBImageBrowserDownloader downloadWebImageWithUrl:model.url progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        if (self->progressBlock) self->progressBlock(model, receivedSize, expectedSize, targetURL);
        
    } success:^(UIImage * _Nullable image, NSData * _Nullable data, BOOL finished) {
        
        isLoading = NO;
        isLoadFailed = NO;
        isLoadSuccess = YES;
        
        //缓存处理
        if ([YBImageBrowserUtilities isGif:data]) {
            model.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
        } else {
            model.image = image;
        }
        [YBImageBrowserDownloader storeImageDataWithKey:model.url.absoluteString image:image data:data];
        
        if (self->successBlock) self->successBlock(model, image, data, finished);
        
    } failed:^(NSError * _Nullable error, BOOL finished) {
        
        isLoading = NO;
        isLoadFailed = YES;
        if (self->failedBlock) self->failedBlock(model, error, finished);
        
    }];
    
}


#pragma mark public

- (void)setImageWithFileName:(NSString *)fileName fileType:(NSString *)type {
    _image = YB_READIMAGE_FROMFILE(fileName, type);
}

- (void)setUrlWithDownloadInAdvance:(NSURL *)url {
    _url = url;
    [self downloadImageProgress:nil success:nil failed:nil];
}

#pragma mark setter

- (void)setGifName:(NSString *)gifName {
    if (!gifName) return;
    _gifName = gifName;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:gifName ofType:@"gif"];
    if (!filePath) return;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) return;
    _animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
}

@end
