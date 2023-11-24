/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageWebPCoder.h"
#import "SDWebImageWebPCoderDefine.h"
#import <Accelerate/Accelerate.h>
#import <os/lock.h>
#import <libkern/OSAtomic.h>

#if __has_include("webp/decode.h") && __has_include("webp/encode.h") && __has_include("webp/demux.h") && __has_include("webp/mux.h")
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#elif __has_include(<libwebp/decode.h>) && __has_include(<libwebp/encode.h>) && __has_include(<libwebp/demux.h>) && __has_include(<libwebp/mux.h>)
#import <libwebp/decode.h>
#import <libwebp/encode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#else
@import libwebp;
#endif

#define SD_USE_OS_UNFAIR_LOCK TARGET_OS_MACCATALYST ||\
    (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_10_0) ||\
    (__MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_12) ||\
    (__TV_OS_VERSION_MIN_REQUIRED >= __TVOS_10_0) ||\
    (__WATCH_OS_VERSION_MIN_REQUIRED >= __WATCHOS_3_0)

#ifndef SD_LOCK_DECLARE
#if SD_USE_OS_UNFAIR_LOCK
#define SD_LOCK_DECLARE(lock) os_unfair_lock lock
#else
#define SD_LOCK_DECLARE(lock) os_unfair_lock lock API_AVAILABLE(ios(10.0), tvos(10), watchos(3), macos(10.12)); \
OSSpinLock lock##_deprecated;
#endif
#endif

#ifndef SD_LOCK_INIT
#if SD_USE_OS_UNFAIR_LOCK
#define SD_LOCK_INIT(lock) lock = OS_UNFAIR_LOCK_INIT
#else
#define SD_LOCK_INIT(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) lock = OS_UNFAIR_LOCK_INIT; \
else lock##_deprecated = OS_SPINLOCK_INIT;
#endif
#endif

