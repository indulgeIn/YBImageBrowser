//
//  YBIBScreenOrientationManager.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/8/27.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "YBIBLayoutDirectionManager.h"
#import "YBIBUtilities.h"

@implementation YBIBLayoutDirectionManager

#pragma mark - life cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public

- (void)startObserve {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

+ (YBImageBrowserLayoutDirection)getLayoutDirectionByStatusBar {
    UIInterfaceOrientation obr = [UIApplication sharedApplication].statusBarOrientation;
    if ((obr == UIInterfaceOrientationPortrait) || (obr == UIInterfaceOrientationPortraitUpsideDown)) {
        return YBImageBrowserLayoutDirectionVertical;
    } else if ((obr == UIInterfaceOrientationLandscapeLeft) || (obr == UIInterfaceOrientationLandscapeRight)) {
        return YBImageBrowserLayoutDirectionHorizontal;
    } else {
        return YBImageBrowserLayoutDirectionUnknown;
    }
}

#pragma mark - notification

- (void)applicationDidChangeStatusBarOrientationNotification:(NSNotification *)note {
    if (self.layoutDirectionChangedBlock) {
        self.layoutDirectionChangedBlock([self.class getLayoutDirectionByStatusBar]);
    }
}

@end
