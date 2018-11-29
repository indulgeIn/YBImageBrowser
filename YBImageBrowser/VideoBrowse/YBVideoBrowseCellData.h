//
//  YBVideoBrowseCellData.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/28.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "YBImageBrowserCellDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBVideoBrowseCellData : NSObject <YBImageBrowserCellDataProtocol>

/** The network address of video. */
@property (nonatomic, strong, nullable) NSURL *url;

/** Video from the system album */
@property (nonatomic, strong, nullable) PHAsset *phAsset;

/** Usually, use 'AVURLAsset'. */
@property (nonatomic, strong, nullable) AVAsset *avAsset;

/** The source rendering object corresponding to the current data model, it's used for animation.
 In general, it's 'UIImageView', but it can also be 'UIView' or 'CALayer'. */
@property (nonatomic, weak, nullable) id sourceObject;

/** As a preview image. Without explicit settings, the first frame will be loaded from the video source and consume some CPU resources. */
@property (nonatomic, strong, nullable) UIImage *firstFrame;

/** The number of play video automatically. Default is 0.
 User interaction may be caton when playing automatically, so don't use automatic play unless really necessary. */
@property (nonatomic, assign) NSUInteger autoPlayCount;

/** The number of repeat play video. Default is 0. */
@property (nonatomic, assign) NSUInteger repeatPlayCount;

/** The default is YES. */
@property (nonatomic, assign) BOOL allowSaveToPhotoAlbum;

/** The default is YES. */
@property (nonatomic, assign) BOOL allowShowSheetView;

/** You can set any data. */
@property (nonatomic, strong, nullable) id extraData;

@end

NS_ASSUME_NONNULL_END
