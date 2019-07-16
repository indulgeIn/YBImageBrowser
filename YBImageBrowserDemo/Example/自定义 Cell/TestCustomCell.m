//
//  TestCustomCell.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestCustomCell.h"
#import "TestCustomData.h"

@interface TestCustomCell ()
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@end

@implementation TestCustomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = UIColor.whiteColor;
}

#pragma mark - <YBIBCellProtocol>

@synthesize yb_cellData = _yb_cellData;
@synthesize yb_hideBrowser = _yb_hideBrowser;

- (void)setYb_cellData:(id<YBIBDataProtocol>)yb_cellData {
    _yb_cellData = yb_cellData;
    
    TestCustomData *data = (TestCustomData *)yb_cellData;
    self.contentLabel.text = data.text;
}

#pragma mark - touch

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.yb_hideBrowser();
}

@end
