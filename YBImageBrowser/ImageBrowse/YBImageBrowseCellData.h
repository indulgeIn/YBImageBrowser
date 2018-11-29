//
//  YBImageBrowseCellData.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "YBImageBrowserCellDataProtocol.h"
#import "YBImage.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YBImageBrowseFillType) {
    YBImageBrowseFillTypeUnknown,
    // The width of the image is up to the width of the screen, the height automatic adaptation.
    YBImageBrowseFillTypeFullWidth,
    // The image maximization display but ensure integrity.
    YBImageBrowseFillTypeCompletely
};

/** It's recommended to use 'YBImage'. */
typedef __kindof UIImage * _Nullable (^YBIBLocalImageBlock)(void);


@interface YBImageBrowseCellData : NSObject <YBImageBrowserCellDataProtocol>

/** For local image.
 It's recommended to use 'YBImage', the usage of 'YBImage' is the same as 'UIImage', support GIF, WebP and APNG. */
@property (nonatomic, copy, nullable) YBIBLocalImageBlock imageBlock;

/** For network image.
 The network address of image. */
@property (nonatomic, strong, nullable) NSURL *url;

/** Image from the system album */
@property (nonatomic, strong, nullable) PHAsset *phAsset;

/** The source rendering object corresponding to the current data model, it's used for animation.
 In general, it's 'UIImageView', but it can also be 'UIView' or 'CALayer'. */
@property (nonatomic, weak, nullable) id sourceObject;

/** As a preview image. It's usually a low quality image.
 If 'sourceObject' is valid and is kind of 'UIImageView', it will automatic setting 'thumbImage'. */
@property (nonatomic, strong, nullable) UIImage *thumbImage;

/** As a preview image. It's invalid if it is not found in the cache. */
@property (nonatomic, strong, nullable) NSURL *thumbUrl;

/** The final image. */
@property (nonatomic, strong, readonly, nullable) YBImage *image;

/** The maximum zoom scale of image, must be greater than or equal to 1.
 If there is no explicit settings, it will automatically calculate through the image's pixel. */
@property (nonatomic, assign) CGFloat maxZoomScale;

/** When the zoom scale is automatically calculated, the result multiplied by this surplus as the final scaling. The defalut is 1.5. */
@property (nonatomic, class) CGFloat globalZoomScaleSurplus;

/** The maximum texture size, defalut is '(CGSize){4096, 4096}'.
When the image exceeds this texture size, it will be compressed asynchronously and cut asynchronously.
 It is best to set this value before instantiating all variables.
 */
@property (nonatomic, class) CGSize globalMaxTextureSize;

/** The default is 'YBImageBrowseFillTypeFullWidth'. */
@property (nonatomic, class) YBImageBrowseFillType globalVerticalfillType;

/** The default is 'YBImageBrowseFillTypeFullWidth'. */
@property (nonatomic, class) YBImageBrowseFillType globalHorizontalfillType;

/** The current instance variable will ignore the global configuration when this value is valid. */
@property (nonatomic, assign) YBImageBrowseFillType verticalfillType;

/** The current instance variable will ignore the global configuration when this value is valid. */
@property (nonatomic, assign) YBImageBrowseFillType horizontalfillType;

/** The default is YES. */
@property (nonatomic, assign) BOOL allowSaveToPhotoAlbum;

/** The default is YES. */
@property (nonatomic, assign) BOOL allowShowSheetView;

/** You can set any data. */
@property (nonatomic, strong, nullable) id extraData;

/** The default is YES.
 If the image decoding lead to interactive caton, you can set it to YES. When decoding asynchronously, there will be more time consumption. */
@property (nonatomic, class) BOOL shouldDecodeAsynchronously;

@end

NS_ASSUME_NONNULL_END
