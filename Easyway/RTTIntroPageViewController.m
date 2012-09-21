//
//  RTTIntroPageViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTIntroPageViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface RTTIntroPageViewController ()

@end

@implementation RTTIntroPageViewController
@synthesize imageVIEW;
@synthesize startBTN;
@synthesize delegate;
@synthesize page;
@synthesize pageImageVW;

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
    page = 0;
    
    //设置阴影
    startBTN.layer.shadowColor = [[UIColor blackColor] CGColor];
    startBTN.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    startBTN.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    startBTN.layer.shadowRadius = 10.0f; // 阴影发散的程度

    //[startBTN setBackgroundColor:[UIColor blueColor]];
    [startBTN setHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:NO];  

    UIImage *initImage = [UIImage imageNamed:@"Instro-1.png"];
    [pageImageVW setImage:initImage];  
    
}

- (void)viewDidUnload
{
    [self setImageVIEW:nil];
    [self setStartBTN:nil];
    [self setPageImageVW:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [self.navigationController setNavigationBarHidden:YES animated:(NO)];
//    
//}

- (void)viewDidAppear:(BOOL)animated
{
    //NSLog(@"VVVVVV");
    //[self.navigationController setHidesBottomBarWhenPushed:YES];
    [self.navigationController setNavigationBarHidden:YES animated:(NO)];
}

- (IBAction)didStart2Use:(id)sender 
{
    [self.navigationController popViewControllerAnimated:YES];
    
    [delegate didHomeAddrReset:sender];
}

- (IBAction)didSwipeLeft:(id)sender 
{
    if (page >= 3)
    {
        return;
    }
    else 
    {
        page++;
        NSString *imageName = [[NSString alloc] initWithFormat:@"Instro-%d.png", (page+1)];
        UIImage *pageImage = [UIImage imageNamed:imageName];
        [pageImageVW setImage:pageImage];  
        
        if (page == 3)
        {
            [startBTN setHidden:NO];
        }
    }
}

- (IBAction)didSwipeRight:(id)sender 
{
    if (page <= 0)
    {
        return;
    }
    else 
    {
        page--;
        NSString *imageName = [[NSString alloc] initWithFormat:@"Instro-%d.png", (page+1)];
        UIImage *pageImage = [UIImage imageNamed:imageName];
        [pageImageVW setImage:pageImage];
        [startBTN setHidden:YES];
    }

}
@end
