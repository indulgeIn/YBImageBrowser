//
//  YBIBCopywriter.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YBIBCopywriterType) {
    YBIBCopywriterTypeSimplifiedChinese,
    YBIBCopywriterTypeEnglish
};

@interface YBIBCopywriter : NSObject

/**
 The instance variable obtained by this method are effective for the framework.

 @return instance variable
 */
+ (instancetype)shareCopywriter;

/** You can set up language classes explicitly. */
@property (nonatomic, assign) YBIBCopywriterType type;


// The following propertys can be changed.

@property (nonatomic, copy) NSString *videoIsInvalid;

@property (nonatomic, copy) NSString *videoError;

@property (nonatomic, copy) NSString *unableToSave;

@property (nonatomic, copy) NSString *imageIsInvalid;

@property (nonatomic, copy) NSString *downloadImageFailed;

@property (nonatomic, copy) NSString *getPhotoAlbumAuthorizationFailed;

@property (nonatomic, copy) NSString *saveToPhotoAlbumSuccess;

@property (nonatomic, copy) NSString *saveToPhotoAlbumFailed;

@property (nonatomic, copy) NSString *saveToPhotoAlbum;

@property (nonatomic, copy) NSString *cancel;

@end

NS_ASSUME_NONNULL_END
