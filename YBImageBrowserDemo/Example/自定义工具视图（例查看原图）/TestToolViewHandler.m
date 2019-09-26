//
//  TestToolViewHandler.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/16.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "TestToolViewHandler.h"
#import "YBIBImageData.h"
#import "YBIBToastView.h"
#import <SDWebImage/SDWebImage.h>

@interface TestToolViewHandler ()
@property (nonatomic, strong) UIButton *viewOriginButton;
@end

@implementation TestToolViewHandler

#pragma mark - <YBIBToolViewHandler>

@synthesize yb_containerView = _yb_containerView;
@synthesize yb_currentData = _yb_currentData;
@synthesize yb_containerSize = _yb_containerSize;
@synthesize yb_currentOrientation = _yb_currentOrientation;

- (void)yb_containerViewIsReadied {
    [self.yb_containerView addSubview:self.viewOriginButton];
    
    CGSize size = self.yb_containerSize(self.yb_currentOrientation());
    self.viewOriginButton.center = CGPointMake(size.width / 2.0, size.height - 80);
}

- (void)yb_hide:(BOOL)hide {
    YBIBImageData *data = self.yb_currentData();
    if (hide || !data.extraData) {
        self.viewOriginButton.hidden = YES;
    } else {
        self.viewOriginButton.hidden = NO;
    }
}

- (void)yb_pageChanged {
    // 拿到当前的数据对象（此案例都是图片）
    YBIBImageData *data = self.yb_currentData();
    // 有原图就显示按钮
    self.viewOriginButton.hidden = !data.extraData;
    [self.viewOriginButton setTitle:@"查看原图" forState:UIControlStateNormal];
    [self updateViewOriginButtonSize];
}

- (void)yb_orientationChangeAnimationWithExpectOrientation:(UIDeviceOrientation)orientation {
    // 旋转的效果自行处理了
}

#pragma mark - private

- (void)updateViewOriginButtonSize {
    CGSize size = self.viewOriginButton.intrinsicContentSize;
    self.viewOriginButton.bounds = (CGRect){CGPointZero, CGSizeMake(size.width + 15, size.height)};
}

#pragma mark - event

- (void)clickViewOriginButton:(UIButton *)button {
    
    // 拿到当前的数据对象（此案例都是图片）
    YBIBImageData *data = self.yb_currentData();
    
    // 拿到原图的地址（这里直接使用一样的地址是为了演示，业务中请关联真正的原图地址）
    NSURL *originURL = data.extraData;
    
    //下载
    SDWebImageDownloaderOptions options = SDWebImageDownloaderLowPriority | SDWebImageDownloaderAvoidDecodeImage;
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:originURL options:options context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //仅当下载的 data 是当前显示的 data 时才更新进度
            if (data == self.yb_currentData()) {
                CGFloat progress = receivedSize * 1.0 / expectedSize ?: 0;
                NSString *text = [NSString stringWithFormat:@"%.0lf%@", progress * 100, @"%"];
                [self.viewOriginButton setTitle:text forState:UIControlStateNormal];
                [self updateViewOriginButtonSize];
            }
        });
    } completed:^(UIImage * _Nullable image, NSData * _Nullable imageData, NSError * _Nullable error, BOOL finished) {
        
        //仅当下载的 data 是当前显示的 data 时处理 UI
        if (data == self.yb_currentData()) {
            if (error) {
                [self.yb_containerView ybib_showForkToast:@"下载失败"];
                return;
            }
            //隐藏按钮
            self.viewOriginButton.hidden = YES;
        }
        
        //终止处理数据
        [data stopLoading];
        //清除缓存
        [data clearCache];
        //清除原图地址
        data.extraData = nil;
        //清除之前的图片数据
        data.imageURL = nil;
        //赋值新的数据
        data.imageData = ^NSData * _Nullable{
            return imageData;
        };
        //重载
        [data loadData];
    }];
}

#pragma mark - getters

- (UIButton *)viewOriginButton {
    if (!_viewOriginButton) {
        _viewOriginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _viewOriginButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [_viewOriginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _viewOriginButton.backgroundColor = [UIColor.grayColor colorWithAlphaComponent:0.75];
        _viewOriginButton.layer.cornerRadius = 5.0;
        [_viewOriginButton addTarget:self action:@selector(clickViewOriginButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _viewOriginButton;
}

@end
