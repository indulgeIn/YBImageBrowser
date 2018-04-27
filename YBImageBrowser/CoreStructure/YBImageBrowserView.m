//
//  YBImageBrowserView.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserView.h"
#import "YBImageBrowserCell.h"
#import "YBImageBrowserViewLayout.h"

static NSString * const YBImageBrowserViewCellIdentifier = @"YBImageBrowserViewCellIdentifier";

@interface YBImageBrowserView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, YBImageBrowserCellDelegate>
@end

@implementation YBImageBrowserView

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self registerClass:YBImageBrowserCell.class forCellWithReuseIdentifier:YBImageBrowserViewCellIdentifier];
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.alwaysBounceVertical = NO;
        self.delegate = self;
        self.dataSource = self;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

#pragma mark private

- (void)scrollToPageWithIndex:(NSInteger)index {
    if (index >= [self collectionView:self numberOfItemsInSection:0]) {
        YBLOG_WARNING(@"index is invalid");
        return;
    }
    self.contentOffset = CGPointMake(self.bounds.size.width * index, 0);
}

#pragma mark YBImageBrowserScreenOrientationProtocol

- (void)so_setFrameInfoWithSuperViewScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation superViewSize:(CGSize)size {
    
    BOOL isVertical = screenOrientation == YBImageBrowserScreenOrientationVertical;
    CGRect rect0 = CGRectMake(0, 0, size.width, size.height), rect1 = CGRectMake(0, 0, size.height, size.width);
    _so_frameOfVertical = isVertical ? rect0 : rect1;
    _so_frameOfHorizontal = !isVertical ? rect0 : rect1;
}

- (void)so_updateFrameWithScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation {
    if (screenOrientation == _so_screenOrientation) return;
    
    _so_isUpdateUICompletely = NO;
    
    self.frame = screenOrientation == YBImageBrowserScreenOrientationVertical ? _so_frameOfVertical : _so_frameOfHorizontal;
    
    _so_screenOrientation = screenOrientation;
    
    [self reloadData];
    [self layoutIfNeeded];
    [self scrollToPageWithIndex:self.currentIndex];
    
    _so_isUpdateUICompletely = YES;
}

#pragma mark YBImageBrowserCellDelegate

- (void)yBImageBrowserCell:(YBImageBrowserCell *)imageBrowserCell longPressBegin:(UILongPressGestureRecognizer *)gesture {
    if (_yb_delegate && [_yb_delegate respondsToSelector:@selector(yBImageBrowserView:longPressBegin:)]) {
        [_yb_delegate yBImageBrowserView:self longPressBegin:gesture];
    }
}

- (void)applyForHiddenByYBImageBrowserCell:(YBImageBrowserCell *)imageBrowserCell {
    if (_yb_delegate && [_yb_delegate respondsToSelector:@selector(applyForHiddenByYBImageBrowserView:)]) {
        [_yb_delegate applyForHiddenByYBImageBrowserView:self];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_yb_dataSource && [_yb_dataSource respondsToSelector:@selector(numberInYBImageBrowserView:)]) {
        return [_yb_dataSource numberInYBImageBrowserView:self];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YBImageBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YBImageBrowserViewCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.isScaleImageText = self.isScaleImageText;
    cell.loadFailedText = self.loadFailedText;
    cell.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
    cell.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
    cell.cancelDragImageViewAnimation = self.cancelDragImageViewAnimation;
    cell.outScaleOfDragImageViewAnimation = self.outScaleOfDragImageViewAnimation;
    cell.autoCountMaximumZoomScale = self.autoCountMaximumZoomScale;
    [cell so_updateFrameWithScreenOrientation:_so_screenOrientation];
    if (_yb_dataSource && [_yb_dataSource respondsToSelector:@selector(yBImageBrowserView:modelForCellAtIndex:)]) {
        cell.model = [_yb_dataSource yBImageBrowserView:self modelForCellAtIndex:indexPath.row];
    } else {
        cell.model = nil;
    }
    return cell;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat indexF = (scrollView.contentOffset.x / scrollView.bounds.size.width);
    NSUInteger index = (NSUInteger)(indexF + 0.5);
    if (index > [self collectionView:self numberOfItemsInSection:0]) return;
    if (self.currentIndex != index && _so_isUpdateUICompletely) {
        self.currentIndex = index;
        if (_yb_delegate && [_yb_delegate respondsToSelector:@selector(yBImageBrowserView:didScrollToIndex:)]) {
            [_yb_delegate yBImageBrowserView:self didScrollToIndex:self.currentIndex];
        }
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSArray<YBImageBrowserCell *>* array = (NSArray<YBImageBrowserCell *>*)[self visibleCells];
    for (YBImageBrowserCell *cell in array) {
        [cell reDownloadImageUrl];
    }
}


@end
