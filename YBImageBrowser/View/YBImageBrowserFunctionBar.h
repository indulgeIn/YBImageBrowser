//
//  YBImageBrowserFunctionBar.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"


FOUNDATION_EXTERN NSString * const YBImageBrowserFunctionModel_ID_savePictureToAlbum;

@class YBImageBrowserFunctionBar;

@interface YBImageBrowserFunctionModel : NSObject

/**
 功能显示的名字
 */
@property (nonatomic, copy) NSString *name;

/**
 功能的ID（自己定义方便做判断）
 */
@property (nonatomic, copy) NSString *ID;

/**
 保存图片的 model 的便利构造
 @return --
 */
+ (instancetype)functionModelForSavePictureToAlbum;

@end


@protocol YBImageBrowserFunctionBarDelegate <NSObject>

- (void)ybImageBrowserFunctionBar:(YBImageBrowserFunctionBar *)functionBar clickCellWithModel:(YBImageBrowserFunctionModel *)model;

@end

@interface YBImageBrowserFunctionBar : UIView

@property (nonatomic, weak) id <YBImageBrowserFunctionBarDelegate> delegate;

/**
 数据源（默认只有一个存储）
 */
@property (nonatomic, copy) NSArray<YBImageBrowserFunctionModel *> *dataArray;

/**
 每一项的高度（默认50）
 */
@property (nonatomic, assign) CGFloat heightOfCell;

/**
 操作栏占最大可视高度的比例（默认0.7）
 */
@property (nonatomic, assign) CGFloat maxScaleOfOperationBar;

/**
 展示到view
 @param view 目标view
 */
- (void)showToView:(UIView *)view;

/**
 隐藏
 */
- (void)hide;

/**
 转场动画持续时间
 */
@property (nonatomic, assign) CGFloat timeOfAnimation;

/**
 当前是否是展示状态
 */
@property (nonatomic, assign, readonly) BOOL isShow;

- (void)resetUserInterfaceLayout;

@end
