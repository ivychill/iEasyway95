//
//  RTTBMKSvrOperation.m
//  Easyway95
//
//  Created by Sean.Yie on 12-11-7.
//
//

#import "RTTBMKSvrOperation.h"

@implementation RTTBMKSvrOperation



- (void) main
{



}



#pragma mark -
#pragma mark Baidu Delegate Event Process


//得到Poi的地理位置坐标信息
- (void)onGetPoiResult:(NSArray*)poiResultList searchType:(int)type errorCode:(int)error
{
    
	if (error == BMKErrorOk)
    {
		BMKPoiResult* result = (BMKPoiResult*) [poiResultList objectAtIndex:0];
        
        if (result.poiInfoList.count > 0)
        {            
            BMKPoiInfo *firstPoi = [result.poiInfoList objectAtIndex:0];
            NSString *pointAddr = firstPoi.address;
            NSString *pointName = firstPoi.name;
            NSString *addrTxt = [[NSString alloc] initWithFormat:@"%@\r\n%@", pointAddr, pointName ];
            
            NSLog(@"%@", addrTxt);
            
        }
	}
    else
    {
        //NSLog(@"POI Search Fail, Error Code=%d", error);
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"无法获取检索结果"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
    }
}


//获取地理位置的路名地址等POI信息
- (void)onGetAddrResult:(BMKAddrInfo*)result errorCode:(int)error
{
    
	if (error != BMKErrorOk)
    {
    	NSLog(@"onGetAddrResult:error:%d", error);
        return;
    }
    else
    {
        NSLog(@"Get onGetAddrResult Success");

    }
    
    
}

- (void)onGetDrivingRouteResult:(BMKPlanResult*)result errorCode:(int)error
{
	//NSLog(@"onGetDrivingRouteResult, activity=%d", mRunningActivity);
    
    if (error != BMKErrorOk)
    {
    	NSLog(@"onGetDrivingRouteResult:error:%d", error);
        return;
    }
    else
    {
        NSLog(@"Get GetDrivingRoute Success");
        
    }

}




@end
