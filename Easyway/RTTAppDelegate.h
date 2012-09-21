//
//  RTTAppDelegate.h
//  Easyway
//
//  Created by Ye Sean on 12-8-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@class RTTViewController;

@interface RTTAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>
{
    //UIWindow *window;
    //UINavigationController *navigationController;
    
    BMKMapManager* _mapManager;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) RTTViewController *viewController;

@property (strong, nonatomic) UINavigationController *navigationController;


@end