#ifndef SD_LOCK
#if SD_USE_OS_UNFAIR_LOCK
#define SD_LOCK(lock) os_unfair_lock_lock(&lock)
#else
#define SD_LOCK(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) os_unfair_lock_lock(&lock); \
else OSSpinLockLock(&lock##_deprecated);
#endif
#endif

#ifndef SD_UNLOCK
#if SD_USE_OS_UNFAIR_LOCK
#define SD_UNLOCK(lock) os_unfair_lock_unlock(&lock)
#else
#define SD_UNLOCK(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) os_unfair_lock_unlock(&lock); \
else OSSpinLockUnlock(&lock##_deprecated);
#endif
#endif

/// Used for animated WebP, which need a canvas for decoding (rendering), possible apply a scale transform for thumbnail decoding (avoiding post-rescale using vImage)
/// See more in #73
static inline CGContextRef _Nullable CreateWebPCanvas(BOOL hasAlpha, CGSize canvasSize, CGSize thumbnailSize, BOOL preserveAspectRatio) {
    // From SDWebImage v5.17.0, use runtime detection of bitmap info instead of hardcode.
    CGBitmapInfo bitmapInfo = [SDImageCoderHelper preferredPixelFormat:hasAlpha].bitmapInfo;
    // Check whether we need to use thumbnail
    CGSize scaledSize = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(canvasSize.width, canvasSize.height) scaleSize:thumbnailSize preserveAspectRatio:preserveAspectRatio shouldScaleUp:NO];
    CGContextRef canvas = CGBitmapContextCreate(NULL, scaledSize.width, scaledSize.height, 8, 0, [SDImageCoderHelper colorSpaceGetDeviceRGB], bitmapInfo);
    if (!canvas) {
        return nil;
    }
    // Check whether we need to use thumbnail
    if (!CGSizeEqualToSize(canvasSize, scaledSize)) {
        CGFloat sx = scaledSize.width / canvasSize.width;
        CGFloat sy = scaledSize.height / canvasSize.height;
        CGContextScaleCTM(canvas, sx, sy);
    }
    return canvas;
}

WEBP_CSP_MODE ConvertCSPMode(CGBitmapInfo bitmapInfo) {
    // Get alpha info, byteOrder info
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGImageByteOrderInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    size_t bitsPerPixel = 8;
    if (bitmapInfo & kCGBitmapFloatComponents) {
        bitsPerPixel = 16; // 16-Bits, which don't support currently!
    }
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGImageByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGImageByteOrder32Little:
        case kCGImageByteOrder16Little: {
        } break;
        case kCGImageByteOrder32Big:
        case kCGImageByteOrder16Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    switch (alphaInfo) {
        case kCGImageAlphaPremultipliedFirst: {
            if (byteOrderNormal) {
                // ARGB8888, premultiplied
                return MODE_Argb;
            } else {
                // BGRA8888, premultiplied
                return MODE_bgrA;
            }
        }
            break;
        case kCGImageAlphaPremultipliedLast: {
            if (byteOrderNormal) {
                // RGBA8888, premultiplied
                return MODE_rgbA;
            } else {
                // ABGR8888, premultiplied
                // Unsupported!
                return MODE_LAST;
            }
        }
            break;
        case kCGImageAlphaNone: {
            if (byteOrderNormal) {
                // RGB
                return MODE_RGB;
            } else {
                // BGR
                return MODE_BGR;
            }
        }
            break;
        case kCGImageAlphaLast:
        case kCGImageAlphaNoneSkipLast: {
            if (byteOrderNormal) {
                // RGBA or RGBX
                return MODE_RGBA;
            } else {
                // ABGR or XBGR
                // Unsupported!
                return MODE_LAST;
            }
        }
            break;
        case kCGImageAlphaFirst:
        case kCGImageAlphaNoneSkipFirst: {
            if (byteOrderNormal) {
                // ARGB or XRGB
                return MODE_ARGB;
            } else {
                // BGRA or BGRX
                return MODE_BGRA;
            }
        }
            break;
        case kCGImageAlphaOnly: {
            // A
            // Unsupported!
            return MODE_LAST;
        }
            break;
        default:
            break;
    }
    return MODE_LAST;
}

@interface SDWebPCoderFrame : NSObject

@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds
@property (nonatomic, assign) NSUInteger width; // Frame width
@property (nonatomic, assign) NSUInteger height; // Frame height
@property (nonatomic, assign) NSUInteger offsetX; // Frame origin.x in canvas (left-bottom based)
@property (nonatomic, assign) NSUInteger offsetY; // Frame origin.y in canvas (left-bottom based)
@property (nonatomic, assign) BOOL hasAlpha; // Whether frame contains alpha
@property (nonatomic, assign) BOOL isFullSize; // Whether frame size is equal to canvas size
@property (nonatomic, assign) BOOL shouldBlend; // Frame dispose method
@property (nonatomic, assign) BOOL shouldDispose; // Frame blend operation
@property (nonatomic, assign) NSUInteger blendFromIndex; // The nearest previous frame index which blend mode is WEBP_MUX_BLEND

@end

@implementation SDWebPCoderFrame
@end

@implementation SDImageWebPCoder {
    WebPIDecoder *_idec;
    WebPDemuxer *_demux;
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray<SDWebPCoderFrame *> *_frames;
    CGContextRef _canvas;
    CGColorSpaceRef _colorSpace;
    BOOL _hasAnimation;
    BOOL _hasAlpha;
    BOOL _finished;
    CGFloat _canvasWidth;
    CGFloat _canvasHeight;
    SD_LOCK_DECLARE(_lock);
    NSUInteger _currentBlendIndex;
    BOOL _preserveAspectRatio;
    CGSize _thumbnailSize;
    BOOL _limitBytes;
}

- (void)dealloc {
    if (_idec) {
        WebPIDelete(_idec);
        _idec = NULL;
    }
    if (_demux) {
        WebPDemuxDelete(_demux);
        _demux = NULL;
    }
    if (_canvas) {
        CGContextRelease(_canvas);
        _canvas = NULL;
    }
    if (_colorSpace) {
        CGColorSpaceRelease(_colorSpace);
        _colorSpace = NULL;
    }
}

+ (instancetype)sharedCoder {
    static SDImageWebPCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageWebPCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatWebP);
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatWebP);
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = data.bytes;
    webpData.size = data.length;
    WebPDemuxer *demuxer = WebPDemux(&webpData);
    if (!demuxer) {
        return nil;
    }
    
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    BOOL hasAnimation = flags & ANIMATION_FLAG;
    BOOL decodeFirstFrame = [options[SDImageCoderDecodeFirstFrameOnly] boolValue];
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = [scaleFactor doubleValue];
        if (scale < 1) {
            scale = 1;
        }
    }
    
    CGSize thumbnailSize = CGSizeZero;
    NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
    if (thumbnailSizeValue != nil) {
#if SD_MAC
        thumbnailSize = thumbnailSizeValue.sizeValue;
#else
        thumbnailSize = thumbnailSizeValue.CGSizeValue;
#endif
    }
    
    BOOL preserveAspectRatio = YES;
    NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
    if (preserveAspectRatioValue != nil) {
        preserveAspectRatio = preserveAspectRatioValue.boolValue;
    }
    
    // for animated webp image
    WebPIterator iter;
    // libwebp's index start with 1
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        return nil;
    }
    CGColorSpaceRef colorSpace = [self sd_createColorSpaceWithDemuxer:demuxer];
    int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    uint32_t frameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    int loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    
    NSUInteger limitBytes = 0;
    NSNumber *limitBytesValue = options[SDImageCoderDecodeScaleDownLimitBytes];
    if (limitBytesValue != nil) {
        limitBytes = limitBytesValue.unsignedIntegerValue;
    }
    // Scale down to limit bytes if need
    if (limitBytes > 0) {
        // Hack 32 BitsPerPixel
        CGSize imageSize = CGSizeMake(canvasWidth, canvasHeight);
        CGSize framePixelSize = [SDImageCoderHelper scaledSizeWithImageSize:imageSize limitBytes:limitBytes bytesPerPixel:4 frameCount:frameCount];
        // Override thumbnail size
        thumbnailSize = framePixelSize;
        preserveAspectRatio = YES;
    }
    
    // Check whether we need to use thumbnail
    CGSize scaledSize = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(canvasWidth, canvasHeight) scaleSize:thumbnailSize preserveAspectRatio:preserveAspectRatio shouldScaleUp:NO];
    
    if (!hasAnimation || decodeFirstFrame) {
        // first frame for animated webp image
        CGImageRef imageRef = [self sd_createWebpImageWithData:iter.fragment colorSpace:colorSpace scaledSize:scaledSize];
        CGColorSpaceRelease(colorSpace);
#if SD_UIKIT || SD_WATCH
        UIImage *firstFrameImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
        UIImage *firstFrameImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
        firstFrameImage.sd_imageFormat = SDImageFormatWebP;
        CGImageRelease(imageRef);
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        return firstFrameImage;
    }
    
    BOOL hasAlpha = flags & ALPHA_FLAG;
    CGContextRef canvas = CreateWebPCanvas(hasAlpha, CGSizeMake(canvasWidth, canvasHeight), thumbnailSize, preserveAspectRatio);
    if (!canvas) {
        WebPDemuxDelete(demuxer);
        CGColorSpaceRelease(colorSpace);
        return nil;
    }
    
    NSMutableArray<SDImageFrame *> *frames = [NSMutableArray array];
    
    do {
        @autoreleasepool {
            CGImageRef imageRef = [self sd_drawnWebpImageWithCanvas:canvas demuxer:demuxer iterator:iter colorSpace:colorSpace];
            if (!imageRef) {
                continue;
            }

#if SD_UIKIT || SD_WATCH
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
            CGImageRelease(imageRef);
            
            NSTimeInterval duration = [self sd_frameDurationWithIterator:iter];
            SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
    } while (WebPDemuxNextFrame(&iter));
    
    WebPDemuxReleaseIterator(&iter);
    WebPDemuxDelete(demuxer);
    CGContextRelease(canvas);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *animatedImage = [SDImageCoderHelper animatedImageWithFrames:frames];
    animatedImage.sd_imageLoopCount = loopCount;
    animatedImage.sd_imageFormat = SDImageFormatWebP;
    
    return animatedImage;
}

