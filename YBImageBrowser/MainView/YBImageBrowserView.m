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
    BOOL isAdjustingDirection; //正在调整方向
}
@end

@implementation YBImageBrowserView

#pragma mark life cycle

- (void)dealloc {
    [downloaderTokens addPointer:NULL];
    [downloaderTokens compact];
    for (id token in downloaderTokens) {
        [[SDWebImageDownloader sharedDownloader] cancel:token];
    }
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        isAdjustingDirection = NO;
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
    }
    return self;
}

#pragma mark public

- (void)resetUserInterfaceLayout {
    isAdjustingDirection = YES;
    self.frame = self.superview.frame;
    for (YBImageBrowserModel *model in self.dataArray) {
        [model setValue:@(YES) forKey:YBImageBrowser_KVCKey_needUpdateUI];
    }
    [self reloadData];
    [self layoutIfNeeded];
    [self scrollToPageWithIndex:self.currentIndex animated:NO];
    isAdjustingDirection = NO;
}

#pragma mark private

- (void)scrollToPageWithIndex:(NSInteger)index animated:(BOOL)animated {
    if (index >= _dataArray.count) {
        YBLogWarning(@" SEL-scrollToPageWithIndex: faild, index is invalid");
        return;
    }
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
}

#pragma mark YBImageBrowserCellDelegate

- (void)yBImageBrowserCell:(YBImageBrowserCell *)yBImageBrowserCell didAddDownLoaderTaskWithToken:(SDWebImageDownloadToken *)token {
    [downloaderTokens addPointer:NULL];
    [downloaderTokens compact];
    [downloaderTokens addPointer:(__bridge void * _Nullable)(token)];
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
    cell.verticalScreenImageViewFillType = self.verticalScreenImageViewFillType;
    cell.horizontalScreenImageViewFillType = self.horizontalScreenImageViewFillType;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat indexF = scrollView.contentOffset.x / scrollView.bounds.size.width;
    if (indexF == (NSUInteger)indexF && !isAdjustingDirection) {
        self.currentIndex = (NSUInteger)indexF;
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
