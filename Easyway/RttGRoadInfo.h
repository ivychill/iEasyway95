//
//  RttGRoadInfo.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"

@interface RttGRoadInfo : NSObject
{
    NSString *roadname;
    NSMutableArray *pointlist; //RttGPoint
}

@property NSString *roadname;
@property NSMutableArray *pointlist; //RttGPoint

@end


@interface RttGPoint : NSObject
//{
//    Float64 lat;
//    Float64 lon;
//}
//@property Float64 lat;
//@property Float64 lon;
@property CLLocationCoordinate2D coordinate;
@property int stepIndex; //在路径Step中的位置;（如果需要）
@property int pointIndex; //在路径点中的位置;（如果需要）

@end

@interface RttGMatchedTrafficInfo : NSObject
//{
//    NSString *roadname;
//    NSMutableArray *pointlist; //RttGMapPoint
//}

@property NSString *roadname;
@property NSString *detail;
@property int speedKMPH;
@property TimeValue64 timeStamp;
@property NSMutableArray *pointlist;    //RttGMapPoint
@property int stepIndex;                //在路径Step中的位置;
@property int nextPointIndex;           //在路径点中的位置;
//@property int BMKPolylineIndex;       //在ViewControler中，BMKPolyline队列的位置;
@property BMKPolyline *trafficPolyLine; //在地图中的PolyLine，用于绘制和删除图层

@end

@interface RttGMapPoint : NSObject

@property BMKMapPoint mappoint;

@end



@interface RTTFormatedTrafficFromTSS : NSObject
{
    
}

@property CLLocationCoordinate2D startCoord;
@property CLLocationCoordinate2D endCoord;
@property TimeValue64 timestamp;
@property int speedKMPH;
@property NSString *roadName;
@property NSString *details;
@property TimeValue64 lastTTSTimestamp;

@property RttGMatchedTrafficInfo *matchedTrafficInfo;

@end


