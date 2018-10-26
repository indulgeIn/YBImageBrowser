//
//  YBImageBrowserSheetView.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/12.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserSheetView.h"
#import "YBIBCopywriter.h"
#import "YBIBUtilities.h"
#import "YBImageBrowserTipView.h"

NSString * const kYBImageBrowserSheetActionIdentitySaveToPhotoAlbum = @"kYBImageBrowserSheetActionIdentitySaveToPhotoAlbum";

@implementation YBImageBrowserSheetAction
+ (instancetype)actionWithName:(NSString *)name identity:(NSString *)identity action:(YBImageBrowserSheetActionBlock)action {
    YBImageBrowserSheetAction *sheetAction = [YBImageBrowserSheetAction new];
    sheetAction.name = name;
    sheetAction.identity = identity;
    sheetAction.action = action;
    return sheetAction;
}
@end


@interface YBImageBrowserSheetCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *line;
@end
@implementation YBImageBrowserSheetCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _titleLabel = [UILabel new];
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor darkTextColor];
        _titleLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _line = [UIView new];
        _line.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_line];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *labelC0 = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:40];
        NSLayoutConstraint *labelC1 = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-40];
        NSLayoutConstraint *labelC2 = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        _line.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *lineC0 = [NSLayoutConstraint constraintWithItem:_line attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0.5];
        NSLayoutConstraint *lineC1 = [NSLayoutConstraint constraintWithItem:_line attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
        NSLayoutConstraint *lineC2 = [NSLayoutConstraint constraintWithItem:_line attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        NSLayoutConstraint *lineC3 = [NSLayoutConstraint constraintWithItem:_line attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.contentView addConstraints:@[labelC0, labelC1, labelC2, lineC0, lineC1, lineC2, lineC3]];
    }
    return self;
}
@end


static NSString * const kIdentityOfYBImageBrowserSheetCell = @"kIdentityOfYBImageBrowserSheetCell";

@interface YBImageBrowserSheetView () <UITableViewDelegate, UITableViewDataSource> {
    CGRect _showFrame;
    CGRect _hideFrame;
    id<YBImageBrowserCellDataProtocol> _data;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *footer;
@end

@implementation YBImageBrowserSheetView

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_heightOfCell = 50;
        self->_cancelText = [YBIBCopywriter shareCopywriter].cancel;
        self->_maxHeightScale = 0.7;
        self->_animateDuration = 0.2;
        
        [self addSubview:self.tableView];
    }
    return self;
}

#pragma mark - <YBImageBrowserSheetViewProtocol>

- (void)yb_browserShowSheetViewWithData:(id<YBImageBrowserCellDataProtocol>)data layoutDirection:(YBImageBrowserLayoutDirection)layoutDirection containerSize:(CGSize)containerSize {
    if (self.actions.count <= 0) return;
    
    self->_data = data;
    
    CGFloat width = containerSize.width, height = containerSize.height;
    
    CGFloat tableViewHeight = MIN(self.heightOfCell * self.actions.count + self.heightOfCell + 5 + YBIB_HEIGHT_EXTRABOTTOM, height * self.maxHeightScale);
    self->_hideFrame = CGRectMake(0, height, width, tableViewHeight);
    self->_showFrame = CGRectMake(0, height - tableViewHeight, width, tableViewHeight);
    
    self.frame = CGRectMake(0, 0, width, height);
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.tableView.frame = self->_hideFrame;
    [self.tableView reloadData];
    self.footer.frame = CGRectMake(0, 0, width, YBIB_HEIGHT_EXTRABOTTOM);
    [UIView animateWithDuration:self->_animateDuration animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
        self.tableView.frame = self->_showFrame;
    }];
}

- (void)yb_browserHideSheetViewWithAnimation:(BOOL)animation {
    if (!self.superview) return;
    
    void(^animationsBlock)(void) = ^{
        self.tableView.frame = self->_hideFrame;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    };
    void(^completionBlock)(BOOL n) = ^(BOOL n){
        [self removeFromSuperview];
    };
    if (animation) {
        [UIView animateWithDuration:self->_animateDuration animations:animationsBlock completion:completionBlock];
    } else {
        animationsBlock();
        completionBlock(NO);
    }
}

- (NSInteger)yb_browserActionsCount {
    return self.actions.count;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return self.actions.count;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.heightOfCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return 0.001;
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YBImageBrowserSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentityOfYBImageBrowserSheetCell];
    if (indexPath.section == 0) {
        cell.line.hidden = NO;
        YBImageBrowserSheetAction *action = self.actions[indexPath.row];
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
        if ([self.actions[indexPath.row].identity isEqualToString:kYBImageBrowserSheetActionIdentitySaveToPhotoAlbum]) {
            if ([self->_data respondsToSelector:@selector(yb_browserSaveToPhotoAlbum)] && [self->_data respondsToSelector:@selector(yb_browserAllowSaveToPhotoAlbum)] && [self->_data yb_browserAllowSaveToPhotoAlbum]) {
                [self->_data yb_browserSaveToPhotoAlbum];
            } else {
                [YBIBGetNormalWindow() yb_showForkTipView:[YBIBCopywriter shareCopywriter].unableToSave];
            }
        } else {
            self.actions[indexPath.row].action(self->_data);
        }
    }
    [self yb_browserHideSheetViewWithAnimation:YES];
}

#pragma mark - touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.tableView.frame, point)) {
        [self yb_browserHideSheetViewWithAnimation:YES];
    }
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 44;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.backgroundColor = [UIColor clearColor];
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.alwaysBounceVertical = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        _tableView.tableFooterView = self.footer;
        [_tableView registerClass:YBImageBrowserSheetCell.class forCellReuseIdentifier:kIdentityOfYBImageBrowserSheetCell];
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
