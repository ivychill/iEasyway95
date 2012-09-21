//
//  RTTMapPointAnnotation.h
//  Easyway
//
//  Created by Ye Sean on 12-8-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
@class BMKAddrInfo;

#import "BMKPointAnnotation.h"




enum RTTEN_MAPPOINTTYPE {
    MAPPOINTTYPE_UNDEF = 1 << 0,
    MAPPOINTTYPE_START = 1 << 1,
    MAPPOINTTYPE_END = 1 << 2,
    MAPPOINTTYPE_HOME = 1 << 3,
    //ROUTEPOINTTYPE_ROUTETO = 3,
    //ROUTEPOINTTYPE_DELETE = 4,
    //ROUTEPOINTTYPE_GUIDPOINT = 5,
    //ROUTEPOINTTYPE_CAR = 6,
    //ROUTEPOINTTYPE_OTHER = 7
};


@interface RTTMapPointAnnotation : BMKPointAnnotation

@property BMKAddrInfo *addrInfo;
@property NSString  *addrString;
@property enum RTTEN_MAPPOINTTYPE pointType;

@end
