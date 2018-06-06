//
//  YBImageBrowserFunctionBar.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserFunctionBar.h"

@interface YBImageBrowserFunctionBar () <UITableViewDelegate, UITableViewDataSource> {
    CGRect showFrameOfTableView;
    CGRect hideFrameOfTableView;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *footer;
@property (nonatomic, assign) BOOL isShow;

@end

@implementation YBImageBrowserFunctionBar

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _heightOfCell = 50;
        _maxScaleOfOperationBar = 0.7;
        _timeOfAnimation = 0.2;
        _isShow = NO;
        _cancelText = @"取消";
        [self addSubview:self.tableView];
    }
    return self;
}

#pragma mark public

- (void)show {
    [self showToView:[UIApplication sharedApplication].keyWindow];
}

- (void)showToView:(UIView *)view {
    if (self.isShow) {
        return;
    }
    self.frame = view.bounds;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    [self resetTableViewFrameWithSuperView:view];
    self.tableView.frame = hideFrameOfTableView;
    [self.tableView reloadData];
    [view addSubview:self];
    [UIView animateWithDuration:self.timeOfAnimation animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.tableView.frame = showFrameOfTableView;
    } completion:^(BOOL finished) {
        self.isShow = YES;
    }];
}

- (void)hide {
    [self hideWithAnimate:YES];
}

- (void)hideWithAnimate:(BOOL)animate {
    if (!self.isShow) {
        return;
    }
    [UIView animateWithDuration:animate?self.timeOfAnimation:0 animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        self.tableView.frame = hideFrameOfTableView;
    } completion:^(BOOL finished) {
        self.isShow = NO;
        [self removeFromSuperview];
    }];
}

- (void)resetTableViewFrameWithSuperView:(UIView *)superView {
    CGRect bounds = superView.bounds;
    
    self.footer.frame = CGRectMake(0, 0, bounds.size.width, YB_HEIGHT_EXTRABOTTOM);
    
    CGFloat maxHeight = self.maxScaleOfOperationBar * bounds.size.height;
    CGFloat cellsHeight = self.heightOfCell * self.dataArray.count + self.heightOfCell+5 + YB_HEIGHT_EXTRABOTTOM;
    CGFloat resultHeight = maxHeight >= cellsHeight ? cellsHeight : maxHeight;
    showFrameOfTableView = CGRectMake(0, bounds.size.height - resultHeight, bounds.size.width, resultHeight);
    hideFrameOfTableView = CGRectMake(0, bounds.size.height, bounds.size.width, resultHeight);
}

#pragma mark setter

- (void)setDataArray:(NSArray<YBImageBrowserFunctionModel *> *)dataArray {
    if (!dataArray || !dataArray.count) {
        YBLOG_WARNING(@"dataArray is invalid");
        return;
    }
    _dataArray = dataArray;
}

- (void)setMaxScaleOfOperationBar:(CGFloat)maxScaleOfOperationBar {
    if (maxScaleOfOperationBar <= 0) {
        YBLOG_WARNING(@"maxScaleOfOperationBar mast be greater than zero");
        return;
    }
    if (maxScaleOfOperationBar > [UIScreen mainScreen].bounds.size.height) {
        _maxScaleOfOperationBar = [UIScreen mainScreen].bounds.size.height;
    } else {
        _maxScaleOfOperationBar = maxScaleOfOperationBar;
    }
}

- (void)setHeightOfCell:(CGFloat)heightOfCell {
    if (heightOfCell <= 0) {
        YBLOG_WARNING(@"heightOfCell mast be greater than zero");
        return;
    }
    _heightOfCell = heightOfCell;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.dataArray.count;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.heightOfCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.001;
    }
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YBImageBrowserFunctionBar"];
    UILabel *label = [cell.contentView viewWithTag:1000];
    UIView *line = [cell.contentView viewWithTag:1001];
    if (!label) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        label = [UILabel new];
        label.textColor = [UIColor darkTextColor];
        label.font = [UIFont italicSystemFontOfSize:16];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = 1000;
        [cell.contentView addSubview:label];
        line = [UIView new];
        line.backgroundColor = [UIColor groupTableViewBackgroundColor];
        line.tag = 1001;
        [cell.contentView addSubview:line];
        
        //有个奇怪的问题，iPhoneX横屏时contentView的宽度并不是全屏，所以这里使用了约束。
        label.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *labelC0 = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint *labelC1 = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        NSLayoutConstraint *labelC2 = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        line.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *lineC0 = [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0.5];
        NSLayoutConstraint *lineC1 = [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint *lineC2 = [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        NSLayoutConstraint *lineC3 = [NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [cell.contentView addConstraints:@[labelC0, labelC1, labelC2, lineC0, lineC1, lineC2, lineC3]];
    }
    if (indexPath.section == 0) {
        label.text = self.dataArray[indexPath.row].name;
        line.hidden = NO;
    } else {
        label.text = _cancelText;
        line.hidden = YES;
    }
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(ybImageBrowserFunctionBar:clickCellWithModel:)]) {
            [_delegate ybImageBrowserFunctionBar:self clickCellWithModel:self.dataArray[indexPath.row]];
        }
        [self hide];
    } else {
        [self hide];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.tableView.frame, point)) {
        [self hide];
    }
}

#pragma mark getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 44;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = self.footer;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.alwaysBounceVertical = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"YBImageBrowserFunctionBar"];
    }
    return _tableView;
}
- (UIView *)footer {
    if (!_footer) {
        _footer = [UIView new];
        _footer.backgroundColor = [UIColor whiteColor];
    }
    return _footer;
}

@end
