//
//  YBIBImageData.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/5.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <Photos/Photos.h>
#import "YBIBDataProtocol.h"
#import "YBIBImageLayout.h"
#import "YBIBImageCache.h"
#import "YBIBInteractionProfile.h"

NS_ASSUME_NONNULL_BEGIN

@class YBIBImageData;

/// 获取 NSData 的闭包
typedef NSData * _Nullable (^YBIBImageDataBlock)(void);

/// 获取 UIImage 的闭包
typedef UIImage * _Nullable (^YBIBImageBlock)(void);

/// 修改 NSURLRequest 并返回的闭包
typedef NSURLRequest * _Nullable (^YBIBRequestModifierBlock)(YBIBImageData *imageData, NSURLRequest *request);

/// 根据图片逻辑像素和 scale 判断是否需要预解码的闭包
typedef BOOL (^YBIBPreDecodeDecisionBlock)(YBIBImageData *imageData, CGSize imageSize, CGFloat scale);

/// 修改 UIImage 并返回的闭包
typedef void (^YBIBImageModifierBlock)(YBIBImageData *imageData, UIImage *image, void(^completion)(UIImage *processedImage));

/// 单击事件的处理闭包
typedef void (^YBIBImageSingleTouchBlock)(YBIBImageData *imageData);

/// 内部图片滚动视图状态回调闭包
typedef void (^YBIBImageScrollViewStatusBlock)(YBIBImageData *imageData, UIScrollView *scrollView);


/**
 图片数据类，承担配置数据和处理数据的责任
 */
@interface YBIBImageData : NSObject <YBIBDataProtocol>

/// 本地图片名字
@property (nonatomic, copy, nullable) NSString *imageName;

/// 本地图片路径
@property (nonatomic, copy, nullable) NSString *imagePath;

/// 本地图片字节码，返回 NSData
@property (nonatomic, copy, nullable) YBIBImageDataBlock imageData;

/// 本地图片，返回 UIImage 及其衍生类 (若不是遵循'YYAnimatedImage'协议的类型，将失去对动图和拓展格式的支持)
@property (nonatomic, copy, nullable) YBIBImageBlock image;

/// 网络图片资源
@property (nonatomic, copy, nullable) NSURL *imageURL;

/// 修改 NSURLRequest 并返回
@property (nonatomic, copy, nullable) YBIBRequestModifierBlock requestModifier;

/// 相册图片资源
@property (nonatomic, strong, nullable) PHAsset *imagePHAsset;

/// 投影视图，当前数据模型对应外界业务的 UIView (通常为 UIImageView)，做转场动效用
@property (nonatomic, weak, nullable) __kindof UIView *projectiveView;

/// 预览图/缩约图，注意若这个图片过大会导致内存压力（若 projectiveView 存在且是 UIImageView 类型将会自动获取缩约图）
@property (nonatomic, strong, nullable) UIImage *thumbImage;

/// 预览图/缩约图 URL，缓存中未找到则忽略（若 projectiveView 存在且是 UIImageView 类型将会自动获取缩约图）
@property (nonatomic, copy, nullable) NSURL *thumbURL;

/// 是否允许保存到相册
@property (nonatomic, assign) BOOL allowSaveToPhotoAlbum;

/// 根据图片信息判断是否需要预解码
@property (nonatomic, copy, nullable) YBIBPreDecodeDecisionBlock preDecodeDecision;

/// 是否异步预解码，默认为 YES
@property (nonatomic, assign) BOOL shouldPreDecodeAsync;

/// 压缩物理像素界限大小，当图片超过这个值将会被压缩显示，默认为 4096*4096
@property (nonatomic, assign) CGFloat compressingSize;

/// 触发裁剪的缩放比例，必须大于等于 1，默认情况内部会动态计算 (仅当图片需要压缩显示时有效)
@property (nonatomic, assign) CGFloat cuttingZoomScale;

/**
 判断图片是否需要压缩显示
 */
- (BOOL)shouldCompressWithImage:(UIImage *)image;

/**
 修改原始图片并返回处理后的图片 (特别注意当 image 是大图的时候，避免 OOM)
 Example:
    [... setImageModifier:^(YBIBImageData *imageData, UIImage * _Nonnull image, void (^ _Nonnull completion)(UIImage * _Nonnull)) {
        //step 1 : Add watermark, trademark, etc. (Sync or async).
        ... processing code ...
        //step 2 : Return the processed UIImage.
        completion(image);
    }];
 */
@property (nonatomic, copy, nullable) YBIBImageModifierBlock originImageModifier;

/// 修改压缩图片并返回处理后的图片 (仅在当前图片需要被压缩时有效)
@property (nonatomic, copy, nullable) YBIBImageModifierBlock compressedImageModifier;

/// 修改裁剪图片并返回处理后的图片 (仅在当前图片需要被裁剪时有效)
@property (nonatomic, copy, nullable) YBIBImageModifierBlock cuttedImageModifier;

/// 预留属性可随意使用
@property (nonatomic, strong, nullable) id extraData;

/// 手势交互动效配置文件
@property (nonatomic, strong) YBIBInteractionProfile *interactionProfile;

/// 单击的处理，默认是退出图片浏览器
@property (nonatomic, copy, nullable) YBIBImageSingleTouchBlock singleTouchBlock;

/// 图片滚动的回调
@property (nonatomic, copy, nullable) YBIBImageScrollViewStatusBlock imageDidScrollBlock;

/// 图片缩放的回调
@property (nonatomic, copy, nullable) YBIBImageScrollViewStatusBlock imageDidZoomBlock;

/// 图片布局类 (赋值可自定义)
@property (nonatomic, strong) id<YBIBImageLayout> layout;
/// 默认图片布局类 (可配置其属性)
@property (nonatomic, weak, readonly) YBIBImageLayout *defaultLayout;

/**
 终止处理数据程序
 */
- (void)stopLoading;

/**
 清除缓存的数据
 */
- (void)clearCache;

/**
 加载数据，一般不需要调用这个方法，当该数据对象做了数据更新时调用
 */
- (void)loadData;

/// 处理后的原始图片
@property (nonatomic, strong, readonly) UIImage *originImage;

/// 处理后的压缩图片
@property (nonatomic, strong, readonly) UIImage *compressedImage;

@end

NS_ASSUME_NONNULL_END