#pragma mark - Progressive Decode
- (instancetype)initIncrementalWithOptions:(nullable SDImageCoderOptions *)options {
    self = [super init];
    if (self) {
        // Progressive images need transparent, so always use premultiplied RGBA
        _idec = WebPINewRGB(MODE_rgbA, NULL, 0, 0);
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        _scale = scale;
        CGSize thumbnailSize = CGSizeZero;
        NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
        if (thumbnailSizeValue != nil) {
    #if SD_MAC
            thumbnailSize = thumbnailSizeValue.sizeValue;
    #else
            thumbnailSize = thumbnailSizeValue.CGSizeValue;
    #endif
        }
        _thumbnailSize = thumbnailSize;
        BOOL preserveAspectRatio = YES;
        NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
        if (preserveAspectRatioValue != nil) {
            preserveAspectRatio = preserveAspectRatioValue.boolValue;
        }
        _preserveAspectRatio = preserveAspectRatio;
        NSUInteger limitBytes = 0;
        NSNumber *limitBytesValue = options[SDImageCoderDecodeScaleDownLimitBytes];
        if (limitBytesValue != nil) {
            limitBytes = limitBytesValue.unsignedIntegerValue;
        }
        _limitBytes = limitBytes;
        _currentBlendIndex = NSNotFound;
        SD_LOCK_INIT(_lock);
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _finished = finished;
    // check whether we can detect Animated WebP or Static WebP, they need different codec (Demuxer or IDecoder)
    if (!_hasAnimation) {
        VP8StatusCode status = WebPIUpdate(_idec, data.bytes, data.length);
        // For Static WebP, all things done.
        // For Animated WebP (currently use `VP8_STATUS_UNSUPPORTED_FEATURE` to check), continue to create demuxer
        if (status != VP8_STATUS_UNSUPPORTED_FEATURE) {
            return;
        }
        _hasAnimation = YES;
    }
    // libwebp current have no API to update demuxer, so we always delete and recreate demuxer
    // Use lock to avoid progressive animation decoding thread safe issue
    SD_LOCK(_lock);
    if (_demux) {
        // next line `_imageData = nil` ARC will release the raw buffer, but need release the demuxer firstly because libwebp don't use retain/release rule
        WebPDemuxDelete(_demux);
        _demux = NULL;
    }
    _imageData = data;
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = _imageData.bytes;
    webpData.size = _imageData.length;
    WebPDemuxState state;
    _demux = WebPDemuxPartial(&webpData, &state);
    if (_demux && state != WEBP_DEMUX_PARSE_ERROR) {
        [self scanAndCheckFramesValidWithDemuxer:_demux];
    }
    SD_UNLOCK(_lock);
    // Scale down to limit bytes if need
    if (_limitBytes > 0) {
        // Hack 32 BitsPerPixel
        CGSize imageSize = CGSizeMake(_canvasWidth, _canvasHeight);
        CGSize framePixelSize = [SDImageCoderHelper scaledSizeWithImageSize:imageSize limitBytes:_limitBytes bytesPerPixel:4 frameCount:_frameCount];
        // Override thumbnail size
        _thumbnailSize = framePixelSize;
        _preserveAspectRatio = YES;
    }
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    UIImage *image;
    
    // For Animated WebP Images, progressive decoding only return the first frame.
    // If you want progressive animation, use the SDAniamtedCoder protocol method instead.
    if (_demux) {
        SD_LOCK(_lock);
        image = [self safeStaticImageFrame];
        SD_UNLOCK(_lock);
        image.sd_imageFormat = SDImageFormatWebP;
        image.sd_isDecoded = YES;
        return image;
    }
    
    // For Static WebP images
    int width = 0;
    int height = 0;
    int last_y = 0;
    int stride = 0;
    uint8_t *rgba = WebPIDecGetRGB(_idec, &last_y, &width, &height, &stride);
    // last_y may be 0, means no enough bitmap data to decode, ignore this
    if (width + height > 0 && last_y > 0 && height >= last_y) {
        // Construct a UIImage from the decoded RGBA value array
        size_t rgbaSize = last_y * stride;
        CGDataProviderRef provider =
        CGDataProviderCreateWithData(NULL, rgba, rgbaSize, NULL);
        CGColorSpaceRef colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        // Because _idec use MODE_rgbA
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
        size_t components = 4;
        BOOL shouldInterpolate = YES;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        // Why to use last_y for image height is because of libwebp's bug (https://bugs.chromium.org/p/webp/issues/detail?id=362)
        // It will not keep memory barrier safe on x86 architechure (macOS & iPhone simulator) but on ARM architecture (iPhone & iPad & tv & watch) it works great
        // If different threads use WebPIDecGetRGB to grab rgba bitmap, it will contain the previous decoded bitmap data
        // So this will cause our drawed image looks strange(above is the current part but below is the previous part)
        // We only grab the last_y height and draw the last_y height instead of total height image
        // Besides fix, this can enhance performance since we do not need to create extra bitmap
        CGImageRef imageRef = CGImageCreate(width, last_y, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, shouldInterpolate, renderingIntent);
        
        CGDataProviderRelease(provider);
        
        if (!imageRef) {
            return nil;
        }
        
        CGContextRef canvas = CreateWebPCanvas(YES, CGSizeMake(width, height), _thumbnailSize, _preserveAspectRatio);
        if (!canvas) {
            CGImageRelease(imageRef);
            return nil;
        }
        
        // Only draw the last_y image height, keep remains transparent, in Core Graphics coordinate system
        CGContextDrawImage(canvas, CGRectMake(0, height - last_y, width, last_y), imageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
        CGImageRelease(imageRef);
        if (!newImageRef) {
            CGContextRelease(canvas);
            return nil;
        }
        CGFloat scale = _scale;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        
#if SD_UIKIT || SD_WATCH
        image = [[UIImage alloc] initWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
#else
        image = [[UIImage alloc] initWithCGImage:newImageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
        image.sd_isDecoded = YES; // Already drawn on bitmap context above
        image.sd_imageFormat = SDImageFormatWebP;
        CGImageRelease(newImageRef);
        CGContextRelease(canvas);
    }
    
    return image;
}

- (void)sd_blendWebpImageWithCanvas:(CGContextRef)canvas demuxer:(nonnull WebPDemuxer *)demuxer iterator:(WebPIterator)iter colorSpace:(nonnull CGColorSpaceRef)colorSpaceRef {
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = canvasHeight - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    
    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    } else {
        CGImageRef imageRef = [self sd_createWebpImageWithData:iter.fragment colorSpace:colorSpaceRef scaledSize:CGSizeZero];
        if (!imageRef) {
            return;
        }
        BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
        // If not blend, cover the target image rect. (firstly clear then draw)
        if (!shouldBlend) {
            CGContextClearRect(canvas, imageRect);
        }
        CGContextDrawImage(canvas, imageRect, imageRef);
        CGImageRelease(imageRef);
    }
}

- (nullable CGImageRef)sd_drawnWebpImageWithCanvas:(CGContextRef)canvas demuxer:(nonnull WebPDemuxer *)demuxer iterator:(WebPIterator)iter colorSpace:(nonnull CGColorSpaceRef)colorSpaceRef CF_RETURNS_RETAINED {
    CGImageRef imageRef = [self sd_createWebpImageWithData:iter.fragment colorSpace:colorSpaceRef scaledSize:CGSizeZero];
    if (!imageRef) {
        return nil;
    }
    
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = canvasHeight - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    
    BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
    
    // If not blend, cover the target image rect. (firstly clear then draw)
    if (!shouldBlend) {
        CGContextClearRect(canvas, imageRect);
    }
    
    CGContextDrawImage(canvas, imageRect, imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
    CGImageRelease(imageRef);

    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    }
    
    return newImageRef;
}

- (nullable CGImageRef)sd_createWebpImageWithData:(WebPData)webpData colorSpace:(nonnull CGColorSpaceRef)colorSpaceRef scaledSize:(CGSize)scaledSize CF_RETURNS_RETAINED {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    
    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    
    BOOL hasAlpha = config.input.has_alpha;
    // From SDWebImage v5.17.0, use runtime detection of bitmap info instead of hardcode.
    SDImagePixelFormat pixelFormat = [SDImageCoderHelper preferredPixelFormat:hasAlpha];
    CGBitmapInfo bitmapInfo = pixelFormat.bitmapInfo;
    WEBP_CSP_MODE mode = ConvertCSPMode(bitmapInfo);
    if (mode == MODE_LAST) {
#if DEBUG
        NSLog(@"Unsupported libwebp preferred CGBitmapInfo: %d", bitmapInfo);
#endif
        // Fallback to RGBA8888/RGB888 instead
        mode = MODE_rgbA;
        bitmapInfo = kCGBitmapByteOrderDefault;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNoneSkipLast;
    }
    config.output.colorspace = mode;
    config.options.use_threads = 1;
    
    
    // Use scaling for thumbnail
    size_t width = config.input.width;
    size_t height = config.input.height;
    if (scaledSize.width != 0 && scaledSize.height != 0) {
        config.options.use_scaling = 1;
        config.options.scaled_width = scaledSize.width;
        config.options.scaled_height = scaledSize.height;
        width = scaledSize.width;
        height = scaledSize.height;
    }
    
    // We alloc the buffer and do byte alignment by ourself. libwebp defaults does not byte alignment to `bitsPerPixel`, which cause the CoreAnimation unhappy and always trigger the `CA::Render::copy_image`
    size_t bitsPerComponent = 8;
    size_t components = (mode == MODE_RGB || mode == MODE_BGR) ? 3 : 4; // Actually always 4
    size_t bitsPerPixel = bitsPerComponent * components;
    // Read: https://github.com/path/FastImageCache#byte-alignment
    // A properly aligned bytes-per-row value must be a multiple of 8 pixels × bytes per pixel
    // For a typical ARGB image, the aligned bytes-per-row value is a multiple of 64.
    size_t alignment = pixelFormat.alignment;
    size_t bytesPerRow = SDByteAlign(width * (bitsPerPixel / 8), alignment);
    
    void *rgba = WebPMalloc(bytesPerRow * height);
    config.output.is_external_memory = 1;
    config.output.u.RGBA.rgba = rgba;
    config.output.u.RGBA.stride = (int)bytesPerRow;
    config.output.u.RGBA.size = height * bytesPerRow;
    
    // Decode the WebP image data into a RGBA value array
    if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
        return nil;
    }
    
    // Construct a UIImage from the decoded RGBA value array
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    BOOL shouldInterpolate = YES;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, shouldInterpolate, renderingIntent);
    
    CGDataProviderRelease(provider);
    
    return imageRef;
}

- (NSTimeInterval)sd_frameDurationWithIterator:(WebPIterator)iter {
    int duration = iter.duration;
    if (duration <= 10) {
        // WebP standard says 0 duration is used for canvas updating but not showing image, but actually Chrome and other implementations set it to 100ms if duration is lower or equal than 10ms
        // Some animated WebP images also created without duration, we should keep compatibility
        duration = 100;
    }
    return duration / 1000.0;
}

// Create and return the correct colorspace by checking the ICC Profile
- (nonnull CGColorSpaceRef)sd_createColorSpaceWithDemuxer:(nonnull WebPDemuxer *)demuxer CF_RETURNS_RETAINED {
    // WebP contains ICC Profile should use the desired colorspace, instead of default device colorspace
    // See: https://developers.google.com/speed/webp/docs/riff_container#color_profile
    
    CGColorSpaceRef colorSpaceRef = NULL;
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    
    if (flags & ICCP_FLAG) {
        WebPChunkIterator chunk_iter;
        int result = WebPDemuxGetChunk(demuxer, "ICCP", 1, &chunk_iter);
        if (result) {
            // See #2618, the `CGColorSpaceCreateWithICCProfile` does not copy ICC Profile data, it only retain `CFDataRef`.
            // When the libwebp `WebPDemuxer` dealloc, all chunks will be freed. So we must copy the ICC data (really cheap, less than 10KB)
            NSData *profileData = [NSData dataWithBytes:chunk_iter.chunk.bytes length:chunk_iter.chunk.size];
            if (@available(iOS 10, tvOS 10, macOS 10.12, watchOS 3, *)) {
                colorSpaceRef = CGColorSpaceCreateWithICCData((__bridge CFDataRef)profileData);
            } else {
                colorSpaceRef = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
            }
            WebPDemuxReleaseChunkIterator(&chunk_iter);
            if (colorSpaceRef) {
                // We use RGB color model to decode WebP images currently, so we must filter out other colorSpace
                CGColorSpaceModel model = CGColorSpaceGetModel(colorSpaceRef);
                if (model != kCGColorSpaceModelRGB) {
                    CGColorSpaceRelease(colorSpaceRef);
                    colorSpaceRef = NULL;
                }
            }
        }
    }
    
    if (!colorSpaceRef) {
        colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGColorSpaceRetain(colorSpaceRef);
    }
    
    return colorSpaceRef;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return (format == SDImageFormatWebP);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    NSArray<SDImageFrame *> *frames = [SDImageCoderHelper framesFromAnimatedImage:image];
    if (!frames || frames.count == 0) {
        SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:0];
        frames = @[frame];
    }
    return [self encodedDataWithFrames:frames loopCount:image.sd_imageLoopCount format:format options:options];
}

