//
//  YBImageBrowserViewLayout.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/17.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserViewLayout.h"

@implementation YBImageBrowserViewLayout

- (void)prepareLayout {
    [super prepareLayout];
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGRect bounds = self.collectionView.bounds;
    self.itemSize = CGSizeMake(bounds.size.width, bounds.size.height);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.sectionInset = UIEdgeInsetsZero;
}

//- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
//    NSArray<UICollectionViewLayoutAttributes *> *layoutAttsArray = [super layoutAttributesForElementsInRect:rect];
//    CGFloat centerX = self.collectionView.frame.size.width / 2 + self.collectionView.contentOffset.x;
//    
//    __block CGFloat minDistance = CGFLOAT_MAX;
//    __block NSIndexPath *indexPath;
//    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (ABS(obj.center.x - centerX) < minDistance) {
//            minDistance = ABS(obj.center.x - centerX);
//            indexPath = obj.indexPath;
//        }
//    }];
//    
//    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        obj.center = CGPointMake(obj.center.x - indexPath.row*self.minimumLineSpacing, obj.center.y);
//    }];
    
//    return layoutAttsArray;
//}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
