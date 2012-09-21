//
//  RTTTopBarView.m
//  Easyway
//
//  Created by Ye Sean on 12-8-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTTopBarView.h"

@implementation RTTTopBarView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
//    //if ([self.delegate respondsToSelector:@selector(didRTTToolbarButtonWasPressed:)]) 
//    {
//        [self.delegate didRTTToolbarButtonWasPressed:@"RouteBookmarkBTN"];
//    }
//    
//}

@end
