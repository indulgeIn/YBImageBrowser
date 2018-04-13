//
//  YBImageBrowserCell.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"

@class YBImageBrowserCell;

@protocol YBImageBrowserCellDelegate <NSObject>

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell didAddDownLoaderTaskWithToken:(SDWebImageDownloadToken *)token;

@end

@interface YBImageBrowserCell : UICollectionViewCell

@property (nonatomic, strong) YBImageBrowserModel *model;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

@property (nonatomic, weak) id delegate;

- (void)reLoad;

- (void)resetUserInterfaceLayout;

@end
