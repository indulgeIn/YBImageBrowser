//
//  YBImageBrowserView.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserDataSource.h"
#import "YBIBLayoutDirectionManager.h"
#import "YBIBUtilities.h"
#import "YBIBGestureInteractionProfile.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YBImageBrowserViewDelegate <NSObject>

@required

- (void)yb_imageBrowserViewDismiss:(YBImageBrowserView *)browserView;

- (void)yb_imageBrowserView:(YBImageBrowserView *)browserView changeAlpha:(CGFloat)alpha duration:(NSTimeInterval)duration;

- (void)yb_imageBrowserView:(YBImageBrowserView *)browserView pageIndexChanged:(NSUInteger)index;

- (void)yb_imageBrowserView:(YBImageBrowserView *)browserView hideTooBar:(BOOL)hidden;

@end

@interface YBImageBrowserView : UICollectionView

@property (nonatomic, weak) id<YBImageBrowserDataSource> yb_dataSource;

@property (nonatomic, weak) UIViewController<YBImageBrowserViewDelegate> *yb_delegate;

@property (nonatomic, assign, readonly) NSUInteger currentIndex;

- (id<YBImageBrowserCellDataProtocol>)currentData;

- (id<YBImageBrowserCellDataProtocol>)dataAtIndex:(NSUInteger)index;

- (void)preloadWithCurrentIndex:(NSInteger)index;

- (void)updateLayoutWithDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize;

- (void)scrollToPageWithIndex:(NSInteger)index;

- (void)yb_reloadData;

@property (nonatomic, strong) YBIBGestureInteractionProfile *giProfile;

@property (nonatomic, assign) UIInterfaceOrientation statusBarOrientationBefore;

@property (nonatomic, assign) NSUInteger cacheCountLimit;

@property (nonatomic, assign) BOOL shouldPreload;

@end

NS_ASSUME_NONNULL_END
