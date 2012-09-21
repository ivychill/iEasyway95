//
//  RttGRouteInfo.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RttGRouteInfo : NSObject
{
    NSMutableArray *roadlist;  //队列Item类型为RttgRoadInfo
}

@property NSMutableArray *roadlist;

@end


@interface RTTStepInfo : NSObject
@property NSString *distanceStr;
@property int distanceMeter;
@property NSString *discriptionStr;
@property int degree; //相对正北的角度

@end