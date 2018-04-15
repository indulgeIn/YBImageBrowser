//
//  YBImageBrowserScreenOrientationProtocol.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/15.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserUtilities.h"

/**
 屏幕方向协议
 （和屏幕旋转更新UI有关）
 */
@protocol YBImageBrowserScreenOrientationProtocol <NSObject>

@required

/**
 当前视图UI适配的屏幕方向
 */
@property (nonatomic, assign) YBImageBrowserScreenOrientation so_screenOrientation;

/**
 当前视图在竖直屏幕的frame
 */
@property (nonatomic, assign) CGRect so_frameOfVertical;

/**
 当前视图在横向屏幕的frame
 */
@property (nonatomic, assign) CGRect so_frameOfHorizontal;

/**
 更新约束是否完成
 */
@property (nonatomic, assign) BOOL so_isUpdateUICompletely;

- (void)so_setFrameInfoWithSuperViewScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation superViewSize:(CGSize)size;

- (void)so_updateFrameWithScreenOrientation:(YBImageBrowserScreenOrientation)screenOrientation;

@end
