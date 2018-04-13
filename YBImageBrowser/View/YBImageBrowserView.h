//
//  YBImageBrowserView.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"

@class YBImageBrowserView;

@protocol YBImageBrowserViewDelegate <NSObject>

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView didScrollToIndex:(NSUInteger)index;

@end

@interface YBImageBrowserView : UICollectionView

@property (nonatomic, weak) id <YBImageBrowserViewDelegate> yb_delegate;

@property (nonatomic, copy) NSArray<YBImageBrowserModel *> *dataArray;

@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;

- (void)resetUserInterfaceLayout;

@end
