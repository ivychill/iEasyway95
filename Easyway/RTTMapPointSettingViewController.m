//
//  RTTMapPointSettingViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTMapPointSettingViewController.h"

@interface RttGRoutePointType()
@end

@implementation RttGRoutePointType

@synthesize pointtype;

@end


@interface RTTMapPointSettingViewController ()

@end

@implementation RTTMapPointSettingViewController
@synthesize AddressInfoLAB;
@synthesize delegate;
@synthesize addrTxt;

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
    //[self.navigationController setNavigationBarHidden:NO];
    AddressInfoLAB.text = addrTxt;
    
}

- (void)viewDidUnload
{
    [self setDelegate:nil];
    [self setAddressInfoLAB:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)viewDidDisappear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES animated:(NO)];
}

- (void)viewDidAppear:(BOOL)animated
{
    //[self.navigationController setHidesBottomBarWhenPushed:YES];
    //[self.navigationController setNavigationBarHidden:YES animated:(NO)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES animated:(NO)];
}

- (IBAction)didSetRoute2Me:(id)sender {
   [self SendBackPointTypeToDelegate:RTTSETMAPPOIN_ROUTETO];
}

- (IBAction)didSetStartPoint:(id)sender {
    [self SendBackPointTypeToDelegate:RTTSETMAPPOIN_START];
}
- (IBAction)didSetEndPoint:(id)sender {
    [self SendBackPointTypeToDelegate:RTTSETMAPPOIN_END];
}

- (IBAction)didSetDeleteMe:(id)sender {
    [self SendBackPointTypeToDelegate:RTTSETMAPPOIN_DELETE];
}

- (void) SendBackPointTypeToDelegate:(enum RTTEN_SETMAPPOINTACTION) type
{
    RttGRoutePointType *pPointType = [[RttGRoutePointType alloc] init];
    [pPointType setPointtype:type];
    if (self.delegate != nil)
    {
        [self.delegate performSelector:@selector(SetRoutePointType:) withObject:pPointType];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
