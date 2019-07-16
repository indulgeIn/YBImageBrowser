//
//  YBIBImageCache.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/13.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YBIBImageCache : NSObject

/// 唯一单例
+ (instancetype)sharedCache;

/// 缓存数量限制（一个单位表示一个 YBIBImageData 产生的所有图片数据）
@property (nonatomic, assign) NSUInteger imageCacheCountLimit;

@end

NS_ASSUME_NONNULL_END
