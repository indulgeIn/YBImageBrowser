//
//  YBIBCollectionView.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/6.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBCollectionViewLayout.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBIBCollectionView : UICollectionView

@property (nonatomic, strong, readonly) YBIBCollectionViewLayout *layout;

- (NSString *)reuseIdentifierForCellClass:(Class)cellClass;

- (nullable UICollectionViewCell *)centerCell;

- (void)scrollToPage:(NSInteger)page;

@end

NS_ASSUME_NONNULL_END
