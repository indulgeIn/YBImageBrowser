//
//  YBImageBrowserDownloader.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YBImageBrowserDownloader : NSObject

+ (void)downloadImageWithURL:(NSURL *)url progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progress success:(void(^)(UIImage *image))success failed:(void(^)(void))failed;

@end
