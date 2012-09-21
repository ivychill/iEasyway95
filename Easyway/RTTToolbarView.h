//
//  RTTToolbarView.h
//  Easyway
//
//  Created by Ye Sean on 12-8-6.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"

//@protocol RTTToolbarDelegate
//
//@required
//
//- (void)didRTTToolbarButtonWasPressed:(NSString*)buttonName;
//
//@end


@interface RTTToolbarView : UIView

@property id <RTTVCDelegate> delegate;
//@property (strong, nonatomic) IBOutlet UIButton *routeBookmarkBTN;

//- (IBAction)didRouteBookmarkClick:(id)sender;
- (IBAction)didHomeSetting:(id)sender;
- (IBAction)didAccountSetting:(id)sender;
- (IBAction)didGoHome:(id)sender;
- (IBAction)didGoOffice:(id)sender;

@end
