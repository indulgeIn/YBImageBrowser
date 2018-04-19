//
//  YBImageBrowserView.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"
#import "YBImageBrowserModel.h"
#import "YBImageBrowserScreenOrientationProtocol.h"

@class YBImageBrowserView;

@protocol YBImageBrowserViewDelegate <NSObject>

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView didScrollToIndex:(NSUInteger)index;

- (void)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView longPressBegin:(UILongPressGestureRecognizer *)gesture;

- (void)applyForHiddenByYBImageBrowserView:(YBImageBrowserView *)imageBrowserView;

@end

@protocol YBImageBrowserViewDataSource <NSObject>

- (NSInteger)numberInYBImageBrowserView:(YBImageBrowserView *)imageBrowserView;

- (YBImageBrowserModel *)yBImageBrowserView:(YBImageBrowserView *)imageBrowserView modelForCellAtIndex:(NSInteger)index;

@end

@interface YBImageBrowserView : UICollectionView <YBImageBrowserScreenOrientationProtocol>

@property (nonatomic, weak) id <YBImageBrowserViewDelegate> yb_delegate;
@property (nonatomic, weak) id <YBImageBrowserViewDataSource> yb_dataSource;

@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, assign) YBImageBrowserImageViewFillType verticalScreenImageViewFillType;
@property (nonatomic, assign) YBImageBrowserImageViewFillType horizontalScreenImageViewFillType;
@property (nonatomic, strong) NSString *loadFailedText;
@property (nonatomic, strong) NSString *isScaleImageText;
@property (nonatomic, assign) BOOL cancelDragImageViewAnimation;
@property (nonatomic, assign) CGFloat outScaleOfDragImageViewAnimation;
@property (nonatomic, assign) BOOL autoCountMaximumZoomScale;

- (void)scrollToPageWithIndex:(NSInteger)index;

@end
