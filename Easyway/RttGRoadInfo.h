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
@property NSMutableArray *pointlist;

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

@interface RttGTrafficInfo : NSObject
//{
//    NSString *roadname;
//    NSMutableArray *pointlist; //RttGMapPoint
//}

@property NSString *roadname;
@property NSString *detail;
@property NSMutableArray *pointlist; //RttGMapPoint
@property int stepIndex;             //在路径Step中的位置;
@property int nextPointIndex;        //在路径点中的位置;

@end

@interface RttGMapPoint : NSObject

@property BMKMapPoint mappoint;

@end

