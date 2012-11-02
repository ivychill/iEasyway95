//
//  RTTTrafficListViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RTTRunningDataSet;


@interface RoadTrafficInfo : NSObject

@property (strong, nonatomic)  NSString *roadName;
@property (strong, nonatomic) NSString *trafficDetail;
@property TimeValue64 timestamp;

@end




@interface RTTTrafficListViewController : UIViewController
{
    BOOL mIsShowAllTraffic;
    NSMutableArray *trafficArray; //Object_Type: RoadTrafficInfo 
}
@property (strong, nonatomic) IBOutlet UITableView *trafficListTBL;
@property RTTRunningDataSet *runtimeDataset;
@property BOOL isShowAllTraffic;
@property (strong, nonatomic) IBOutlet UISegmentedControl *setmentCTRL;

- (void) getDatasourceFromRunningDataSet;

- (IBAction)didSegmentChange:(id)sender;

@end
