//
//  RttGRunningDataSet.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"
#import "RttGRoadInfo.h"
#import "RttGRouteInfo.h"
#import "RttGMapDataset.h"
#import "Tss.pb.h"
#import "RttGHistoryPathInfo.h"
#import "Tss.pb.h"

enum RTTEN_ROUTECODE {
    ROUTEUNKNOW = 0,
    GOTOOFFICE = 1,
    GOHOME = 2,
    };

enum RTTEN_MANUALSETTING {
    RTTEN_MANUALSETTING_NO = 0,
    RTTEN_MANUALSETTING_GOOFFICE = 1,
    RTTEN_MANUALSETTING_GOHOME = 2,
};

@interface RTTRunningDataSet : NSObject
{
//    BMKRoute* DrivingRoute;     //规划出来的路线信息，直接按照百度数据结构保存
//    NSMutableArray *RoutNames;  //规划路径中的所有路名列表
//    int iRdStep;                //目前位置在规划路径中的关键信息第几段(百度数据结构BMKRoute中的steps）
//    
//    TSS_CityTraffic *citytraffic4me;    //TSS下发的交通路况信息
//    RttGRouteInfo *formatedrouteinfo;   //按照结构化的 路名+路径点列表 保存的数据
}

@property BMKRoute* drivingRoute;
@property NSMutableArray *planedRoadNames;
@property int currentRoadStep;    //当前在Step中的哪一步（数组位置）
@property int nextRoadPointIndex; //下一个路径的Point点位置
@property TSSCityTraffic *cityTraffic4Me;
@property RttGRouteInfo *formatedRouteInfo;
@property BOOL isPlaned;
@property BOOL isPlaningFailed;

@property BOOL isDriving;
@property  BMKAddrInfo *startPointInfo;
@property  BMKAddrInfo *endPointInfo;
//@property NSMutableArray *historyPathNameList;
@property NSMutableArray *historyPathInfoList; //RttGHistoryPathInfo
@property CLLocation *lastUserLocation;

@property BMKPoiInfo *homeAddrInfo;
@property BMKPoiInfo *officeAddrInfo;
@property enum RTTEN_ROUTECODE currentlyRoute;
@property enum RTTEN_MANUALSETTING manualRouteSettingType;


//@property CLLocationDistance Near 
@property RttGRouteInfo *formatedH2ORouteInfo;
@property RttGRouteInfo *formatedO2HRouteInfo;



@property NSMutableArray *trafficInfoList; //RttGTrafficInfo


@end
