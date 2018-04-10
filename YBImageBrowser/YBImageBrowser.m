//
//  YBImageBrowser.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowser.h"
#import "YBImageBrowserView.h"

@interface YBImageBrowser ()

@property (nonatomic, strong) YBImageBrowserView *browserView;

@end

@implementation YBImageBrowser

#pragma mark life cycle
- (void)dealloc {
    
}
- (instancetype)init {
    return [self initWithFrame:[UIScreen mainScreen].bounds];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _browserView = [[YBImageBrowserView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    }
    return self;
}

#pragma mark public
- (void)show {
    [self showToView:[UIApplication sharedApplication].keyWindow];
}
- (void)showToView:(UIView *)view {
    if (!_dataArray || _dataArray.count <= 0) return;
    [self addSubview:self.browserView];
    [view addSubview:self];
}
- (void)hide {
    [self removeFromSuperview];
}

#pragma mark setter
- (void)setDataArray:(NSArray<YBImageBrowserModel *> *)dataArray {
    if (!_dataArray) {
        _dataArray = dataArray;
        _browserView.dataArray = dataArray;
    }
}


@end
