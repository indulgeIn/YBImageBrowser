//
//  YBIBTopView.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/6.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBIBTopViewOperationType) {
    YBIBTopViewOperationTypeSave,   //保存
    YBIBTopViewOperationTypeMore    //更多
};

@interface YBIBTopView : UIView

/// 页码标签
@property (nonatomic, strong, readonly) UILabel *pageLabel;

/// 操作按钮（自定义：直接修改图片或文字，然后添加点击事件）
@property (nonatomic, strong, readonly) UIButton *operationButton;

/// 按钮类型
@property (nonatomic, assign) YBIBTopViewOperationType operationType;

/**
 设置页码

 @param page 当前页码
 @param totalPage 总页码数
 */
- (void)setPage:(NSInteger)page totalPage:(NSInteger)totalPage;

/// 点击操作按钮的回调
@property (nonatomic, copy) void(^clickOperation)(YBIBTopViewOperationType type);

+ (CGFloat)defaultHeight;

@end

NS_ASSUME_NONNULL_END
