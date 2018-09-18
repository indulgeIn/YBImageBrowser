//
//  YBIBFileManager.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/29.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YBIBFileManager : NSObject

/**
 Get the default bundle.
 */
+ (NSBundle *)yBImageBrowserBundle;

/**
 Get 'UIImage' from the default bundle.
 */
+ (UIImage *)getImageWithName:(NSString *)name;

@end
