//
//  RTTHomeAddrViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"
#import "BMapKit.h"

@interface RTTHomeAddrViewController : UIViewController <BMKMapViewDelegate>
@property (strong, nonatomic) IBOutlet UILabel *mHomeAddrLBL;
@property (strong, nonatomic) IBOutlet UIImageView *mHomeImage;
@property (strong, nonatomic) IBOutlet BMKMapView *addrInfoMAP;
@property NSString *addrTxt;
@property CLLocationCoordinate2D addrLocation;


@property id <RTTVCDelegate> delegate;

@end
