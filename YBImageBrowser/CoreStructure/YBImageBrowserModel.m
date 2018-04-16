//
//  YBImageBrowserModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserModel.h"

NSString * const YBImageBrowserModel_KVCKey_isLoading = @"isLoading";
NSString * const YBImageBrowserModel_KVCKey_isLoadFailed = @"isLoadFailed";
char * const YBImageBrowserModel_SELName_download = "downloadImageProgress:success:failed:";

@interface YBImageBrowserModel () {
    BOOL isLoading;
    BOOL isLoadFailed;
    BOOL isLoadSuccess;
    __weak SDWebImageDownloadToken *downloadToken;
    YBImageBrowserDownloadProgressBlock progressBlock;
    YBImageBrowserDownloadSuccessBlock successBlock;
    YBImageBrowserDownloadFailedBlock failedBlock;
}

@end

@implementation YBImageBrowserModel

#pragma mark life cycle

- (void)dealloc {
    if (downloadToken) {
        [[SDWebImageDownloader sharedDownloader] cancel:downloadToken];
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

- (void)downloadImageProgress:(YBImageBrowserDownloadProgressBlock)progress success:(YBImageBrowserDownloadSuccessBlock)success failed:(YBImageBrowserDownloadFailedBlock)failed {
    
    YBImageBrowserModel *model = self;
    
    if (!model.url || isLoadSuccess) return;    //不用处理回调的情况
    
    progressBlock = progress;
    successBlock = success;
    failedBlock = failed;
    
    if (isLoading) return;      //仍然处理回调转接（主要是预下载与正式下载可能会同时请求）
    
    isLoading = YES;
    
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.url options:SDWebImageDownloaderLowPriority|SDWebImageDownloaderScaleDownLargeImages progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        if (progress) progress(model, receivedSize, expectedSize, targetURL);
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        isLoading = NO;
        
        if (error) {
            isLoadFailed = YES;
            if (failed) failed(model, error, finished);
            return;
        }
        
        isLoadFailed = NO;
        isLoadSuccess = YES;
        
        //缓存处理
        if ([YBImageBrowserUtilities isGif:data]) {
            model.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
            
            [[SDImageCache sharedImageCache] storeImage:image imageData:data forKey:model.url.absoluteString toDisk:YES completion:^{
                
                if ([[SDImageCache sharedImageCache] diskImageDataExistsWithKey:model.url.absoluteString]) {
                    NSLog(@"YES");
                }
                
                [[SDImageCache sharedImageCache] queryCacheOperationForKey:model.url.absoluteString options:SDImageCacheQueryDiskSync|SDImageCacheQueryDataWhenInMemory done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
                    
                }];
            }];
            
        } else {
            model.image = image;
            [[SDImageCache sharedImageCache] storeImage:image forKey:model.url.absoluteString completion:nil];
        }
        
        if (success) success(model, image, data, finished);
    }];
    
    downloadToken = token;
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
