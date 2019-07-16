//
//  YBIBImageScrollView.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/10.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBImage.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBIBScrollImageType) {
    YBIBScrollImageTypeNone,
    YBIBScrollImageTypeOriginal,
    YBIBScrollImageTypeCompressed,
    YBIBScrollImageTypeThumb
};

@interface YBIBImageScrollView : UIScrollView

- (void)setImage:(__kindof UIImage *)image type:(YBIBScrollImageType)type;

@property (nonatomic, strong, readonly) YYAnimatedImageView *imageView;

@property (nonatomic, assign) YBIBScrollImageType imageType;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
