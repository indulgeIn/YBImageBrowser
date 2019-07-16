//
//  YBIBImageLayout.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/12.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBImageLayout.h"

@implementation YBIBImageLayout

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _verticalFillType = YBIBImageFillTypeCompletely;
        _horizontalFillType = YBIBImageFillTypeFullWidth;
        _zoomScaleSurplus = 1.5;
    }
    return self;
}

#pragma mark - private

- (YBIBImageFillType)fillTypeByOrientation:(UIDeviceOrientation)orientation {
    return UIDeviceOrientationIsLandscape(orientation) ? self.horizontalFillType : self.verticalFillType;
}

#pragma mark - <YBIBImageLayout>

- (CGRect)yb_imageViewFrameWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize orientation:(UIDeviceOrientation)orientation {
    if (containerSize.width <= 0 || containerSize.height <= 0 || imageSize.width <= 0 || imageSize.height <= 0) return CGRectZero;
    
    CGFloat x = 0, y = 0, width = 0, height = 0;
    switch ([self fillTypeByOrientation:orientation]) {
        case YBIBImageFillTypeFullWidth: {
            x = 0;
            width = containerSize.width;
            height = containerSize.width * (imageSize.height / imageSize.width);
            if (imageSize.width / imageSize.height >= containerSize.width / containerSize.height)
                y = (containerSize.height - height) / 2.0;
            else
                y = 0;
        }
            break;
        case YBIBImageFillTypeCompletely: {
            if (imageSize.width / imageSize.height >= containerSize.width / containerSize.height) {
                width = containerSize.width;
                height = containerSize.width * (imageSize.height / imageSize.width);
                x = 0;
                y = (containerSize.height - height) / 2.0;
            } else {
                height = containerSize.height;
                width = containerSize.height * (imageSize.width / imageSize.height);
                x = (containerSize.width - width) / 2.0;
                y = 0;
            }
        }
            break;
        default: return CGRectZero;
    }
    return CGRectMake(x, y, width, height);
}

- (CGFloat)yb_maximumZoomScaleWithContainerSize:(CGSize)containerSize imageSize:(CGSize)imageSize orientation:(UIDeviceOrientation)orientation {
    if (self.maxZoomScale >= 1) return self.maxZoomScale;
    
    if (containerSize.width <= 0 || containerSize.height <= 0) return 0;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale <= 0) return 0;
    
    CGFloat widthScale = imageSize.width / scale / containerSize.width,
    heightScale = imageSize.height / scale / containerSize.height,
    maxScale = 1;
    switch ([self fillTypeByOrientation:orientation]) {
        case YBIBImageFillTypeFullWidth:
            maxScale = widthScale;
            break;
        case YBIBImageFillTypeCompletely:
            maxScale = MAX(widthScale, heightScale);
            break;
        default: return 0;
    }
    return MAX(maxScale, 1) * self.zoomScaleSurplus;
}

@end
