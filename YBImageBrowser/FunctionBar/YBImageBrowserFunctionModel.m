//
//  YBImageBrowserFunctionModel.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/14.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBImageBrowserFunctionModel.h"

NSString * const YBImageBrowserFunctionModel_ID_savePictureToAlbum = @"YBImageBrowserFunctionModel_ID_savePictureToAlbum";

@implementation YBImageBrowserFunctionModel

+ (instancetype)functionModelForSavePictureToAlbum {
    YBImageBrowserFunctionModel *model = [YBImageBrowserFunctionModel new];
    model.name = @"保存图片";
    model.ID = YBImageBrowserFunctionModel_ID_savePictureToAlbum;
    model.image = YB_READIMAGE_FROMFILE(@"ybImageBrowser_save", @"png");
    return model;
}

@end
