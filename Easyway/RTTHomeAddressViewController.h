//
//  RTTHomeAddressViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@interface RTTHomeAddressViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *AddressLAB;
@property (strong, nonatomic) IBOutlet BMKMapView *addrMapVIEW;

@end
