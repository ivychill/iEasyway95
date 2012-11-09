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
//#import "RttGHistoryPathInfo.h"
#import "Tss.pb.h"
#import "RTTTrafficTTSPlayRecord.h"
#import "RTTTrafficContainer.h"


enum RTTEN_ROUTECODE {
    ROUTECODEUNKNOW = 256,
    ROUTECODEGOTOOFFICE = 257,
    ROUTECODEGOHOME = 258,
    ROUTECODETEMPROUTE = 259,
    };

enum RTTEN_TRAFFICTYPE {
    TRAFFICTYPEHOT  = 255,
    TRAFFICTYPEUNKNOW = ROUTECODEUNKNOW,
    TRAFFICTYPEOFFICE = ROUTECODEGOTOOFFICE,
    TRAFFICTYPEHOME = ROUTECODEGOHOME,
    TRAFFICTYPETEMP = ROUTECODETEMPROUTE,
};

enum RTTEN_MANUALSETTING {
    RTTEN_MANUALSETTING_NO = ROUTECODEUNKNOW,
    RTTEN_MANUALSETTING_GOOFFICE = ROUTECODEGOTOOFFICE,
    RTTEN_MANUALSETTING_GOHOME = ROUTECODEGOHOME,
};

@interface RTTRunningDataSet : NSObject

@property NSDate *lastRoutePlanedTime;                      //最后一次获得规划路线的时间
@property BMKRoute* drivingRoute;                           //当前的驾驶路线
@property NSMutableArray *planedRoadNames;                  //所获得的驾驶路线中所有的路名列表
@property int currentRoadStep;                              //当前位置在Step中的哪一步（数组位置）
@property int nextRoadPointIndex;                           //下一个路径的Point点位置（数组位置）
//@property LYCityTraffic *cityTraffic4Me;
@property RttGRouteInfo *formatedRouteInfo;                 //格式化后的Route信息；主要用于向TSS发送订阅消息
@property BOOL isPlaned;                                    //路径是否规划
@property BOOL isPlaningFailed;                             //路径规划是否失败，用于发起重试

@property BOOL isDriving;                                   //是否正在开车；目前规划后即认为是在驾驶，后续待根据速度等优化
@property  BMKAddrInfo *startPointInfo;                     //起始点的信息，用于保持路名等，以便规避“从起点向正东方出发”丢失路名的情况
@property  BMKAddrInfo *endPointInfo;                       //结束点的信息
//@property NSMutableArray *historyPathNameList;
//@property NSMutableArray *historyPathInfoList;              //RttGHistoryPathInfo
@property CLLocation *lastUserLocation;                     //上一次获得位置的位置地址
//@property CLLocationDirection

@property BMKPoiInfo *homeAddrInfo;                         //家庭地址
@property BMKPoiInfo *officeAddrInfo;                       //办公室地址
@property enum RTTEN_ROUTECODE currentlyRoute;              //当前的路径类型，上班，下班，...
@property enum RTTEN_MANUALSETTING manualRouteSettingType;  //手工设置的类型

//@property CLLocationDistance Near 
@property RttGRouteInfo *formatedH2ORouteInfo;              //
@property RttGRouteInfo *formatedO2HRouteInfo;              //

@property NSString *userToken;                              //用于APNS的Token

@property     NSString *deviceUuid;
@property UIDevice *thisDev;                                //= [UIDevice currentDevice];
@property NSString *deviceVersion;                          //= dev.systemVersion; e.g, 5.1, 6.0, etc.


@property RTTTrafficTTSPlayRecord *trffTTSPlayRec;          //用于保存每隔500M播放一次拥堵的记录，避免重复播放


@property RTTTrafficContainer   *trafficContainer;          //路况数据都在这里统一管理

@property BOOL isRouteGuideON;
@property BOOL isReadedIntroPage;

@property NSMutableArray *searchHistoryArray;                //搜索并选择的结果，只是保存20个，通过Save方法

- (void) saveSearchHistory:(NSString*) searchTxt;

@end
