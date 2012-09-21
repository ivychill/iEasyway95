//
//  RttGHistoryPathInfo.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"

@interface RttGHistoryPathInfo : NSObject

@property  BMKAddrInfo *startPointInfo;
@property  BMKAddrInfo *endPointInfo;
@property  NSString    *pathName;


@end
