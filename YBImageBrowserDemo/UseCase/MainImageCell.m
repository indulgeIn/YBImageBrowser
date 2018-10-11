//
//  MainImageCell.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "MainImageCell.h"
#import <Photos/Photos.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "YBIBFileManager.h"
#import <libkern/OSAtomic.h>


static CGFloat kMaxPixel = 4096.0;

@interface MainImageCell ()
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (weak, nonatomic) IBOutlet UIImageView *auxiliaryImageView;
@property (weak, nonatomic) IBOutlet UILabel *auxiliaryLabel;
@end

@implementation MainImageCell

#pragma mark - life cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    self.auxiliaryLabel.layer.cornerRadius = 2;
    self.auxiliaryLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
    self.auxiliaryLabel.layer.masksToBounds = YES;
    self.mainImageView.layer.masksToBounds = YES;
}

#pragma mark - setter

- (void)setData:(id)data {
    _data = data;
    
    self.mainImageView.image = nil;
    
    CGFloat padding = 5, imageViewLength = ([UIScreen mainScreen].bounds.size.width - padding * 2) / 3 - 10, scale = [UIScreen mainScreen].scale;
    CGSize imageViewSize = CGSizeMake(imageViewLength * scale, imageViewLength * scale);
    
    if ([data isKindOfClass:PHAsset.class]) {

        PHAsset *phAsset = (PHAsset *)data;
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.synchronous = NO;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info){
            BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
            if (downloadFinined && result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.data == data) self.mainImageView.image = result;
                });
            }
        }];
        
        if (phAsset.mediaType == PHAssetMediaTypeVideo) {
            self.auxiliaryImageView.hidden = NO;
            self.auxiliaryLabel.hidden = YES;
            self.auxiliaryImageView.image = [YBIBFileManager getImageWithName:@"ybib_bigPlay"];
        } else {
            self.auxiliaryImageView.hidden = YES;
            self.auxiliaryLabel.hidden = YES;
        }
        
    } else if ([data isKindOfClass:NSString.class]) {
        
        NSString *imageStr = (NSString *)data;
        __block BOOL isBigImage = NO, isLongImage = NO;
        
        if ([imageStr hasSuffix:@".MP4"]) {
            
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.data == data) self.mainImageView.image = [UIImage imageWithCGImage:cgImage];
                    });
                });
            }
            
        } else if ([imageStr hasPrefix:@"http"]) {
            
            [self.mainImageView sd_setImageWithURL:[NSURL URLWithString:imageStr]];

        } else {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *type = imageStr.pathExtension;
                NSString *resource = imageStr.stringByDeletingPathExtension;
                NSString *filePath = [[NSBundle mainBundle] pathForResource:resource ofType:type];
                NSData *nsData = [NSData dataWithContentsOfFile:filePath];
                UIImage *image = [UIImage imageWithData:nsData];
                
                if (image.size.width * image.scale * image.size.height * image.scale > kMaxPixel * kMaxPixel) isBigImage = YES;
                if (image.size.width * image.scale > kMaxPixel || image.size.height * image.scale > kMaxPixel) isLongImage = YES;
                
                if (isBigImage) {
                    CGSize size = CGSizeMake(imageViewSize.width, image.size.height / image.size.width * imageViewSize.width);
                    UIGraphicsBeginImageContext(size);
                    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
                    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.data == data) self.mainImageView.image = scaledImage;
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.data == data) self.mainImageView.image = image;
                    });
                }
            });
        }
        
        if ([imageStr hasSuffix:@".MP4"]) {
            self.auxiliaryImageView.hidden = NO;
            self.auxiliaryLabel.hidden = YES;
            self.auxiliaryImageView.image = [YBIBFileManager getImageWithName:@"ybib_bigPlay"];
        } else if ([imageStr hasSuffix:@".gif"]) {
            self.auxiliaryImageView.hidden = YES;
            self.auxiliaryLabel.hidden = NO;
            self.auxiliaryLabel.text = @" GIF ";
        } else if (isBigImage) {
            self.auxiliaryImageView.hidden = YES;
            self.auxiliaryLabel.hidden = NO;
            self.auxiliaryLabel.text = @" 高清图 ";
        } else if (isLongImage) {
            self.auxiliaryImageView.hidden = YES;
            self.auxiliaryLabel.hidden = NO;
            self.auxiliaryLabel.text = @" 长图 ";
        } else {
            self.auxiliaryImageView.hidden = YES;
            self.auxiliaryLabel.hidden = YES;
        }
        
    } else {
        
        self.mainImageView.image = nil;
        self.auxiliaryImageView.hidden = YES;
        self.auxiliaryLabel.hidden = YES;
    }
}

@end
