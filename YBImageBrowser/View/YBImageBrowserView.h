//
//  YBImageBrowserView.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"

@interface YBImageBrowserView : UICollectionView

@property (nonatomic, strong) NSArray<YBImageBrowserModel *> *dataArray;

@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

- (void)resetUserInterfaceLayout;

@end
