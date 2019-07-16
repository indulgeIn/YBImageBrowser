//
//  BaseListCell.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseListCell : UICollectionViewCell

@property (nonatomic, strong) id data;

@property (weak, nonatomic) IBOutlet UIImageView *contentImgView;

@end

NS_ASSUME_NONNULL_END
