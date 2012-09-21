//
//  RttGRouteInfo.m
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RttGRouteInfo.h"

@implementation RttGRouteInfo
{
    
}

@synthesize roadlist;  //RttgRoadinfo

- (id) init
{
    self = [super init];
    roadlist = [[NSMutableArray alloc] init];
    return self;
}

@end



@implementation RTTStepInfo


@synthesize distanceStr;
@synthesize distanceMeter;
@synthesize discriptionStr;
@synthesize degree;

- (id) init
{
    self = [super init];

    return self;
}

@end