- (NSData *)encodedDataWithFrames:(NSArray<SDImageFrame *> *)frames loopCount:(NSUInteger)loopCount format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    UIImage *image = frames.firstObject.image; // Primary image
    if (!image) {
        return nil;
    }
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        // Earily return, supports CGImage only
        return nil;
    }
    
    NSData *data;
    
    double compressionQuality = 1;
    if (options[SDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[SDImageCoderEncodeCompressionQuality] doubleValue];
    }
    CGSize maxPixelSize = CGSizeZero;
    NSValue *maxPixelSizeValue = options[SDImageCoderEncodeMaxPixelSize];
    if (maxPixelSizeValue != nil) {
#if SD_MAC
        maxPixelSize = maxPixelSizeValue.sizeValue;
#else
        maxPixelSize = maxPixelSizeValue.CGSizeValue;
#endif
    }
    NSUInteger maxFileSize = 0;
    if (options[SDImageCoderEncodeMaxFileSize]) {
        maxFileSize = [options[SDImageCoderEncodeMaxFileSize] unsignedIntegerValue];
    }
    
    BOOL encodeFirstFrame = [options[SDImageCoderEncodeFirstFrameOnly] boolValue];
    if (encodeFirstFrame || frames.count <= 1) {
        // for static single webp image
        data = [self sd_encodedWebpDataWithImage:imageRef
                                         quality:compressionQuality
                                    maxPixelSize:maxPixelSize
                                     maxFileSize:maxFileSize
                                         options:options];
    } else {
        // for animated webp image
        WebPMux *mux = WebPMuxNew();
        if (!mux) {
            return nil;
        }
        for (size_t i = 0; i < frames.count; i++) {
            SDImageFrame *currentFrame = frames[i];
            NSData *webpData = [self sd_encodedWebpDataWithImage:currentFrame.image.CGImage
                                                         quality:compressionQuality
                                                    maxPixelSize:maxPixelSize
                                                     maxFileSize:maxFileSize
                                                         options:options];
            int duration = currentFrame.duration * 1000;
            WebPMuxFrameInfo frame = { .bitstream.bytes = webpData.bytes,
                .bitstream.size = webpData.length,
                .duration = duration,
                .id = WEBP_CHUNK_ANMF,
                .dispose_method = WEBP_MUX_DISPOSE_BACKGROUND, // each frame will clear canvas
                .blend_method = WEBP_MUX_NO_BLEND
            };
            if (WebPMuxPushFrame(mux, &frame, 0) != WEBP_MUX_OK) {
                WebPMuxDelete(mux);
                return nil;
            }
        }
        
        WebPMuxAnimParams params = { .bgcolor = 0,
            .loop_count = (int)loopCount
        };
        if (WebPMuxSetAnimationParams(mux, &params) != WEBP_MUX_OK) {
            WebPMuxDelete(mux);
            return nil;
        }
        
        WebPData outputData;
        WebPMuxError error = WebPMuxAssemble(mux, &outputData);
        WebPMuxDelete(mux);
        if (error != WEBP_MUX_OK) {
            return nil;
        }
        data = [NSData dataWithBytes:outputData.bytes length:outputData.size];
        WebPDataClear(&outputData);
    }
    
    return data;
}

