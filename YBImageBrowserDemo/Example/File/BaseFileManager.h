//
//  BaseFileManager.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/15.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseFileManager : NSObject

+ (NSArray *)imageURLs;

+ (NSArray *)imageNames;

+ (NSArray *)videos;

+ (NSArray<PHAsset *> *)imagePHAssets;

@end

NS_ASSUME_NONNULL_END
