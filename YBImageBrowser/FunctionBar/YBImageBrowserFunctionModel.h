//
//  YBImageBrowserFunctionModel.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

NS_ASSUME_NONNULL_BEGIN

//保存图片的功能，若设置该ID框架会帮你实现此功能
FOUNDATION_EXTERN NSString * const YBImageBrowserFunctionModel_ID_savePictureToAlbum;

@interface YBImageBrowserFunctionModel : NSObject

/**
 功能显示的名字
 */
@property (nonatomic, copy) NSString *name;

/**
 功能的ID（自己定义方便做判断）
 */
@property (nonatomic, copy, nullable) NSString *ID;

/**
 图片
 （在额外操作功能只有一个情况下，YBImageBrowserFunctionBar 不会展示，将会在YBImageBrowserToolBar 右上角显示此图片）
 */
@property (nonatomic, strong, nullable) UIImage *image;

/**
 保存图片的 model 的便利构造（框架内部会处理，只要 ID == YBImageBrowserFunctionModel_ID_savePictureToAlbum）
 @return instancetype
 */
+ (instancetype)functionModelForSavePictureToAlbum;

@end

NS_ASSUME_NONNULL_END
