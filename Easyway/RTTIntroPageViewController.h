//
//  RTTIntroPageViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"

@interface RTTIntroPageViewController : UIViewController
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *imageVIEW;
@property (strong, nonatomic) IBOutlet UIButton *startBTN;
@property id <RTTVCDelegate> delegate;
@property NSInteger page;
@property (strong, nonatomic) IBOutlet UIImageView *pageImageVW;

- (IBAction)didStart2Use:(id)sender;

- (IBAction)didSwipeLeft:(id)sender;
- (IBAction)didSwipeRight:(id)sender;

@end
