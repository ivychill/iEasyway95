//
//  RTTMapPointSettingViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum RTTEN_SETMAPPOINTACTION {
    RTTSETMAPPOIN_START = 1,
    RTTSETMAPPOIN_END = 2,
    RTTSETMAPPOIN_ROUTETO = 3,
    RTTSETMAPPOIN_DELETE = 4,
    RTTSETMAPPOIN_OFFICE = 5,
    RTTSETMAPPOIN_HOME = 6,
};

@interface RttGRoutePointType : NSObject

@property enum RTTEN_SETMAPPOINTACTION pointtype;

@end


@protocol RttgRDVCdelegate <NSObject>

- (void) SetRoutePointType:(RttGRoutePointType*) pointtype;

@end


@interface RTTMapPointSettingViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *AddressInfoLAB;
@property id<RttgRDVCdelegate> delegate;
@property NSString *addrTxt;

- (IBAction)didSetRoute2Me:(id)sender;
- (IBAction)didSetStartPoint:(id)sender;
- (IBAction)didSetEndPoint:(id)sender;
- (IBAction)didSetDeleteMe:(id)sender;


@end
