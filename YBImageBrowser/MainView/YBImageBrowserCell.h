//
//  YBImageBrowserCell.h
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserTool.h"
#import "YBImageBrowserModel.h"

@interface YBImageBrowserCell : UICollectionViewCell

- (void)loadImageWithModel:(YBImageBrowserModel *)model;

@property (nonatomic, assign) BOOL isLoadFailed;
- (void)reLoad;

@end
