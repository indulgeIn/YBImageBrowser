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

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell didAddDownLoaderTaskWithToken:(SDWebImageDownloadToken *)token;

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell longPressBegin:(UILongPressGestureRecognizer *)gesture;

@end

@interface YBImageBrowserCell : UICollectionViewCell <YBImageBrowserScreenOrientationProtocol>

@property (nonatomic, weak) id<YBImageBrowserCellDelegate> delegate;

@property (nonatomic, strong) YBImageBrowserModel *model;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

@property (nonatomic, strong) NSString *loadFailedText;

@property (nonatomic, strong, readonly) FLAnimatedImageView *imageView;

- (void)reLoad;

+ (void)countWithContainerSize:(CGSize)containerSize image:(id)image screenOrientation:(YBImageBrowserScreenOrientation)screenOrientation verticalFillType:(YBImageBrowserImageViewFillType)verticalFillType horizontalFillType:(YBImageBrowserImageViewFillType)horizontalFillType completed:(void(^)(CGRect imageFrame, CGSize contentSize, CGFloat minimumZoomScale))completed;

@end
