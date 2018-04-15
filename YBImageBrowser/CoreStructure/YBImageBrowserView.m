//
//  YBImageBrowserView.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserView.h"
#import "YBImageBrowserCell.h"

@interface YBImageBrowserView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, YBImageBrowserCellDelegate> {
    NSPointerArray *downloaderTokens;
}
@end

@implementation YBImageBrowserView

@synthesize so_screenOrientation = _so_screenOrientation;
@synthesize so_frameOfVertical = _so_frameOfVertical;
@synthesize so_frameOfHorizontal = _so_frameOfHorizontal;
@synthesize so_isUpdateUICompletely = _so_isUpdateUICompletely;

#pragma mark life cycle

- (void)dealloc {
    [self cancelAllDownloadTask];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        downloaderTokens = [NSPointerArray weakObjectsPointerArray];
        [self registerClass:YBImageBrowserCell.class forCellWithReuseIdentifier:@"YBImageBrowserCell"];
        self.collectionViewLayout = layout;
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.alwaysBounceVertical = NO;
        self.delegate = self;
        self.dataSource = self;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self visibleCells];
    }
    return self;
}

#pragma mark private

- (void)scrollToPageWithIndex:(NSInteger)index animated:(BOOL)animated {
    if (index >= _dataArray.count) {
        YBLOG_WARNING(@"index is invalid")
        return;
    }
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
}

- (void)cancelAllDownloadTask {
    [downloaderTokens addPointer:NULL];
    [downloaderTokens compact];
    for (id token in downloaderTokens) {
        [[SDWebImageDownloader sharedDownloader] cancel:token];
    }
}

#pragma mark setter

- (void)setDataArray:(NSArray<YBImageBrowserModel *> *)dataArray {
    if (!dataArray || !dataArray.count) {
        YBLOG_WARNING(@"dataArray is invalid")
        return;
    }
    _dataArray = dataArray;
    [self cancelAllDownloadTask];
    [self reloadData];
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
    [self scrollToPageWithIndex:self.currentIndex animated:NO];
    
    _so_isUpdateUICompletely = YES;
}

#pragma mark YBImageBrowserCellDelegate

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell didAddDownLoaderTaskWithToken:(SDWebImageDownloadToken *)token {
    [downloaderTokens addPointer:NULL];
    [downloaderTokens compact];
    [downloaderTokens addPointer:(__bridge void * _Nullable)(token)];
}

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell longPressBegin:(UILongPressGestureRecognizer *)gesture {
    if (_yb_delegate && [_yb_delegate respondsToSelector:@selector(yBImageBrowserView:longPressBegin:)]) {
        [_yb_delegate yBImageBrowserView:self longPressBegin:gesture];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YBImageBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YBImageBrowserCell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.loadFailedText = self.loadFailedText;
    cell.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
    cell.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
    [cell so_updateFrameWithScreenOrientation:_so_screenOrientation];
    cell.model = self.dataArray[indexPath.row];
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = collectionView.bounds.size;
    return CGSizeMake(size.width, size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

#pragma mark UIScrollViewDelegate
//  0.0-0.5 - 0   0.5-1.5 - 1   1.5-2.5 - 2  ......
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger index = (NSUInteger)((scrollView.contentOffset.x / scrollView.bounds.size.width) + 0.5);
    if (index > self.dataArray.count) return;
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
        if ([[cell.model valueForKey:YBImageBrowser_KVCKey_isLoadFailed] boolValue]) {
            [cell reLoad];
        }
    }
}

@end
