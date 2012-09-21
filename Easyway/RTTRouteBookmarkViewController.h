//
//  RTTRouteBookmarkViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
@class RTTRunningDataSet;

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"


@interface RTTRouteBookmarkViewController : UITableViewController

@property RTTRunningDataSet *runtimeDataset;
@property (assign) id <RTTVCDelegate> delegate;


@end
