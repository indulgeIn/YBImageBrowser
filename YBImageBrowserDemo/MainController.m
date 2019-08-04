//
//  MainController.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "MainController.h"
#import "TestAController.h"
#import "TestBController.h"
#import "TestCController.h"
#import "TestDController.h"
#import "TestEController.h"
#import "TestFController.h"

@interface MainController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation MainController {
    NSArray<Class> *_controllers;
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"YBImageBrowser";
    _controllers = @[TestAController.self, TestBController.self, TestCController.self, TestDController.self, TestFController.self, TestEController.self];
    [self.view addSubview:self.tableView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _controllers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const kCellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    cell.textLabel.text = [_controllers[indexPath.row] yb_title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BaseListController *vc = [_controllers[indexPath.row] new];
    vc.title = [vc.class yb_title];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

@end
