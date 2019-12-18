//
//  TestImageBrowser.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestImageBrowser : UIViewController

@property (nonatomic, copy) NSArray<PHAsset *> *imagePHAssets;

@property (nonatomic, assign) NSInteger selectIndex;

@end

NS_ASSUME_NONNULL_END
