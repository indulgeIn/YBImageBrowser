//
//  YBImageBrowserView.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserView.h"
#import "YBImageBrowseCell.h"
#import "YBImageBrowserViewLayout.h"
#import "YBIBUtilities.h"
#import "YBImageBrowserCellDataProtocol.h"
#import "YBImageBrowserCellProtocol.h"

static NSInteger const preloadCount = 2;

@interface YBImageBrowserView () <UICollectionViewDataSource, UICollectionViewDelegate> {
    NSMutableSet *_reuseIdentifierSet;
    YBImageBrowserLayoutDirection _layoutDirection;
    CGSize _containerSize;
    BOOL _isDealingScreenRotation;
    BOOL _bodyIsInCenter;
    BOOL _isDealedSELInitializeFirst;
    NSCache *_dataCache;
}
@property (nonatomic, assign) NSUInteger currentIndex;
@end

@implementation YBImageBrowserView

#pragma mark - life cycle

- (void)dealloc {
    self->_dataCache = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame collectionViewLayout:[YBImageBrowserViewLayout new]];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self initVars];
        
        self.backgroundColor = [UIColor clearColor];
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.alwaysBounceVertical = NO;
        self.alwaysBounceHorizontal = NO;
        self.delegate = self;
        self.dataSource = self;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (void)initVars {
    self->_layoutDirection = YBImageBrowserLayoutDirectionUnknown;
    self->_reuseIdentifierSet = [NSMutableSet set];
    self->_isDealingScreenRotation = NO;
    self->_bodyIsInCenter = YES;
    self->_currentIndex = NSUIntegerMax;
    self->_isDealedSELInitializeFirst = NO;
    self->_cacheCountLimit = 8;
}

#pragma mark - public

- (void)updateLayoutWithDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    if (self->_layoutDirection == layoutDirection) return;
    self->_isDealingScreenRotation = YES;
    
    self->_containerSize = containerSize;
    self.frame = CGRectMake(0, 0, self->_containerSize.width, self->_containerSize.height);
    self->_layoutDirection = layoutDirection;
    
    if (self.superview) {
        // Notice 'visibleCells' layout direction changed, can't use '-reloadData' because it will triggering '-prepareForReuse' of cell.
        NSArray<UICollectionViewCell<YBImageBrowserCellProtocol> *> *cells = [self visibleCells];
        [cells enumerateObjectsUsingBlock:^(UICollectionViewCell<YBImageBrowserCellProtocol> * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell respondsToSelector:@selector(yb_browserLayoutDirectionChanged:containerSize:)]) {
                [cell yb_browserLayoutDirectionChanged:self->_layoutDirection containerSize:self->_containerSize];
            }
        }];
        [self scrollToPageWithIndex:self.currentIndex];
    }
    
    [self layoutIfNeeded];
    self->_isDealingScreenRotation = NO;
}

- (void)scrollToPageWithIndex:(NSInteger)index {
    if (index >= [self.yb_dataSource yb_numberOfCellForImageBrowserView:self]) {
        // If index overstep the boundary, maximum processing.
        self.currentIndex = [self.yb_dataSource yb_numberOfCellForImageBrowserView:self] - 1;
        self.contentOffset = CGPointMake(self.bounds.size.width * self.currentIndex, 0);
    } else {
        CGPoint targetPoint = CGPointMake(self.bounds.size.width * index, 0);
        if (CGPointEqualToPoint(self.contentOffset, targetPoint)) {
            [self scrollViewDidScroll:self];
        } else {
            self.contentOffset = targetPoint;
        }
    }
}

- (void)yb_reloadData {
    self->_dataCache = nil;
    [self reloadData];
}

- (id<YBImageBrowserCellDataProtocol>)currentData {
    return [self dataAtIndex:self.currentIndex];
}

- (id<YBImageBrowserCellDataProtocol>)dataAtIndex:(NSUInteger)index {
    if (index < 0 || index >= [self.yb_dataSource yb_numberOfCellForImageBrowserView:self]) return nil;
    
    if (!self->_dataCache) {
        self->_dataCache = [NSCache new];
        self->_dataCache.countLimit = self.cacheCountLimit;
    }
    
    id<YBImageBrowserCellDataProtocol> data;
    if (self->_dataCache && [self->_dataCache objectForKey:@(index)]) {
        data = [self->_dataCache objectForKey:@(index)];
    } else {
        data = [self.yb_dataSource yb_imageBrowserView:self dataForCellAtIndex:index];
        [self->_dataCache setObject:data forKey:@(index)];
    }
    return data;
}

