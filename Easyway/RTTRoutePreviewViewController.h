//
//  RTTRoutePreviewViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"
@class RTTRunningDataSet;
@class RTTMapView;
@class BMKPolyline;


@interface RTTRoutePreviewViewController : UIViewController <UITableViewDataSource, BMKMapViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *stepListTBL;
@property (strong, nonatomic) IBOutlet RTTMapView *pathMapView;
//@property (strong, nonatomic) IBOutlet UIView *pathMapView;


@property RTTRunningDataSet *runtimeDataset;
@property BMKPolyline *pCurrentlyPolyLine;



@end