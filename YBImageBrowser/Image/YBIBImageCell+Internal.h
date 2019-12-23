//
//  YBIBImageCell+Internal.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/12/23.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBImageCell.h"
#import "YBIBImageScrollView.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBIBImageCell ()

@property (nonatomic, strong) YBIBImageScrollView *imageScrollView;

@property (nonatomic, strong) UIImageView *tailoringImageView;

@end

NS_ASSUME_NONNULL_END
