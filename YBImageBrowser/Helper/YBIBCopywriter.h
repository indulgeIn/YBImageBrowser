//
//  YBIBCopywriter.h
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/9/13.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBIBCopywriterType) {
    /// 简体中文
    YBIBCopywriterTypeSimplifiedChinese,
    /// 英文
    YBIBCopywriterTypeEnglish
};

/**
 文案管理类
 */
@interface YBIBCopywriter : NSObject

/**
 唯一有效单例
 */
+ (instancetype)sharedCopywriter;

/// 语言类型
@property (nonatomic, assign) YBIBCopywriterType type;

#pragma - 以下文案可更改

@property (nonatomic, copy) NSString *videoIsInvalid;

@property (nonatomic, copy) NSString *videoError;

@property (nonatomic, copy) NSString *unableToSave;

@property (nonatomic, copy) NSString *imageIsInvalid;

@property (nonatomic, copy) NSString *downloadFailed;

@property (nonatomic, copy) NSString *getPhotoAlbumAuthorizationFailed;

@property (nonatomic, copy) NSString *saveToPhotoAlbumSuccess;

@property (nonatomic, copy) NSString *saveToPhotoAlbumFailed;

@property (nonatomic, copy) NSString *saveToPhotoAlbum;

@property (nonatomic, copy) NSString *cancel;

@end

NS_ASSUME_NONNULL_END
