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
    self.minimumLineSpacing = 20;
    self.minimumInteritemSpacing = 0;
    self.sectionInset = UIEdgeInsetsZero;
}

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttsArray = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    CGFloat centerX = self.collectionView.frame.size.width / 2 + self.collectionView.contentOffset.x;
    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes  *_Nonnull atts, NSUInteger idx, BOOL * _Nonnull stop) {
        atts.center = CGPointMake(atts.center.x + (atts.center.x - centerX), atts.center.y);
    }];
    return layoutAttsArray;
}

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
