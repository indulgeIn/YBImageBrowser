//
//  YBIBImageCache+Internal.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/13.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBImageCache.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBIBImageCacheType) {
    YBIBImageCacheTypeOrigin,
    YBIBImageCacheTypeCompressed
};

/**
 Not thread safe.
 */
@interface YBIBImageCache ()

- (void)setImage:(UIImage *)image type:(YBIBImageCacheType)type forKey:(NSString *)key resident:(BOOL)resident;

- (nullable UIImage *)imageForKey:(NSString *)key type:(YBIBImageCacheType)type;

- (void)removeForKey:(NSString *)key;

- (void)removeResidentForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
