//
//  YBImageBrowserCell.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserModel.h"

@class YBImageBrowserCell;

@protocol YBImageBrowserCellDelegate <NSObject>

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell didAddDownLoaderTaskWithToken:(SDWebImageDownloadToken *)token;

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell longPressBegin:(UILongPressGestureRecognizer *)gesture;

@end

@interface YBImageBrowserCell : UICollectionViewCell

@property (nonatomic, weak) id<YBImageBrowserCellDelegate> delegate;

@property (nonatomic, strong) YBImageBrowserModel *model;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

- (void)reLoad;

- (void)resetUserInterfaceLayout;

@end
