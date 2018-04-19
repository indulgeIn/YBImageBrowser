//
//  YBImageBrowserCell.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserModel.h"
#import "YBImageBrowserScreenOrientationProtocol.h"

@class YBImageBrowserCell;

@protocol YBImageBrowserCellDelegate <NSObject>

- (void)yBImageBrowserCell:(YBImageBrowserCell *)imageBrowserCell longPressBegin:(UILongPressGestureRecognizer *)gesture;

- (void)applyForHiddenByYBImageBrowserCell:(YBImageBrowserCell *)imageBrowserCell;

@end

@interface YBImageBrowserCell : UICollectionViewCell <YBImageBrowserScreenOrientationProtocol>

@property (nonatomic, weak) id<YBImageBrowserCellDelegate> delegate;

@property (nonatomic, strong) YBImageBrowserModel *model;

@property (nonatomic, strong, readonly) FLAnimatedImageView *imageView;
@property (nonatomic, strong, readonly) UIImageView *animateImageView;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;
@property (nonatomic, strong) NSString *loadFailedText;
@property (nonatomic, strong) NSString *isScaleImageText;
@property (nonatomic, assign) BOOL cancelDragImageViewAnimation;
@property (nonatomic, assign) CGFloat outScaleOfDragImageViewAnimation;
@property (nonatomic, assign) BOOL autoCountMaximumZoomScale;

- (void)reDownloadImageUrl;

+ (void)countWithContainerSize:(CGSize)containerSize image:(id)image screenOrientation:(YBImageBrowserScreenOrientation)screenOrientation verticalFillType:(YBImageBrowserImageViewFillType)verticalFillType horizontalFillType:(YBImageBrowserImageViewFillType)horizontalFillType completed:(void(^)(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale, CGFloat maximumZoomScale))completed;

@end
