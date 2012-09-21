//
//  RTTHomeAddrViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTHomeAddrViewController.h"

@interface RTTHomeAddrViewController ()

@end

@implementation RTTHomeAddrViewController
@synthesize mHomeAddrLBL;
@synthesize mHomeImage;
@synthesize addrInfoMAP;
@synthesize delegate;
@synthesize addrTxt;
@synthesize addrLocation;

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
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]initWithTitle:@"重设地址" 
                                                                      style:UIBarButtonItemStylePlain target:self action:@selector(didResetAddr:)];
        
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    mHomeAddrLBL.text = addrTxt;
    [self addAnnotation2Map:addrLocation];
}

- (void)viewDidUnload
{
    [self setMHomeAddrLBL:nil];
    [self setMHomeImage:nil];
    [self setAddrInfoMAP:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [addrInfoMAP removeFromSuperview];
    addrInfoMAP = nil;
}

- (void) didResetAddr:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];

    [delegate didHomeAddrReset:sender];
}



#pragma mark -
#pragma mark Baidu Map Process

- (void) addAnnotation2Map:(CLLocationCoordinate2D)coordinate
{
    BMKPointAnnotation *pointAnnotation = [[BMKPointAnnotation alloc] init];
    pointAnnotation.coordinate = coordinate;
    

            pointAnnotation.title = @"家";
     
    [addrInfoMAP addAnnotation:pointAnnotation];
    [addrInfoMAP setCenterCoordinate:coordinate];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)bmkmapview viewForAnnotation:(id <BMKAnnotation>)annotation
{    
    if ([annotation isKindOfClass:[BMKUserLocation class]])
    {
        return nil;  
    }
    

        static NSString* RoutePlanAnnotationIdentifier = @"RoutePlanAnnotationIdentifier";  
        __autoreleasing BMKPinAnnotationView* pinView = (BMKPinAnnotationView *) [addrInfoMAP dequeueReusableAnnotationViewWithIdentifier:RoutePlanAnnotationIdentifier];  
        if (!pinView)  
        {
            // if an existing pin view was not available, create one  
            BMKPinAnnotationView* customPinView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:RoutePlanAnnotationIdentifier];
            
            customPinView.opaque = YES;
            
            pinView = customPinView;
        }  
        else  
        {  
            pinView.annotation = annotation;  
        }  
        
        return pinView;  
}


@end
