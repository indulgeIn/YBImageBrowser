//
//  YBIBGestureInteractionProfile.h
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/11.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YBIBGestureInteractionProfile : NSObject

/** The property indicating whether to cancel gesture interaction animation */
@property (nonatomic, assign) BOOL disable;

/** The result of this scale multiplied by the screen height, is the triggering distance to make 'image browser' disappear. */
@property (nonatomic, assign) CGFloat dismissScale;

/** The velocity to make 'image browser' disappear. */
@property (nonatomic, assign) CGFloat dismissVelocityY;

/** The duration of restore UI */
@property (nonatomic, assign) CGFloat restoreDuration;

/** The triggering distance to start gesture interaction animation. */
@property (nonatomic, assign) CGFloat triggerDistance;

@end