- (nullable NSData *)sd_encodedWebpDataWithImage:(nullable CGImageRef)imageRef
                                         quality:(double)quality
                                    maxPixelSize:(CGSize)maxPixelSize
                                     maxFileSize:(NSUInteger)maxFileSize
                                         options:(nullable SDImageCoderOptions *)options
{
    NSData *webpData;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || width > WEBP_MAX_DIMENSION) {
        return nil;
    }
    if (height == 0 || height > WEBP_MAX_DIMENSION) {
        return nil;
    }
    
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    // If we can not get bitmap buffer, early return
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return nil;
    }
    
    uint8_t *rgba = NULL; // RGBA Buffer managed by CFData, don't call `free` on it, instead call `CFRelease` on `dataRef`
    // We must prefer the input CGImage's color space, which may contains ICC profile
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    if (!colorSpace) {
        colorSpace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    }
    CGColorRenderingIntent renderingIntent = CGImageGetRenderingIntent(imageRef);
    vImage_CGImageFormat destFormat = {
        .bitsPerComponent = 8,
        .bitsPerPixel = hasAlpha ? 32 : 24,
        .colorSpace = colorSpace,
        .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault, // RGB888/RGBA8888 (Non-premultiplied to works for libwebp)
        .renderingIntent = renderingIntent
    };
    vImage_Buffer dest;
    // We could not assume that input CGImage's color mode is always RGB888/RGBA8888. Convert all other cases to target color mode using vImage
    // But vImageBuffer_InitWithCGImage will do convert automatically (unless you use `kvImageNoAllocate`), so no need to call `vImageConvert` by ourselves
    vImage_Error error = vImageBuffer_InitWithCGImage(&dest, &destFormat, NULL, imageRef, kvImageNoFlags);
    if (error != kvImageNoError) {
        return nil;
    }
    rgba = dest.data;
    bytesPerRow = dest.rowBytes;
    
    float qualityFactor = quality * 100; // WebP quality is 0-100
    // Encode RGB888/RGBA8888 buffer to WebP data
    // Using the libwebp advanced API: https://developers.google.com/speed/webp/docs/api#advanced_encoding_api
    WebPConfig config;
    WebPPicture picture;
    WebPMemoryWriter writer;
    
    if (!WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, qualityFactor) ||
        !WebPPictureInit(&picture)) {
        // shouldn't happen, except if system installation is broken
        free(dest.data);
        return nil;
    }

    [self updateWebPOptionsToConfig:&config maxFileSize:maxFileSize options:options];
    picture.use_argb = 0; // Lossy encoding use YUV for internel bitstream
    picture.width = (int)width;
    picture.height = (int)height;
    picture.writer = WebPMemoryWrite; // Output in memory data buffer
    picture.custom_ptr = &writer;
    WebPMemoryWriterInit(&writer);
    
    int result;
    if (hasAlpha) {
        result = WebPPictureImportRGBA(&picture, rgba, (int)bytesPerRow);
    } else {
        result = WebPPictureImportRGB(&picture, rgba, (int)bytesPerRow);
    }
    if (!result) {
        WebPMemoryWriterClear(&writer);
        free(dest.data);
        return nil;
    }
    
    // Check if need to scale pixel size
    CGSize scaledSize = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(width, height) scaleSize:maxPixelSize preserveAspectRatio:YES shouldScaleUp:NO];
    if (!CGSizeEqualToSize(scaledSize, CGSizeMake(width, height))) {
        result = WebPPictureRescale(&picture, scaledSize.width, scaledSize.height);
        if (!result) {
            WebPMemoryWriterClear(&writer);
            WebPPictureFree(&picture);
            free(dest.data);
            return nil;
        }
    }
    
    result = WebPEncode(&config, &picture);
    WebPPictureFree(&picture);
    free(dest.data);
    
    if (result) {
        // success
        webpData = [NSData dataWithBytes:writer.mem length:writer.size];
    } else {
        // failed
        webpData = nil;
    }
    WebPMemoryWriterClear(&writer);
    
    return webpData;
}

