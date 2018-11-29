//
//  YBImageBrowserCellDataProtocol.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/25.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YBImageBrowserCellDataProtocol <NSObject>

@required

- (Class)yb_classOfBrowserCell;

@optional

- (id)yb_browserCellSourceObject;

- (BOOL)yb_browserAllowSaveToPhotoAlbum;
- (void)yb_browserSaveToPhotoAlbum;

- (BOOL)yb_browserAllowShowSheetView;

- (CGRect)yb_browserCurrentImageFrameWithImageSize:(CGSize)size;

- (void)yb_preload;

@end

NS_ASSUME_NONNULL_END
