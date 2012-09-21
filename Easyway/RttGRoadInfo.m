//
//  RttGRoadInfo.m
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RttGRoadInfo.h"

@implementation RttGRoadInfo

@synthesize roadname;
@synthesize pointlist;

- (id) init
{
    self = [super init];
    roadname = [[NSString alloc] init];
    pointlist = [[NSMutableArray alloc] init];
    return self;
}

@end


@implementation  RttGPoint
//@synthesize lat;
//@synthesize lon;
@synthesize coordinate;
@synthesize stepIndex;
@synthesize pointIndex;

@end


@implementation RttGTrafficInfo

@synthesize roadname;
@synthesize pointlist;
@synthesize stepIndex;
@synthesize nextPointIndex;
@synthesize detail;

- (id) init
{
    self = [super init];
    roadname = [[NSString alloc] init];
    detail = [[NSString alloc] init];
    pointlist = [[NSMutableArray alloc] init];
    stepIndex = 0;
    nextPointIndex = 0;
    return self;
}

@end


@implementation  RttGMapPoint

@synthesize mappoint;

@end