- (void) updateWebPOptionsToConfig:(WebPConfig * _Nonnull)config
                       maxFileSize:(NSUInteger)maxFileSize
                           options:(nullable SDImageCoderOptions *)options {

    config->target_size = (int)maxFileSize; // Max filesize for output, 0 means use quality instead
    config->pass = maxFileSize > 0 ? 6 : 1; // Use 6 passes for file size limited encoding, which is the default value of `cwebp` command line
    config->lossless = GetIntValueForKey(options, SDImageCoderEncodeWebPLossless, config->lossless);
    
    config->method = GetIntValueForKey(options, SDImageCoderEncodeWebPMethod, config->method);
    config->pass = GetIntValueForKey(options, SDImageCoderEncodeWebPPass, config->pass);
    config->preprocessing = GetIntValueForKey(options, SDImageCoderEncodeWebPPreprocessing, config->preprocessing);
    config->thread_level = GetIntValueForKey(options, SDImageCoderEncodeWebPThreadLevel, 1);
    config->low_memory = GetIntValueForKey(options, SDImageCoderEncodeWebPLowMemory, config->low_memory);
    config->target_PSNR = GetFloatValueForKey(options, SDImageCoderEncodeWebPTargetPSNR, config->target_PSNR);
    config->segments = GetIntValueForKey(options, SDImageCoderEncodeWebPSegments, config->segments);
    config->sns_strength = GetIntValueForKey(options, SDImageCoderEncodeWebPSnsStrength, config->sns_strength);
    config->filter_strength = GetIntValueForKey(options, SDImageCoderEncodeWebPFilterStrength, config->filter_strength);
    config->filter_sharpness = GetIntValueForKey(options, SDImageCoderEncodeWebPFilterSharpness, config->filter_sharpness);
    config->filter_type = GetIntValueForKey(options, SDImageCoderEncodeWebPFilterType, config->filter_type);
    config->autofilter = GetIntValueForKey(options, SDImageCoderEncodeWebPAutofilter, config->autofilter);
    config->alpha_compression = GetIntValueForKey(options, SDImageCoderEncodeWebPAlphaCompression, config->alpha_compression);
    config->alpha_filtering = GetIntValueForKey(options, SDImageCoderEncodeWebPAlphaFiltering, config->alpha_filtering);
    config->alpha_quality = GetIntValueForKey(options, SDImageCoderEncodeWebPAlphaQuality, config->alpha_quality);
    config->show_compressed = GetIntValueForKey(options, SDImageCoderEncodeWebPShowCompressed, config->show_compressed);
    config->partitions = GetIntValueForKey(options, SDImageCoderEncodeWebPPartitions, config->partitions);
    config->partition_limit = GetIntValueForKey(options, SDImageCoderEncodeWebPPartitionLimit, config->partition_limit);
    config->use_sharp_yuv = GetIntValueForKey(options, SDImageCoderEncodeWebPUseSharpYuv, config->use_sharp_yuv);
}

static void FreeImageData(void *info, const void *data, size_t size) {
    WebPFree((void *)data);
}

