//
//  YBImageBrowserFunctionBar.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserFunctionBar.h"


NSString * const YBImageBrowserFunctionModel_ID_savePictureToAlbum = @"YBImageBrowserFunctionModel_ID_savePictureToAlbum";

@implementation YBImageBrowserFunctionModel

+ (instancetype)functionModelForSavePictureToAlbum {
    YBImageBrowserFunctionModel *model = [YBImageBrowserFunctionModel new];
    model.name = @"保存图片";
    model.ID = YBImageBrowserFunctionModel_ID_savePictureToAlbum;
    return model;
}

@end


@interface YBImageBrowserFunctionBar () <UITableViewDelegate, UITableViewDataSource> {
    CGRect showFrameOfTableView;
    CGRect hideFrameOfTableView;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isShow;

@end

@implementation YBImageBrowserFunctionBar

#pragma mark life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.heightOfCell = 50;
        self.maxScaleOfOperationBar = 0.7;
        self.timeOfAnimation = 0.2;
        self.isShow = NO;
        [self resetUserInterfaceLayout];
        [self addSubview:self.tableView];
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    }
    return self;
}

#pragma mark public

- (void)showToView:(UIView *)view {
    if (self.isShow) {
        return;
    }
    self.frame = view.bounds;
    [view addSubview:self];
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.tableView.frame = hideFrameOfTableView;
    [UIView animateWithDuration:self.timeOfAnimation animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.tableView.frame = showFrameOfTableView;
    } completion:^(BOOL finished) {
        self.isShow = YES;
    }];
}

- (void)hide {
    if (!self.isShow) {
        return;
    }
    [UIView animateWithDuration:self.timeOfAnimation animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        self.tableView.frame = hideFrameOfTableView;
    } completion:^(BOOL finished) {
        self.isShow = NO;
        [self removeFromSuperview];
    }];
}

- (void)resetUserInterfaceLayout {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat maxHeight = self.maxScaleOfOperationBar * bounds.size.height;
    CGFloat cellsHeight = self.heightOfCell * self.dataArray.count + self.heightOfCell+5;
    CGFloat resultHeight = maxHeight >= cellsHeight ? cellsHeight : maxHeight;
    showFrameOfTableView = CGRectMake(0, bounds.size.height - resultHeight, bounds.size.width, resultHeight);
    hideFrameOfTableView = CGRectMake(0, bounds.size.height, bounds.size.width, resultHeight);
    if (_isShow) {
        self.frame = bounds;
        self.tableView.frame = showFrameOfTableView;;
        [self.tableView reloadData];
    }
}

#pragma mark setter

- (void)setDataArray:(NSArray<YBImageBrowserFunctionModel *> *)dataArray {
    if (!dataArray || dataArray.count == 0) {
        YBLOG_WARNING(@"class-YBImageBrowserFunctionBar dataArray (NSArray<YBImageBrowserFunctionModel *> *) is invalid");
        return;
    }
    _dataArray = dataArray;
    [self resetUserInterfaceLayout];
    [self.tableView reloadData];
}

- (void)setMaxScaleOfOperationBar:(CGFloat)maxScaleOfOperationBar {
    if (maxScaleOfOperationBar <= 0) {
        _maxScaleOfOperationBar = 0;
    } else if (maxScaleOfOperationBar > [UIScreen mainScreen].bounds.size.height) {
        _maxScaleOfOperationBar = [UIScreen mainScreen].bounds.size.height;
    } else {
        _maxScaleOfOperationBar = maxScaleOfOperationBar;
    }
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
    UILabel *label = [cell viewWithTag:1000];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"YBImageBrowserFunctionBar"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        label = [UILabel new];
        label.textColor = [UIColor darkTextColor];
        label.font = [UIFont systemFontOfSize:15];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = 1000;
        [cell.contentView addSubview:label];
    }
    label.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, self.heightOfCell);
    
    if (indexPath.section == 0) {
        label.text = self.dataArray[indexPath.row].name;
    } else {
        label.text = @"取消";
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
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.alwaysBounceVertical = NO;
    }
    return _tableView;
}

@end
