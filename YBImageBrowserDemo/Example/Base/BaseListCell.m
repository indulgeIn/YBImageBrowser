//
//  BaseListCell.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "BaseListCell.h"
#import <Photos/Photos.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "YBIBIconManager.h"
#import <libkern/OSAtomic.h>

@interface BaseListCell ()
@property (weak, nonatomic) IBOutlet UIImageView *coverImgView;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@end

@implementation BaseListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.typeLabel.layer.cornerRadius = 3;
    self.typeLabel.layer.masksToBounds = YES;
}

- (void)setData:(id)data {
    _data = data;
    self.contentImgView.image = nil;
    self.coverImgView.image = nil;
    self.typeLabel.text = nil;
    self.textLabel.text = nil;
    
    // 测试用途，请忽略不严谨逻辑
    
    CGFloat padding = 5, imageViewLength = ([UIScreen mainScreen].bounds.size.width - padding * 2) / 3 - 10, scale = [UIScreen mainScreen].scale;
    CGSize imageViewSize = CGSizeMake(imageViewLength * scale, imageViewLength * scale);
    
    if ([data isKindOfClass:PHAsset.class]) {
        
        PHAsset *phAsset = (PHAsset *)data;
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.synchronous = NO;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:CGSizeMake(250, 250) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info){
            BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
            if (downloadFinined && result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.data == data) self.contentImgView.image = result;
                });
            }
        }];
        
        if (phAsset.mediaType == PHAssetMediaTypeVideo) {
            self.coverImgView.hidden = NO;
            self.typeLabel.hidden = YES;
            self.coverImgView.image = [YBIBIconManager sharedManager].videoBigPlayImage();
        } else {
            self.coverImgView.hidden = YES;
            self.typeLabel.hidden = YES;
        }
        
    } else if ([data isKindOfClass:NSString.class]) {
        
        NSString *imageStr = (NSString *)data;
        __block BOOL isBigImage = NO, isLongImage = NO;
        
        if ([imageStr hasSuffix:@".mp4"]) {
            
            AVURLAsset *avAsset = nil;
            if ([imageStr hasPrefix:@"http"]) {
                avAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:imageStr]];
            } else {
                NSString *path = [[NSBundle mainBundle] pathForResource:imageStr.stringByDeletingPathExtension ofType:imageStr.pathExtension];
                avAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
            }
            
            if (avAsset) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avAsset];
                    generator.appliesPreferredTrackTransform = YES;
                    generator.maximumSize = imageViewSize;
                    NSError *error = nil;
                    CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:NULL error:&error];
                    UIImage *resultImg = [UIImage imageWithCGImage:cgImage];
                    if (cgImage) CGImageRelease(cgImage);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.data == data) self.contentImgView.image = resultImg;
                    });
                });
            }
            
        } else if ([imageStr hasPrefix:@"http"]) {
            
            [self.contentImgView sd_setImageWithURL:[NSURL URLWithString:imageStr] placeholderImage:nil options:SDWebImageDecodeFirstFrameOnly];
            
        } else if (imageStr.pathExtension.length > 0) {
            
            NSString *type = imageStr.pathExtension;
            NSString *resource = imageStr.stringByDeletingPathExtension;
            NSString *filePath = [[NSBundle mainBundle] pathForResource:resource ofType:type];
            NSData *nsData = [NSData dataWithContentsOfFile:filePath];
            UIImage *image = [UIImage imageWithData:nsData];
            
            static CGFloat kMaxPixel = 4096.0;
            if (image.size.width * image.scale * image.size.height * image.scale > kMaxPixel * kMaxPixel) {
                isBigImage = YES;
            } else if (image.size.width * image.scale > kMaxPixel || image.size.height * image.scale > kMaxPixel) {
                isLongImage = YES;
            }
            
            if (isBigImage) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    CGSize size = CGSizeMake(imageViewSize.width, image.size.height / image.size.width * imageViewSize.width);
                    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
                    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
                    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.data == data) self.contentImgView.image = scaledImage;
                    });
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.data == data) self.contentImgView.image = image;
                });
            }
        } else {
            self.textLabel.text = imageStr;
        }
        
        if ([imageStr hasSuffix:@".mp4"]) {
            self.coverImgView.hidden = NO;
            self.typeLabel.hidden = YES;
            self.coverImgView.image = [YBIBIconManager sharedManager].videoBigPlayImage();
        } else if ([imageStr hasSuffix:@".gif"]) {
            self.coverImgView.hidden = YES;
            self.typeLabel.hidden = NO;
            self.typeLabel.text = @" GIF ";
        } else if (isBigImage) {
            self.coverImgView.hidden = YES;
            self.typeLabel.hidden = NO;
            self.typeLabel.text = @" 高清图 ";
        } else if (isLongImage) {
            self.coverImgView.hidden = YES;
            self.typeLabel.hidden = NO;
            self.typeLabel.text = @" 长图 ";
        } else {
            self.coverImgView.hidden = YES;
            self.typeLabel.hidden = YES;
        }
    }
}

@end