static int GetIntValueForKey(NSDictionary * _Nonnull dictionary, NSString * _Nonnull key, int defaultValue) {
    id value = [dictionary objectForKey:key];
    if (value != nil) {
        if ([value isKindOfClass: [NSNumber class]]) {
            return [value intValue];
        }
    }
    return defaultValue;
}

static float GetFloatValueForKey(NSDictionary * _Nonnull dictionary, NSString * _Nonnull key, float defaultValue) {
    id value = [dictionary objectForKey:key];
    if (value != nil) {
        if ([value isKindOfClass: [NSNumber class]]) {
            return [value floatValue];
        }
    }
    return defaultValue;
}


#pragma mark - SDAnimatedImageCoder
- (instancetype)initWithAnimatedImageData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    if (self) {
        WebPData webpData;
        WebPDataInit(&webpData);
        webpData.bytes = data.bytes;
        webpData.size = data.length;
        WebPDemuxer *demuxer = WebPDemux(&webpData);
        if (!demuxer) {
            return nil;
        }
        BOOL framesValid = [self scanAndCheckFramesValidWithDemuxer:demuxer];
        if (!framesValid) {
            WebPDemuxDelete(demuxer);
            return nil;
        }
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        CGSize thumbnailSize = CGSizeZero;
        NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
        if (thumbnailSizeValue != nil) {
    #if SD_MAC
            thumbnailSize = thumbnailSizeValue.sizeValue;
    #else
            thumbnailSize = thumbnailSizeValue.CGSizeValue;
    #endif
        }
        _thumbnailSize = thumbnailSize;
        BOOL preserveAspectRatio = YES;
        NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
        if (preserveAspectRatioValue != nil) {
            preserveAspectRatio = preserveAspectRatioValue.boolValue;
        }
        _preserveAspectRatio = preserveAspectRatio;
        NSUInteger limitBytes = 0;
        NSNumber *limitBytesValue = options[SDImageCoderDecodeScaleDownLimitBytes];
        if (limitBytesValue != nil) {
            limitBytes = limitBytesValue.unsignedIntegerValue;
        }
        _limitBytes = limitBytes;
        // Scale down to limit bytes if need
        if (_limitBytes > 0) {
            // Hack 32 BitsPerPixel
            CGSize imageSize = CGSizeMake(_canvasWidth, _canvasHeight);
            CGSize framePixelSize = [SDImageCoderHelper scaledSizeWithImageSize:imageSize limitBytes:_limitBytes bytesPerPixel:4 frameCount:_frameCount];
            // Override thumbnail size
            _thumbnailSize = framePixelSize;
            _preserveAspectRatio = YES;
        }
        _scale = scale;
        _demux = demuxer;
        _imageData = data;
        _currentBlendIndex = NSNotFound;
        SD_LOCK_INIT(_lock);
    }
    return self;
}

- (BOOL)scanAndCheckFramesValidWithDemuxer:(WebPDemuxer *)demuxer {
    if (!demuxer) {
        return NO;
    }
    WebPIterator iter;
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        return NO;
    }
    
    uint32_t iterIndex = 0;
    uint32_t lastBlendIndex = 0;
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    BOOL hasAnimation = flags & ANIMATION_FLAG;
    BOOL hasAlpha = flags & ALPHA_FLAG;
    int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    uint32_t frameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    uint32_t loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    NSMutableArray<SDWebPCoderFrame *> *frames = [NSMutableArray array];
    
    _hasAnimation = hasAnimation;
    _hasAlpha = hasAlpha;
    _canvasWidth = canvasWidth;
    _canvasHeight = canvasHeight;
    _loopCount = loopCount;
    
    // If static WebP, does not need to parse the frame blend index
    if (frameCount <= 1) {
        return YES;
    }
    
    // We should loop all the frames and scan each frames' blendFromIndex for later decoding, this can also ensure all frames is valid
    do {
        if (!iter.complete) {
            // Skip partial frame
            continue;
        }
        SDWebPCoderFrame *frame = [[SDWebPCoderFrame alloc] init];
        frame.index = iterIndex;
        frame.duration = [self sd_frameDurationWithIterator:iter];
        frame.width = iter.width;
        frame.height = iter.height;
        frame.hasAlpha = iter.has_alpha;
        frame.shouldDispose = iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND;
        frame.shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
        frame.offsetX = iter.x_offset;
        frame.offsetY = canvasHeight - iter.y_offset - iter.height;

        BOOL sizeEqualsToCanvas = (iter.width == canvasWidth && iter.height == canvasHeight);
        BOOL offsetIsZero = (iter.x_offset == 0 && iter.y_offset == 0);
        frame.isFullSize = (sizeEqualsToCanvas && offsetIsZero);
        
        if ((!frame.shouldBlend || !frame.hasAlpha) && frame.isFullSize) {
            lastBlendIndex = iterIndex;
            frame.blendFromIndex = iterIndex;
        } else {
            if (frame.shouldDispose && frame.isFullSize) {
                frame.blendFromIndex = lastBlendIndex;
                lastBlendIndex = iterIndex + 1;
            } else {
                frame.blendFromIndex = lastBlendIndex;
            }
        }
        iterIndex++;
        [frames addObject:frame];
    } while (WebPDemuxNextFrame(&iter));
    WebPDemuxReleaseIterator(&iter);
    
    if (frames.count != frameCount) {
        // frames not match, do not override current value
        return NO;
    }
    _frameCount = frameCount;
    _frames = [frames copy];
    
    return YES;
}

