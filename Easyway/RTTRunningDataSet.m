//
//  RttGRunningDataSet.m
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTRunningDataSet.h"

@interface RTTRunningDataSet ()
{
}

@end

@implementation RTTRunningDataSet

@synthesize drivingRoute;
@synthesize planedRoadNames;
@synthesize currentRoadStep;
@synthesize nextRoadPointIndex;
@synthesize cityTraffic4Me;
@synthesize formatedRouteInfo;
@synthesize isPlaned;
@synthesize isPlaningFailed;
@synthesize isDriving;
@synthesize startPointInfo;
@synthesize endPointInfo;
@synthesize historyPathInfoList;
@synthesize lastUserLocation;

@synthesize trafficInfoList;

@synthesize homeAddrInfo;
@synthesize officeAddrInfo;
@synthesize currentlyRoute;

@synthesize formatedH2ORouteInfo;
@synthesize formatedO2HRouteInfo;
@synthesize manualRouteSettingType;

- (id) init
{
    self = [super init];
    drivingRoute = nil;
    planedRoadNames = [[NSMutableArray alloc] init];
    currentRoadStep = 0;
    nextRoadPointIndex = 0;
    cityTraffic4Me = nil;
    formatedRouteInfo = nil;
    isPlaned = NO;
    isPlaningFailed = NO;
    startPointInfo = nil;
    endPointInfo = nil;
    isDriving = NO;
    trafficInfoList = [[NSMutableArray alloc] init];
    historyPathInfoList = [[NSMutableArray alloc] init];
    
    homeAddrInfo = nil;//[[BMKPoiInfo alloc] init];
    
    officeAddrInfo = [[BMKPoiInfo alloc] init];
    CLLocationCoordinate2D officeLoc;

//    //华为
//    officeLoc.latitude = 22.656973; 
//    officeLoc.longitude = 114.066142;
    
    #warning 办公室坐标为路云，请修改为华为
    //路云
    officeLoc.latitude = 22.575297; 
    officeLoc.longitude = 113.907907;
    officeAddrInfo.pt = officeLoc;
    officeAddrInfo.address = @"华为坂田基地 深圳市龙岗区";
    currentlyRoute = ROUTEUNKNOW;

    return self;
}


@end
