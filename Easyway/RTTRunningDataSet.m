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
//@synthesize cityTraffic4Me;
@synthesize formatedRouteInfo;
@synthesize isPlaned;
@synthesize isPlaningFailed;
@synthesize isDriving;
@synthesize startPointInfo;
@synthesize endPointInfo;
//@synthesize historyPathInfoList;
@synthesize lastUserLocation;

//@synthesize filteredRouteTrafficList;

@synthesize homeAddrInfo;
@synthesize officeAddrInfo;
@synthesize currentlyRoute;

@synthesize formatedH2ORouteInfo;
@synthesize formatedO2HRouteInfo;
@synthesize manualRouteSettingType;

@synthesize userToken;
@synthesize deviceUuid;
@synthesize thisDev;
@synthesize deviceVersion;

@synthesize trffTTSPlayRec;

//@synthesize routeTrafficFromTSS;

- (id) init
{
    self = [super init];
    drivingRoute = nil;
    planedRoadNames = [[NSMutableArray alloc] init];
    currentRoadStep = 0;
    nextRoadPointIndex = 0;
//    cityTraffic4Me = nil;
    formatedRouteInfo = nil;
    isPlaned = NO;
    isPlaningFailed = NO;
    startPointInfo = nil;
    endPointInfo = nil;
    isDriving = NO;
    //historyPathInfoList = [[NSMutableArray alloc] init];
    
    homeAddrInfo = nil;//[[BMKPoiInfo alloc] init];
    
    //officeAddrInfo = [[BMKPoiInfo alloc] init];
    //CLLocationCoordinate2D officeLoc;

    //华为
//    officeLoc.latitude = 22.656973; 
//    officeLoc.longitude = 114.066142;
    
    #warning 办公室坐标为路云，请修改为华为
//    //路云
//    officeLoc.latitude = 22.575297;
//    officeLoc.longitude = 113.907907;
    
//    //南海北环113.943761,22.575691
//    officeLoc.latitude = 22.575691;
//    officeLoc.longitude = 113.943761;
    
    //113.890581,22.570418
//    officeLoc.latitude = 22.570418;
//    officeLoc.longitude = 113.890581;
//    
//    officeAddrInfo.pt = officeLoc;
//    officeAddrInfo.address = @"华为坂田基地 深圳市龙岗区";
    currentlyRoute = ROUTECODEUNKNOW;

    userToken = nil;
    deviceUuid = nil;
    thisDev = nil;
    deviceVersion = nil;

    
    trffTTSPlayRec = [[RTTTrafficTTSPlayRecord alloc] init];
//    routeTrafficFromTSS = [[NSMutableArray alloc] init];
//    self.hotTrafficFromTSS   = [[NSMutableArray alloc] init];
//    filteredRouteTrafficList = [[NSMutableArray alloc] init];
    self.trafficContainer = [[RTTTrafficContainer alloc] init];

    self.searchHistoryArray = [[NSMutableArray alloc] init];
    [self loadHistorySearchTxt];
    
    return self;
}

- (void) saveSearchHistory:(NSString*) searchTxt
{
    if (self.searchHistoryArray == nil)
    {
        self.searchHistoryArray = [[NSMutableArray alloc] init];
    }
    if (searchTxt==nil || [searchTxt isEqualToString:@""])
    {
        return;
    }
    else
    {
        BOOL isSaved = NO;
        for (NSString *strSaved in self.searchHistoryArray)
        {
            //NSLog(@"******Saved Search Txt=%@", strSaved);
            if([strSaved isEqualToString:searchTxt])
            {
                isSaved = YES;
            }
        }
        
        if (isSaved)
        {
            return;
        }
        else
        {
            NSInteger savedItemCnt = self.searchHistoryArray.count;
            if (savedItemCnt >= 20)
            {
                [self.searchHistoryArray removeObjectAtIndex:(savedItemCnt-1)];
            }
            else
            {
                [self.searchHistoryArray insertObject:searchTxt atIndex:0]; //最后搜索的加入到最顶
            }
            
            NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
            [saveDefaults setObject:self.searchHistoryArray forKey:@"HistorySearchSaveKey"];
            [saveDefaults synchronize];

        }
    }
}

- (void) loadHistorySearchTxt
{
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    self.searchHistoryArray = [saveDefaults objectForKey:@"HistorySearchSaveKey"];
}


@end
