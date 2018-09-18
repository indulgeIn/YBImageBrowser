//
//  CustomCell.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/26.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "CustomCell.h"
#import "CustomCellData.h"

@interface CustomCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;

@end

@implementation CustomCell

@synthesize yb_browserDismissBlock = _yb_browserDismissBlock;

#pragma mark - life cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [UIColor whiteColor];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToTapGesture)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)respondsToTapGesture {
    self.yb_browserDismissBlock();
}

#pragma mark - private

- (void)updateUIWithlayoutDirection:(YBImageBrowserLayoutDirection)layoutDirection {
    NSString *orientation = nil;
    switch (layoutDirection) {
        case YBImageBrowserLayoutDirectionUnknown:
            orientation = @"Unknown";
            break;
        case YBImageBrowserLayoutDirectionVertical:
            orientation = @"Vertical";
            break;
        case YBImageBrowserLayoutDirectionHorizontal:
            orientation = @"Horizontal";
            break;
    }
    self.subTitleLabel.text = [NSString stringWithFormat:@"Layout Direction：%@", orientation];
}

#pragma mark - <YBImageBrowserCellProtocol>

// required method

- (void)yb_initializeBrowserCellWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    if (![data isKindOfClass:CustomCellData.class]) return;
    CustomCellData *cellData = (CustomCellData *)data;
    self.titleLabel.text = cellData.text;
    
    [self updateUIWithlayoutDirection:layoutDirection];
}

// optional method

- (void)yb_browserLayoutDirectionChanged:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    [self updateUIWithlayoutDirection:layoutDirection];
}

@end
