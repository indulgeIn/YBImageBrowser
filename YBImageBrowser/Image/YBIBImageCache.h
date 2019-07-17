//
//  YBIBImageCache.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/13.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YBIBImageCache;

@interface NSObject (YBIBImageCache)

/// 图片浏览器持有的图片缓存管理类
@property (nonatomic, strong, readonly) YBIBImageCache *ybib_imageCache;

@end


@interface YBIBImageCache : NSObject

/// 缓存数量限制（一个单位表示一个 YBIBImageData 产生的所有图片数据）
@property (nonatomic, assign) NSUInteger imageCacheCountLimit;

@end

NS_ASSUME_NONNULL_END
