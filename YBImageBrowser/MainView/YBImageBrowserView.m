//
//  YBImageBrowserView.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserView.h"
#import "YBImageBrowserCell.h"

@interface YBImageBrowserView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    CGFloat selfHeight;
    CGFloat selfWidth;
}
@end

@implementation YBImageBrowserView

#pragma mark life cycle
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        selfHeight = self.bounds.size.height;
        selfWidth = self.bounds.size.width;
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

#pragma mark *** UICollectionViewDataSource ***
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YBImageBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YBImageBrowserCell" forIndexPath:indexPath];
    [cell loadImageWithModel:self.dataArray[indexPath.row]];
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(selfWidth, selfHeight);
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
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSArray<YBImageBrowserCell *>* array = (NSArray<YBImageBrowserCell *>*)[self visibleCells];
    for (YBImageBrowserCell *cell in array) {
        if (cell.isLoadFailed) {
            [cell reLoad];
        }
    }
}

@end
