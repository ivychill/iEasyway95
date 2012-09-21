//
//  RTTModeActivityIndicatorView.m
//  Easyway
//
//  Created by Ye Sean on 12-8-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTModeActivityIndicatorView.h"
#import <QuartzCore/QuartzCore.h>

@implementation RTTModeActivityIndicatorView
@synthesize activityDescLBL;
@synthesize backgroundBoardVW;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [backgroundBoardVW setCenter:CGPointMake(160.0, 80.0)];
        //[[self view] addSubview:mModeIndicatorView];
        
        //设置圆角
        [backgroundBoardVW.layer setCornerRadius:12.0f];
        
        //设置阴影
        backgroundBoardVW.layer.shadowColor = [[UIColor blackColor] CGColor];
        backgroundBoardVW.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
        backgroundBoardVW.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
        backgroundBoardVW.layer.shadowRadius = 10.0f; // 阴影发散的程度

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

@end