- (void)preloadWithCurrentIndex:(NSInteger)index {
    for (NSInteger i = -preloadCount; i <= preloadCount; ++i) {
        if (i == 0) continue;
        id<YBImageBrowserCellDataProtocol> needPreloadData = [self dataAtIndex:index + i];
        if ([needPreloadData respondsToSelector:@selector(yb_preload)]) {
            [needPreloadData yb_preload];
        }
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.yb_dataSource || ![self.yb_dataSource respondsToSelector:@selector(yb_numberOfCellForImageBrowserView:)]) return 0;
    return [self.yb_dataSource yb_numberOfCellForImageBrowserView:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.yb_dataSource || ![self.yb_dataSource respondsToSelector:@selector(yb_imageBrowserView:dataForCellAtIndex:)]) {
        return [UICollectionViewCell new];
    }
    
    id<YBImageBrowserCellDataProtocol> data = [self dataAtIndex:indexPath.row];
    
    NSAssert(data && [data respondsToSelector:@selector(yb_classOfBrowserCell)], @"your custom data must conforms '<YBImageBrowserCellDataProtocol>' and implement '-yb_classOfBrowserCell'");
    Class cellClass = data.yb_classOfBrowserCell;
    NSAssert(cellClass, @"the class get from '-yb_classOfBrowserCell' is invalid");
    
    NSString *identifier = NSStringFromClass(cellClass);
    if (![self->_reuseIdentifierSet containsObject:cellClass]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:identifier ofType:@"nib"];
        if (path) {
            [collectionView registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
        } else {
            [collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
        }
        [self->_reuseIdentifierSet addObject:cellClass];
    }
    UICollectionViewCell<YBImageBrowserCellProtocol> *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    NSAssert(cell, @"your custom cell must be subclass of 'UICollectionViewCell'");
    
    NSAssert([cell respondsToSelector:@selector(yb_initializeBrowserCellWithData:layoutDirection:containerSize:)], @"your custom cell must conforms '<YBImageBrowserCellProtocol>' and implement '-yb_initializeBrowserCellWithData:layoutDirection:containerSize:'");
    [cell yb_initializeBrowserCellWithData:data layoutDirection:self->_layoutDirection containerSize:self->_containerSize];
    
    if ([cell respondsToSelector:@selector(yb_browserStatusBarOrientationBefore:)]) {
        [cell yb_browserStatusBarOrientationBefore:self.statusBarOrientationBefore];
    }
    
    if ([cell respondsToSelector:@selector(setYb_browserDismissBlock:)]) {
        __weak typeof(self) wSelf = self;
        [cell setYb_browserDismissBlock:^{
            __strong typeof(wSelf) sSelf = wSelf;
            [sSelf.yb_delegate yb_imageBrowserViewDismiss:sSelf];
        }];
    }
    
    if ([cell respondsToSelector:@selector(setYb_browserScrollEnabledBlock:)]) {
        __weak typeof(self) wSelf = self;
        [cell setYb_browserScrollEnabledBlock:^(BOOL enabled) {
            __strong typeof(wSelf) sSelf = wSelf;
            sSelf.scrollEnabled = enabled;
        }];
    }
    
    if ([cell respondsToSelector:@selector(setYb_browserChangeAlphaBlock:)]) {
        __weak typeof(self) wSelf = self;
        [cell setYb_browserChangeAlphaBlock:^(CGFloat alpha, CGFloat duration) {
            __strong typeof(wSelf) sSelf = wSelf;
            [sSelf.yb_delegate yb_imageBrowserView:sSelf changeAlpha:alpha duration:duration];
        }];
    }
    
    if ([cell respondsToSelector:@selector(yb_browserSetGestureInteractionProfile:)]) {
        [cell yb_browserSetGestureInteractionProfile:self.giProfile];
    }
    
    if ([cell respondsToSelector:@selector(setYb_browserToolBarHiddenBlock:)]) {
        __weak typeof(self) wSelf = self;
        [cell setYb_browserToolBarHiddenBlock:^(BOOL hidden) {
            __strong typeof(wSelf) sSelf = wSelf;
            [sSelf.yb_delegate yb_imageBrowserView:sSelf hideTooBar:hidden];
        }];
    }
    
    if ([cell respondsToSelector:@selector(yb_browserInitializeFirst:)] && !self->_isDealedSELInitializeFirst) {
        self->_isDealedSELInitializeFirst = YES;
        [cell yb_browserInitializeFirst:self->_currentIndex == indexPath.row];
    }
    
    if (collectionView.window && self.shouldPreload) {
        [self preloadWithCurrentIndex:indexPath.row];
    }
    
    return cell;
}

#pragma mark - <UIScrollViewDelegate>
 
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat indexF = scrollView.contentOffset.x / scrollView.bounds.size.width;
    NSUInteger index = (NSUInteger)(indexF + 0.5);
    
    BOOL isInCenter = indexF <= (NSInteger)indexF + 0.001 && indexF >= (NSInteger)indexF - 0.001;
    if (self->_bodyIsInCenter != isInCenter) {
        self->_bodyIsInCenter = isInCenter;
        
        NSArray<UICollectionViewCell<YBImageBrowserCellProtocol> *> *cells = [self visibleCells];
        [cells enumerateObjectsUsingBlock:^(UICollectionViewCell<YBImageBrowserCellProtocol> * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell respondsToSelector:@selector(yb_browserBodyIsInTheCenter:)]) {
                [cell yb_browserBodyIsInTheCenter:self->_bodyIsInCenter];
            }
        }];
    }
    
    if (index >= [self.yb_dataSource yb_numberOfCellForImageBrowserView:self]) return;
    if (self.currentIndex != index && !self->_isDealingScreenRotation) {
        self.currentIndex = index;
        
        [self.yb_delegate yb_imageBrowserView:self pageIndexChanged:self.currentIndex];
        
        // Notice 'visibleCells' page index changed.
        NSArray<UICollectionViewCell<YBImageBrowserCellProtocol> *> *cells = [self visibleCells];
        [cells enumerateObjectsUsingBlock:^(UICollectionViewCell<YBImageBrowserCellProtocol> * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell respondsToSelector:@selector(yb_browserPageIndexChanged:ownIndex:)]) {
                [cell yb_browserPageIndexChanged:self.currentIndex ownIndex:[self indexPathForCell:cell].row];
            }
        }];
    }
}

#pragma mark - hit-test

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    // When the hit-test view is 'UISlider', set '_scrollEnabled' to 'NO', avoid gesture conflicts.
    self.scrollEnabled = ![view isKindOfClass:UISlider.class];
    return view;
}

@end
