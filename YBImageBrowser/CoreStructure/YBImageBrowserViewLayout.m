//
//  YBImageBrowserViewLayout.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/17.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserViewLayout.h"

@interface YBImageBrowserViewLayout ()

@end

@implementation YBImageBrowserViewLayout

- (void)prepareLayout {
    [super prepareLayout];
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGSize size = self.collectionView.bounds.size;
    self.itemSize = CGSizeMake(size.width, size.height);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttsArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.bounds.size.width/2.0;
    __block CGFloat min = CGFLOAT_MAX;
    __block NSUInteger minIdx;
    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (ABS(centerX-obj.center.x) < min) {
            min = ABS(centerX-obj.center.x);
            minIdx = idx;
        }
    }];
    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (minIdx - 1 == idx) {
            obj.center = CGPointMake(obj.center.x-self.distanceBetweenPages, obj.center.y);
        }
        if (minIdx + 1 == idx) {
            obj.center = CGPointMake(obj.center.x+self.distanceBetweenPages, obj.center.y);
        }
    }];
    return layoutAttsArray;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
