//
//  YBIBImageCache.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/6/13.
//  Copyright © 2019 波儿菜. All rights reserved.
//

#import "YBIBImageCache.h"
#import "YBIBImageCache+Internal.h"
#import "YBIBUtilities.h"
#import <objc/runtime.h>


@implementation NSObject (YBIBImageCache)
static void *YBIBImageCacheKey = &YBIBImageCacheKey;
- (void)setYbib_imageCache:(YBIBImageCache *)ybib_imageCache {
    objc_setAssociatedObject(self, YBIBImageCacheKey, ybib_imageCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (YBIBImageCache *)ybib_imageCache {
    YBIBImageCache *cache = objc_getAssociatedObject(self, YBIBImageCacheKey);
    if (!cache) {
        cache = [YBIBImageCache new];
        self.ybib_imageCache = cache;
    }
    return cache;
}
@end


@interface YBIBImageCachePack : NSObject
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong) UIImage *compressedImage;
@end
@implementation YBIBImageCachePack
@end


@implementation YBIBImageCache {
    NSCache<NSString *, YBIBImageCachePack *> *_imageCache;
    NSMutableDictionary<NSString *, YBIBImageCachePack *> *_residentCache;
}

#pragma mark - life cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _imageCache = [NSCache new];
        _imageCache.countLimit = _imageCacheCountLimit = YBIBLowMemory() ? 6 : 12;
        _residentCache = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

#pragma mark - event

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [_imageCache removeAllObjects];
    [_residentCache removeAllObjects];
}

#pragma mark - public

- (void)setImage:(UIImage *)image type:(YBIBImageCacheType)type forKey:(NSString *)key resident:(BOOL)resident {
    YBIBImageCachePack *pack = [_imageCache objectForKey:key];
    if (!pack) {
        pack = [YBIBImageCachePack new];
        [_imageCache setObject:pack forKey:key];
    }
    switch (type) {
        case YBIBImageCacheTypeOrigin:
            pack.originImage = image;
            break;
        case YBIBImageCacheTypeCompressed:
            pack.compressedImage = image;
            break;
    }
    [_residentCache setObject:pack forKey:key];
}

- (UIImage *)imageForKey:(NSString *)key type:(YBIBImageCacheType)type {
    YBIBImageCachePack *pack = [_imageCache objectForKey:key] ?: [_residentCache objectForKey:key];
    switch (type) {
        case YBIBImageCacheTypeOrigin: return pack.originImage;
        case YBIBImageCacheTypeCompressed: return pack.compressedImage;
        default: return nil;
    }
}

- (void)removeForKey:(NSString *)key {
    [_imageCache removeObjectForKey:key];
    [_residentCache removeObjectForKey:key];
}

- (void)removeResidentForKey:(NSString *)key {
    [_residentCache removeObjectForKey:key];
}

#pragma mark - setter

- (void)setImageCacheCountLimit:(NSUInteger)imageCacheCountLimit {
    _imageCacheCountLimit = imageCacheCountLimit;
    _imageCache.countLimit = imageCacheCountLimit;
}

@end
