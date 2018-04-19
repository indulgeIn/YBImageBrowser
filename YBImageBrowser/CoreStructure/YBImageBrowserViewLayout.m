//
//  YBImageBrowserViewLayout.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/17.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserViewLayout.h"

@interface YBImageBrowserViewLayout () {
    CGFloat collectionViewWidth;
    CGFloat totalOffsetX;    //需要左移的总共距离
    CGFloat maxOffsetX;    //最大偏移
}

@end

@implementation YBImageBrowserViewLayout

- (void)prepareLayout {
    [super prepareLayout];
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    collectionViewWidth = self.collectionView.bounds.size.width;
    CGFloat height = self.collectionView.bounds.size.height;
    self.itemSize = CGSizeMake(collectionViewWidth, height);
    NSInteger number = [self.collectionView numberOfItemsInSection:0];
    totalOffsetX = self.minimumLineSpacing * (number - 1);
    maxOffsetX = self.collectionView.bounds.size.width * (number - 1);
    self.sectionInset = UIEdgeInsetsMake(0, 0, 0, - totalOffsetX);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttsArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
    if (self->maxOffsetX <= 0) {
        return layoutAttsArray;
    }
    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.center = CGPointMake(obj.center.x - (self.collectionView.contentOffset.x / self->maxOffsetX) * self->totalOffsetX, obj.center.y);
    }];
    return layoutAttsArray;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
