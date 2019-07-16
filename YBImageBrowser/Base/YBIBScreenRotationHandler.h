//
//  YBIBScreenRotationHandler.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/8.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBImageBrowser.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBIBScreenRotationHandler : NSObject

- (instancetype)initWithBrowser:(YBImageBrowser *)browser;

- (void)startObserveStatusBarOrientation;

- (void)startObserveDeviceOrientation;

- (void)clear;

- (void)configContainerSize:(CGSize)size;

- (CGSize)containerSizeWithOrientation:(UIDeviceOrientation)orientation;

@property (nonatomic, assign, readonly, getter=isRotating) BOOL rotating;

@property (nonatomic, assign, readonly) UIDeviceOrientation currentOrientation;

@property (nonatomic, assign) UIInterfaceOrientationMask supportedOrientations;

@property (nonatomic, assign) NSTimeInterval rotationDuration;

@end

NS_ASSUME_NONNULL_END
