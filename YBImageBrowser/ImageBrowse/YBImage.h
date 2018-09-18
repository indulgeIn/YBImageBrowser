//
//  YBImage.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/31.
//  Copyright © 2018年 杨波. All rights reserved.
//

#if __has_include(<YYImage/YYImage.h>)
#import <YYImage/YYFrameImage.h>
#import <YYImage/YYSpriteSheetImage.h>
#import <YYImage/YYImageCoder.h>
#import <YYImage/YYAnimatedImageView.h>
#elif __has_include(<YYWebImage/YYImage.h>)
#import <YYWebImage/YYFrameImage.h>
#import <YYWebImage/YYSpriteSheetImage.h>
#import <YYWebImage/YYImageCoder.h>
#import <YYWebImage/YYAnimatedImageView.h>
#else
#import "YYFrameImage.h"
#import "YYSpriteSheetImage.h"
#import "YYImageCoder.h"
#import "YYAnimatedImageView.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 It is a fully compatible `UIImage` subclass. It extends the UIImage
 to support animated WebP, APNG and GIF format image data decoding. It also
 support NSCoding protocol to archive and unarchive multi-frame image data.
 
 If the image is created from multi-frame image data, and you want to play the
 animation, try replace UIImageView with `YYAnimatedImageView`.
 
 Note: 'YBImage' is copied from 'YYImage', only added a logic of whether to decompress.
 */

@interface YBImage : UIImage <YYAnimatedImage>

+ (nullable YBImage *)imageNamed:(NSString *)name; // no cache!
+ (nullable YBImage *)imageWithContentsOfFile:(NSString *)path;
+ (nullable YBImage *)imageWithData:(NSData *)data;
+ (nullable YBImage *)imageWithData:(NSData *)data scale:(CGFloat)scale;

/**
 If the image is created from data or file, then the value indicates the data type.
 */
@property (nonatomic, readonly) YYImageType animatedImageType;

/**
 If the image is created from animated image data (multi-frame GIF/APNG/WebP),
 this property stores the original image data.
 */
@property (nullable, nonatomic, readonly) NSData *animatedImageData;

/**
 The total memory usage (in bytes) if all frame images was loaded into memory.
 The value is 0 if the image is not created from a multi-frame image data.
 */
@property (nonatomic, readonly) NSUInteger animatedImageMemorySize;

/**
 Preload all frame image to memory.
 
 @discussion Set this property to `YES` will block the calling thread to decode
 all animation frame image to memory, set to `NO` will release the preloaded frames.
 If the image is shared by lots of image views (such as emoticon), preload all
 frames will reduce the CPU cost.
 
 See `animatedImageMemorySize` for memory cost.
 */
@property (nonatomic) BOOL preloadAllAnimatedImageFrames;


@end

NS_ASSUME_NONNULL_END
