//
//  RTTToolbarView.m
//  Easyway
//
//  Created by Ye Sean on 12-8-6.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTToolbarView.h"

@implementation RTTToolbarView
@synthesize delegate;
//@synthesize routeBookmarkBTN;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//#if defined (HUAWEIVER)
//        [routeBookmarkBTN setHidden:YES];
//#endif
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

//- (IBAction)didRouteBookmarkClick:(id)sender 
//{
////    //if ([self.delegate respondsToSelector:@selector(didRTTToolbarButtonWasPressed:)]) 
////    {
////        [self.delegate didToolbarHomeSettingBTN:sender];
////    }
//    [self.delegate didToolbarBookmarkBTN:sender];
//    
//
//
//}

- (IBAction)didHomeSetting:(id)sender 
{
    [self.delegate didToolbarHomeSettingBTN:sender];
}

- (IBAction)didAccountSetting:(id)sender 
{
    [self.delegate didToolbarAccountBTN:sender];
}

- (IBAction)didGoHome:(id)sender 
{
    [self.delegate didToolbarGoHomeBTN:sender];
}

- (IBAction)didGoOffice:(id)sender 
{
    [self.delegate didToolbarGoOfficeBTN:sender];
}

@end
