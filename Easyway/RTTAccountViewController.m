//
//  RTTAccountViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTAccountViewController.h"

@interface RTTAccountViewController ()

@end

@implementation RTTAccountViewController
@synthesize accountPageVIEW;
@synthesize webpageStr;
@synthesize activityIndicatorView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //webpageStr = @"https://www.roadclouding.com/users/sign_up";
    webpageStr = @"http://www.roadclouding.com/users/edit";
    NSLog(@"%@", webpageStr);
    NSURL *url =[NSURL URLWithString:webpageStr];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    [accountPageVIEW loadRequest:request];
    
    activityIndicatorView = [[UIActivityIndicatorView alloc] 
                             initWithFrame : CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)] ;
    [activityIndicatorView setCenter: self.view.center] ;
    [activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray] ; 
    [self.view addSubview : activityIndicatorView];

}

- (void)viewDidUnload
{
    [self setAccountPageVIEW:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *alterview = [[UIAlertView alloc] initWithTitle:@"" message:[error localizedDescription]  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alterview show];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [activityIndicatorView startAnimating] ;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [activityIndicatorView stopAnimating];
}

@end
