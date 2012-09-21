//
//  RTTAccountViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTTAccountViewController : UIViewController <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *accountPageVIEW;
@property NSString *webpageStr;
@property UIActivityIndicatorView *activityIndicatorView;

@end
