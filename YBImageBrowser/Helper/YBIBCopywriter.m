//
//  YBIBCopywriter.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2018/9/13.
//  Copyright © 2018年 波儿菜. All rights reserved.
//

#import "YBIBCopywriter.h"

@implementation YBIBCopywriter

#pragma mark - life cycle

+ (instancetype)sharedCopywriter {
    static YBIBCopywriter *copywriter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        copywriter = [YBIBCopywriter new];
    });
    return copywriter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _type = YBIBCopywriterTypeSimplifiedChinese;
        NSArray *appleLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        if (appleLanguages && appleLanguages.count > 0) {
            NSString *languages = appleLanguages[0];
            if (![languages hasPrefix:@"zh-Hans"]) {
                _type = YBIBCopywriterTypeEnglish;
            }
        }
        
        [self initCopy];
    }
    return self;
}

#pragma mark - private

- (void)initCopy {
    BOOL en = self.type == YBIBCopywriterTypeEnglish;
    
    self.videoIsInvalid = en ? @"Video is invalid" : @"视频无效";
    self.videoError = en ? @"Video error" : @"视频错误";
    self.unableToSave = en ? @"Unable to save" : @"无法保存";
    self.imageIsInvalid = en ? @"Image is invalid" : @"图片无效";
    self.downloadFailed = en ? @"Download failed" : @"图片失败";
    self.getPhotoAlbumAuthorizationFailed = en ? @"Failed to get album authorization" : @"获取相册权限失败";
    self.saveToPhotoAlbumSuccess = en ? @"Save successful" : @"已保存到系统相册";
    self.saveToPhotoAlbumFailed = en ? @"Save failed" : @"保存失败";
    self.saveToPhotoAlbum = en ? @"Save" : @"保存到相册";
    self.cancel = en ? @"Cancel" : @"取消";
}

#pragma mark - public

- (void)setType:(YBIBCopywriterType)type {
    _type = type;
    [self initCopy];
}

@end
