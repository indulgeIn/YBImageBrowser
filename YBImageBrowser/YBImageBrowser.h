//
//  YBImageBrowser.h
//
//  Github : https://github.com/indulgeIn/YBImageBrowser
//  Blog : https://www.jianshu.com/p/bffdb9f0036c
//
//  Created by 杨波 on 2018/8/24.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserDataSource.h"
#import "YBImageBrowserDelegate.h"
#import "YBImageBrowseCellData.h"
#import "YBVideoBrowseCellData.h"
#import "YBIBGestureInteractionProfile.h"
#import "YBImageBrowserToolBarProtocol.h"
#import "YBImageBrowserSheetViewProtocol.h"
#import "YBImageBrowserToolBar.h"
#import "YBImageBrowserSheetView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBImageBrowserTransitionType) {
    YBImageBrowserTransitionTypeNone,
    YBImageBrowserTransitionTypeFade,
    YBImageBrowserTransitionTypeCoherent
};

@interface YBImageBrowser : UIViewController

/** Usually, use this array to configure data sources. Array elements can be 'YBImageBrowseCellData', 'YBVideoBrowseCellData'. */
@property (nonatomic, copy) NSArray<id<YBImageBrowserCellDataProtocol>> *dataSourceArray;

/** When you need to reduce memory footprint, use this proxy to configure data sources. */
@property (nonatomic, weak) id<YBImageBrowserDataSource> dataSource;

/** Set this proxy to get some useful callbacks. */
@property (nonatomic, weak) id<YBImageBrowserDelegate> delegate;

/** Set or get the index of the current page. */
@property (nonatomic, assign) NSUInteger currentIndex;

/**
 Show image browser.
 */
- (void)show;

/**
 Show image browser from target 'UIViewController'.
 Used 'presentViewController:animated:completion:'.
 */
- (void)showFromController:(UIViewController *)fromController;

/**
 Hide image browser.
 Normally, you do not need to call this method explicitly.
 */
- (void)hide;

/**
 Refresh display, you need to ensure that the data source is changed correctly.
 */
- (void)reloadData;

/**
 Get current data of image browser.
 
 @return the current data.
 */
- (id<YBImageBrowserCellDataProtocol>)currentData;

/** The default is YES. */
@property (nonatomic, assign) BOOL shouldPreload;


/** The default is 'UIInterfaceOrientationMaskAllButUpsideDown'. */
@property (nonatomic, assign) UIInterfaceOrientationMask supportedOrientations;

/** The default is 20. */
@property (nonatomic, assign) CGFloat distanceBetweenPages;

/** The default is black. */
@property (nonatomic, strong) UIColor *backgroundColor;

/** Automatically hide source objects. What is the source object, see 'YBImageBrowseCellData' or 'YBVideoBrowseCellData' */
@property (nonatomic, assign) BOOL autoHideSourceObject;


/** The default is 'YBImageBrowserTransitionTypeCoherent'. */
@property (nonatomic, assign) YBImageBrowserTransitionType enterTransitionType;

/** The default is 'YBImageBrowserTransitionTypeCoherent'. */
@property (nonatomic, assign) YBImageBrowserTransitionType outTransitionType;

/** The default is 0.25. */
@property (nonatomic, assign) NSTimeInterval transitionDuration;

/** Parameter configuration object for gesture interaction animation. */
@property (nonatomic, strong) YBIBGestureInteractionProfile *giProfile;


/** Default 'toolBar', you can configure some parameters */
@property (nonatomic, weak, readonly) YBImageBrowserToolBar *defaultToolBar;

/** The array contains 'defaultToolBar', and you can customize several 'toolBar'. You don't need to care about the view hierarchy of the 'toolBars', and just need to update the UI according to the protocol method.*/
@property (nonatomic, copy) NSArray<__kindof UIView<YBImageBrowserToolBarProtocol> *> *toolBars;

/** Default 'sheetView', you can configure some parameters */
@property (nonatomic, weak, readonly) YBImageBrowserSheetView *defaultSheetView;

/** The default is 'defaultSheetView', and you can customize 'sheetView'. You don't need to care about the view hierarchy of 'sheetView', and just need to update the UI according to the protocol method. */
@property (nonatomic, strong) __kindof UIView<YBImageBrowserSheetViewProtocol> *sheetView;


/** The default is YES. */
@property (nonatomic, assign) BOOL shouldHideStatusBar;

/** The number of data cache limits, the default is 6. It is effective when using the proxy to configure data sources. If the data cache is overmuch, may lead to excessive memory consumption. */
@property (nonatomic, assign) NSUInteger dataCacheCountLimit;

@end

NS_ASSUME_NONNULL_END
