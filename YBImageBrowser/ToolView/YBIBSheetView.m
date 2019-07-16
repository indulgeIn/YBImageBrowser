//
//  YBIBSheetView.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/6.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBSheetView.h"
#import "YBIBUtilities.h"
#import "YBIBCopywriter.h"


@implementation YBIBSheetAction
+ (instancetype)actionWithName:(NSString *)name action:(YBIBSheetActionBlock)action {
    YBIBSheetAction *sheetAction = [YBIBSheetAction new];
    sheetAction.name = name;
    sheetAction.action = action;
    return sheetAction;
}
@end


@interface YBIBSheetCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CALayer *line;
@end
@implementation YBIBSheetCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _titleLabel = [UILabel new];
        _titleLabel.textColor = UIColor.darkTextColor;
        _titleLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _line = [CALayer new];
        _line.backgroundColor = UIColor.groupTableViewBackgroundColor.CGColor;
        [self.contentView addSubview:_titleLabel];
        [self.contentView.layer addSublayer:_line];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width, height = self.contentView.bounds.size.height;
    CGFloat lineHeight = 0.5;
    _line.frame = CGRectMake(0, height - lineHeight, width, lineHeight);
    CGFloat offset = 15;
    _titleLabel.frame = CGRectMake(offset, 0, width - offset * 2, height);
}
@end


static CGFloat kOffsetSpace = 5;

@interface YBIBSheetView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation YBIBSheetView {
    CGRect _tableShowFrame;
    CGRect _tableHideFrame;
}

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cancelText = [YBIBCopywriter sharedCopywriter].cancel;
        _maxHeightScale = 0.7;
        _showDuration = 0.2;
        _hideDuration = 0.1;
        _cellHeight = 50;
        _backAlpha = 0.3;
        _actions = [NSMutableArray array];
        
        [self addSubview:self.tableView];
    }
    return self;
}

#pragma mark - public

- (void)showToView:(UIView *)view orientation:(UIDeviceOrientation)orientation {
    if (self.actions.count == 0) return;
    
    [view addSubview:self];
    self.frame = view.bounds;
    
    UIEdgeInsets padding = YBIBPaddingByBrowserOrientation(orientation);
    
    CGFloat footerHeight = padding.bottom;
    CGFloat tableHeight = self.cellHeight * (self.actions.count + 1) + kOffsetSpace + footerHeight;
    
    _tableShowFrame = self.frame;
    _tableShowFrame.size.height = MIN(self.maxHeightScale * self.bounds.size.height, tableHeight);
    _tableShowFrame.origin.y = self.bounds.size.height - _tableShowFrame.size.height;
    
    _tableHideFrame = _tableShowFrame;
    _tableHideFrame.origin.y = self.bounds.size.height;
    
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.tableView.frame = _tableHideFrame;
    self.tableView.tableFooterView.bounds = CGRectMake(0, 0, self.tableView.frame.size.width, footerHeight);
    [UIView animateWithDuration:self.showDuration animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:self->_backAlpha];
        self.tableView.frame = self->_tableShowFrame;
    }];
}

- (void)hideWithAnimation:(BOOL)animation {
    if (!self.superview) return;
    
    void(^animationsBlock)(void) = ^{
        self.tableView.frame = self->_tableHideFrame;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    };
    void(^completionBlock)(BOOL n) = ^(BOOL n){
        [self removeFromSuperview];
    };
    if (animation) {
        [UIView animateWithDuration:self.hideDuration animations:animationsBlock completion:completionBlock];
    } else {
        animationsBlock();
        completionBlock(NO);
    }
}

#pragma mark - touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.tableView.frame, point)) {
        [self hideWithAnimation:YES];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.actions.count : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? CGFLOAT_MIN : kOffsetSpace;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YBIBSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(YBIBSheetCell.self)];
    if (indexPath.section == 0) {
        cell.line.hidden = NO;
        YBIBSheetAction *action = self.actions[indexPath.row];
        cell.titleLabel.text = action.name;
    } else {
        cell.line.hidden = YES;
        cell.titleLabel.text = self.cancelText;
    }
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        YBIBSheetAction *action = self.actions[indexPath.row];
        if (action.action) action.action(self.currentdata());
    } else {
        [self hideWithAnimation:YES];
    }
}

#pragma mark - getters

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 44;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.alwaysBounceVertical = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        UIView *footer = [UIView new];
        footer.backgroundColor = UIColor.whiteColor;
        _tableView.tableFooterView = footer;
        [_tableView registerClass:YBIBSheetCell.self forCellReuseIdentifier:NSStringFromClass(YBIBSheetCell.self)];
    }
    return _tableView;
}

@end