- (NSData *)animatedImageData {
    return _imageData;
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageFrameCount {
    return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    NSTimeInterval duration;
    // Incremental Animation decoding may update frames when new bytes available
    // Which should use lock to ensure frame count and frames match, ensure atomic logic
    if (_idec != NULL) {
        SD_LOCK(_lock);
        if (index >= _frames.count) {
            SD_UNLOCK(_lock);
            return 0;
        }
        duration = _frames[index].duration;
        SD_UNLOCK(_lock);
    } else {
        if (index >= _frames.count) {
            return 0;
        }
        duration = _frames[index].duration;
    }
    return duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    UIImage *image;
    // Incremental Animation decoding may update frames when new bytes available
    // Which should use lock to ensure frame count and frames match, ensure atomic logic
    if (_idec != NULL) {
        SD_LOCK(_lock);
        if (index >= _frames.count) {
            SD_UNLOCK(_lock);
            return nil;
        }
        if (_frames.count <= 1) {
            image = [self safeStaticImageFrame];
        } else {
            image = [self safeAnimatedImageFrameAtIndex:index];
        }
        SD_UNLOCK(_lock);
    } else {
        // Animation Decoding need a lock on the canvas (which is shared), but the _frames is immutable and no lock needed
        if (index >= _frames.count) {
            return nil;
        }
        if (_frames.count <= 1) {
            SD_LOCK(_lock);
            image = [self safeStaticImageFrame];
            SD_UNLOCK(_lock);
        } else {
            SD_LOCK(_lock);
            image = [self safeAnimatedImageFrameAtIndex:index];
            SD_UNLOCK(_lock);
        }
    }
    return image;
}

- (UIImage *)safeStaticImageFrame {
    UIImage *image;
    // Static WebP image
    WebPIterator iter;
    if (!WebPDemuxGetFrame(_demux, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        return nil;
    }
    if (!_colorSpace) {
        _colorSpace = [self sd_createColorSpaceWithDemuxer:_demux];
    }
    // Check whether we need to use thumbnail
    CGImageRef imageRef;
    if (_hasAnimation) {
        // If have animation, we still need to allocate a CGContext, because the poster frame may be smaller than canvas
        if (!_canvas) {
            CGContextRef canvas = CreateWebPCanvas(_hasAlpha, CGSizeMake(_canvasWidth, _canvasHeight), _thumbnailSize, _preserveAspectRatio);
            if (!canvas) {
                return nil;
            }
            _canvas = canvas;
        }
        imageRef = [self sd_drawnWebpImageWithCanvas:_canvas demuxer:_demux iterator:iter colorSpace:_colorSpace];
    } else {
        CGSize scaledSize = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(iter.width, iter.height) scaleSize:_thumbnailSize preserveAspectRatio:_preserveAspectRatio shouldScaleUp:NO];
        imageRef = [self sd_createWebpImageWithData:iter.fragment colorSpace:_colorSpace scaledSize:scaledSize];
    }
    if (!imageRef) {
        return nil;
    }
#if SD_UIKIT || SD_WATCH
    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:UIImageOrientationUp];
#else
    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(imageRef);
    WebPDemuxReleaseIterator(&iter);
    return image;
}

- (UIImage *)safeAnimatedImageFrameAtIndex:(NSUInteger)index {
    if (!_canvas) {
        CGContextRef canvas = CreateWebPCanvas(_hasAlpha, CGSizeMake(_canvasWidth, _canvasHeight), _thumbnailSize, _preserveAspectRatio);
        if (!canvas) {
            return nil;
        }
        _canvas = canvas;
    }
    if (!_colorSpace) {
        _colorSpace = [self sd_createColorSpaceWithDemuxer:_demux];
    }
    
    SDWebPCoderFrame *frame = _frames[index];
    UIImage *image;
    WebPIterator iter;
    
    // Because Animated WebP supports dispose method, which means frames can based on previous canvas context. However, if we clear canvas and loop from the 0 index until the request index, it's harm for performance.
    // But when one frame's dispose method is `WEBP_MUX_DISPOSE_BACKGROUND`, the canvas is cleared after the frame decoded. And subsequent frames are not effected by that frame.
    // So, we calculate each frame's `blendFromIndex`. Then directly draw canvas from that index, instead of always from 0 index.
    
    if (_currentBlendIndex != NSNotFound && _currentBlendIndex + 1 == index) {
        // If the request index is subsequence of current blend index, it does not matter what dispose method is. The canvas is always ready.
        // libwebp's index start with 1
        if (!WebPDemuxGetFrame(_demux, (int)(index + 1), &iter)) {
            WebPDemuxReleaseIterator(&iter);
            return nil;
        }
    } else {
        // Else, this can happen when one image set to different imageViews or one loop end. So we should clear the canvas. Then draw until the canvas is ready.
        if (_currentBlendIndex != NSNotFound) {
            CGContextClearRect(_canvas, CGRectMake(0, 0, _canvasWidth, _canvasHeight));
        }
        
        // Then, loop from the blend from index, draw each of previous frames on the canvas.
        // We use do while loop to call `WebPDemuxNextFrame`(fast), until the endIndex meet.
        size_t startIndex = frame.blendFromIndex;
        size_t endIndex = frame.index;
        // libwebp's index start with 1
        if (!WebPDemuxGetFrame(_demux, (int)(startIndex + 1), &iter)) {
            WebPDemuxReleaseIterator(&iter);
            return nil;
        }
        // Draw from range: [startIndex, endIndex)
        if (endIndex > startIndex) {
            do {
                @autoreleasepool {
                    [self sd_blendWebpImageWithCanvas:_canvas demuxer:_demux iterator:iter colorSpace:_colorSpace];
                }
            } while ((size_t)iter.frame_num < endIndex && WebPDemuxNextFrame(&iter));
        }
        // libwebp's index start with 1
        if (!WebPDemuxGetFrame(_demux, (int)(index + 1), &iter)) {
            WebPDemuxReleaseIterator(&iter);
            return nil;
        }
    }
    _currentBlendIndex = index;
    
    // Now the canvas is ready, which respects of dispose method behavior. Just do normal decoding and produce image.
    CGImageRef imageRef = [self sd_drawnWebpImageWithCanvas:_canvas demuxer:_demux iterator:iter colorSpace:_colorSpace];
    if (!imageRef) {
        return nil;
    }
#if SD_UIKIT || SD_WATCH
    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:UIImageOrientationUp];
#else
    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:kCGImagePropertyOrientationUp];
#endif
    image.sd_imageFormat = SDImageFormatWebP;
    CGImageRelease(imageRef);
    
    WebPDemuxReleaseIterator(&iter);
    return image;
}

@end
