//
//  YBImageBrowserModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserModel.h"
#import "YBImageBrowserDownloader.h"
#import "YBImageBrowser.h"

NSString * const YBImageBrowserModel_KVCKey_isLoading = @"isLoading";
NSString * const YBImageBrowserModel_KVCKey_isLoadFailed = @"isLoadFailed";
NSString * const YBImageBrowserModel_KVCKey_largeImage = @"largeImage";
char * const YBImageBrowserModel_SELName_download = "downloadImageProgress:success:failed:";
char * const YBImageBrowserModel_SELName_scaleImage = "scaleImageWithCurrentImageFrame:complete:";
char * const YBImageBrowserModel_SELName_cutImage = "cutImageWithTargetRect:complete:";

@interface YBImageBrowserModel () {
    BOOL isLoading;
    BOOL isLoadFailed;
    BOOL isLoadSuccess;
    __weak id downloadToken;
    UIImage *largeImage;    //存储需要压缩的高清图
    YBImageBrowserModelDownloadProgressBlock progressBlock;
    YBImageBrowserModelDownloadSuccessBlock successBlock;
    YBImageBrowserModelDownloadFailedBlock failedBlock;
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
        _maximumZoomScale = 4;
        _needCutToShow = NO;
    }
    return self;
}

#pragma mark download

//下载图片
- (void)downloadImageProgress:(YBImageBrowserModelDownloadProgressBlock)progress success:(YBImageBrowserModelDownloadSuccessBlock)success failed:(YBImageBrowserModelDownloadFailedBlock)failed {
    
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
        //该判断是为了防止图片加载框架的BUG影响内部逻辑
        if (!model.animatedImage && !model.image) {
            isLoading = NO;
            isLoadFailed = YES;
            if (self->failedBlock) self->failedBlock(model, nil, finished);
        }
        [YBImageBrowserDownloader storeImageDataWithKey:model.url.absoluteString image:image data:data];
        
        if (self->successBlock) self->successBlock(model, image, data, finished);
        
    } failed:^(NSError * _Nullable error, BOOL finished) {
        
        isLoading = NO;
        isLoadFailed = YES;
        if (self->failedBlock) self->failedBlock(model, error, finished);
        
    }];
}

#pragma mark scale and cut

//压缩图片
- (void)scaleImageWithCurrentImageFrame:(CGRect)imageFrame complete:(YBImageBrowserModelScaleImageSuccessBlock)complete {
    YBImageBrowserModel *model = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        model.image = [YBImageBrowserUtilities scaleToSizeWithImage:largeImage size:imageFrame.size];
        if (complete) {
            YB_MAINTHREAD_ASYNC(^{
                complete(model);
            })
        }
    });
}

//裁剪图片
- (void)cutImageWithTargetRect:(CGRect)targetRect complete:(YBImageBrowserModelCutImageSuccessBlock)complete {
    YBImageBrowserModel *model = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *resultImage = [YBImageBrowserUtilities cutToRectWithImage:largeImage rect:targetRect];
        if (complete) {
            YB_MAINTHREAD_ASYNC(^{
                complete(model, resultImage);
            })
        }
    });
}

#pragma mark public

- (void)setImageWithFileName:(NSString *)fileName fileType:(NSString *)type {
    self.image = YB_READIMAGE_FROMFILE(fileName, type);
}

- (void)setUrlWithDownloadInAdvance:(NSURL *)url {
    _url = url;
    [self downloadImageProgress:nil success:nil failed:nil];
}

#pragma mark setter

- (void)setImage:(UIImage *)image {
    if (image.size.width * image.scale > YBImageBrowser.maxDisplaySize) {
        self.needCutToShow = YES;
        largeImage = image;
    } else {
        _image = image;
    }
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

@end
