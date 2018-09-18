//
//  YBImageBrowserSheetView.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBImageBrowserSheetViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kYBImageBrowserSheetActionIdentitySaveToPhotoAlbum;

typedef void(^YBImageBrowserSheetActionBlock)(id<YBImageBrowserCellDataProtocol> data);

@interface YBImageBrowserSheetAction : NSObject

/** The name of 'action' */
@property (nonatomic, copy) NSString *name;

/** If 'identity' set to 'kYBImageBrowserSheetActionIdentitySaveToPhotoAlbum', it will implement the function of saving image automatically and without callback. */
@property (nonatomic, copy, nullable) NSString *identity;

/** Callback. */
@property (nonatomic, copy, nullable) YBImageBrowserSheetActionBlock action;

+ (instancetype)actionWithName:(NSString *)name identity:(NSString * _Nullable)identity action:(_Nullable YBImageBrowserSheetActionBlock)action;

@end


@interface YBImageBrowserSheetView : UIView <YBImageBrowserSheetViewProtocol>

/** The array count must be greater than or equal to 1 */
@property (nonatomic, copy) NSArray<YBImageBrowserSheetAction *> *actions;

@property (nonatomic, assign) CGFloat heightOfCell;

@property (nonatomic, copy) NSString *cancelText;

@property (nonatomic, assign) CGFloat maxHeightScale;

@property (nonatomic, assign) NSTimeInterval animateDuration;

@end


NS_ASSUME_NONNULL_END
