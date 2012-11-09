//
//  RTTMapKit.m
//  Easyway95
//
//  Created by Sean.Yie on 12-10-31.
//
//

#import "RTTMapKit.h"
#import "RTTMapPointAnnotation.h"
#import "RttGRoadInfo.h"
#import "RttGRouteInfo.h"
#import "RttGMapDataset.h"
#import "Tss.pb.h"
#import "RTTRunningDataSet.h"

#import <QuartzCore/QuartzCore.h>

@implementation CandidateSteps
@synthesize index = _index;
@synthesize StPoint = _StPoint;
@synthesize EdPoint = _EdPoint;
@end

@implementation RTTMapKit

#pragma mark -
#pragma mark MapKit

//判断pnt是否在由（p1, p2）两点组成的线段范围内
//方法：计算投影点，然后判断投影点是否在线段内；如果是，则返回距离，否则返回－1.0；
//Note: 允许投影点在线段两端的误差，目前本函数还没加入这个误差；
CLLocationDistance GetNearLineDistance(BMKMapPoint pnt,  BMKMapPoint p1, BMKMapPoint p2, BMKMapPoint *retproj)
{
    double a;
    double b;
    double c;
    
    if(p2.x >= p1.y)
    {
        a=p2.y-p1.y;
        b=p1.x-p2.x;
        c=p1.y*p2.x-p1.x*p2.y;
    }
    else
    {
        a=p1.y-p2.y;
        b=p2.x-p1.x;
        c=p2.y*p1.x-p2.x*p1.y;
    }
    
    double dSPtX = (b*b*pnt.x - a*(b*pnt.y + c))/(a*a + b*b);
    double dSPtY = (a*a*pnt.y - b*(a*pnt.x + c))/(a*a + b*b);
    
    if (retproj)
    {
        retproj->x = dSPtX;
        retproj->y = dSPtY;
    }
    
    //投影点是否在线段内；之所以这么写是为了避免复杂浮点运算；
    if (p1.x < p2.x)//横坐标判断
    {
        if ((dSPtX < p1.x) || (dSPtX > p2.x)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    else
    {
        if ((dSPtX > p1.x) || (dSPtX < p2.x)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    
    if (p1.y < p2.y) //纵坐标判断
    {
        if ((dSPtY < p1.y) || (dSPtY > p2.y)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    else
    {
        if ((dSPtY > p1.y) || (dSPtY < p2.y)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    
    //double s = fabs(a*pnt.x+b*pnt.y+c)/sqrt(a*a+b*b);
    //return s;
    
    BMKMapPoint projectionPoint;
    projectionPoint.x = dSPtX;
    projectionPoint.y = dSPtY;
    CLLocationDistance distance = BMKMetersBetweenMapPoints(pnt, projectionPoint);
    return distance;
    
};



+ (STPointLineDistInfo) getNearestDistanceOfRoad:(BMKMapPoint)LoctionPoint roadPoints:(BMKMapPoint *)roadPoints pointCnt:(int) pointCount
{
    STPointLineDistInfo retPLDInfo;
    
    retPLDInfo.distance = -1.0;
    retPLDInfo.pointindex = 0;
    retPLDInfo.projection.x = 0.0;
    retPLDInfo.projection.y = 0.0;
    
    
    if (pointCount < 2)
    {
        return retPLDInfo;
    }
    
    CLLocationDistance nearestDistance = BMKMetersBetweenMapPoints(LoctionPoint, roadPoints[0]);
    retPLDInfo.projection = roadPoints[0];
    retPLDInfo.pointindex = 0;
    
    BMKMapPoint projPoint;
    for (int i=0; i<(pointCount-1); i++)
    {
        CLLocationDistance dist = GetNearLineDistance(LoctionPoint, roadPoints[i], roadPoints[i+1], &projPoint);
        if ((dist>=0.0) && (dist <= nearestDistance))
        {
            nearestDistance = dist;
            retPLDInfo.pointindex = i;
            retPLDInfo.projection = projPoint;
        }
        dist = BMKMetersBetweenMapPoints(LoctionPoint, roadPoints[i+1]); //避免落在投影外的情况，譬如凸折现连接外的点
        if ((dist>=0.0) && (dist <= nearestDistance))
        {
            nearestDistance = dist;
            retPLDInfo.pointindex = i;
            retPLDInfo.projection = roadPoints[i+1];
        }
    }
    
    retPLDInfo.distance = nearestDistance;
    
    return retPLDInfo;
};


+ (BMKMapRect) mapRectMakeFromPoint:(BMKMapPoint) point1 withPoint:(BMKMapPoint) point2
{
    //BMKMapPoint *pointLeftTop = [[BMKMapPoint alloc] init];
    BMKMapPoint pointLeftTop;
    pointLeftTop.x = (point1.x < point2.x)? point1.x:point2.x;
    pointLeftTop.y = (point1.y < point2.y)? point1.y:point2.y;
    double rectwidth = fabs(point1.x - point2.x);
    double rectheight = fabs(point1.y - point2.y);
    
    return BMKMapRectMake(pointLeftTop.x, pointLeftTop.y, rectwidth, rectheight);
}

//获取能够抽取出来的路名列表；返回路名的条数，以及在retArray中的字符串对象
+ (int) GetRoadNamesFromBMKRoute:(BMKRoute*) route withRetArray:(NSMutableArray *)retArray
{
    if (!retArray)
    {
        __autoreleasing NSMutableArray *newArray = [[NSMutableArray alloc] init];
        retArray = newArray;
    }
    
    
    //NSString *sRepStr = @"";
    int iStepCnt = route.steps.count;
    
    for (int i = 0; i < iStepCnt; i++)
    {
        BMKStep* step = [route.steps objectAtIndex:i];
        
        //抽取路名，目前是根据“进入.....——xxKM“的规则来抽取
        NSString *cmpFirstStr = @"进入";
        NSString *cmpEndStr = @" - ";
        
        NSString *pKeyPtString =  [[NSString alloc] initWithString:step.content];
        
        NSRange strRange = [pKeyPtString rangeOfString:cmpFirstStr];
        int iStrLocation = strRange.location;
        int iStrLength = strRange.length;
        
        if (iStrLength > 0)
        {
            strRange = [pKeyPtString rangeOfString:cmpEndStr];
            
            if (strRange.length > 0) //存在“进入.........-XXKM”的描述字符，提取路名保存
            {
                iStrLocation = iStrLocation + iStrLength;
                iStrLength = strRange.location - iStrLocation;
                
                NSString *string2 = [pKeyPtString substringWithRange:NSMakeRange(iStrLocation, iStrLength)];
                NSString *strObj = [[NSString alloc] initWithString:string2];
                
                //比较路名是否重复，还没实现路名去重的功能(是否合理待考虑）
                BOOL isRepeated = NO;
                for (int j=0; j < retArray.count; j++)
                {
                    if ( [strObj isEqualToString:((NSString *)[retArray objectAtIndex:j])] )
                    {
                        isRepeated = YES;
                        break;
                    }
                }
                if (!isRepeated)
                {
                    [retArray addObject:strObj];
                }
            }
        }
    }
    
    return retArray.count;
}

+ (NSString *) getRoadNameFromStepContent:(NSString *)stepContent
{
    NSString *roadName = @"";
    
    NSString *cmpFirstStr = @"进入";
    NSString *cmpEndStr = @" - ";
    
    NSString *pKeyPtString =  [[NSString alloc] initWithString:stepContent];
    NSRange strRange = [pKeyPtString rangeOfString:cmpFirstStr];
    int iStrLocation = strRange.location;
    int iStrLength = strRange.length;
    if (iStrLength > 0)
    {
        strRange = [pKeyPtString rangeOfString:cmpEndStr];
        
        if (strRange.length > 0) //存在“进入.........-XXKM”的描述字符，提取路名保存
        {
            iStrLocation = iStrLocation + iStrLength;
            iStrLength = strRange.location - iStrLocation;
            roadName = [pKeyPtString substringWithRange:NSMakeRange(iStrLocation, iStrLength)];
        }
    }
    
    __autoreleasing NSString *strObj = [[NSString alloc] initWithString:roadName];
    return strObj;
}

+ (RTTStepInfo *) getStepInfoFromStepContent:(NSString *)stepContent
{
    
    NSString *cmpSpliteStr = @" - ";
    //    NSString *cmpMStr = @"米";
    //    NSString *cmpKMStr = @"公里";
    
    
    __autoreleasing RTTStepInfo * stepInfo = [[RTTStepInfo alloc] init];
    stepInfo.discriptionStr = @"";
    stepInfo.distanceStr = @"";
    stepInfo.distanceMeter = 0;
    stepInfo.degree = 0;
    
    
    NSArray *listItems = [stepContent componentsSeparatedByString:cmpSpliteStr];
    
    if (listItems.count > 1)
    {
        stepInfo.discriptionStr = [listItems objectAtIndex:0];
        stepInfo.distanceStr = [listItems objectAtIndex:1];
    }
    
    return stepInfo;
}


//快速判断点是否在线段范围内；使用井形判断，在井的四个角就认为不在线段范围内了
+ (bool) isPointInLine:(CLLocationCoordinate2D)location withStepA:(BMKStep*) step_a andStepB:(BMKStep*) step_b
{
    bool is_inLine = false;
    if (step_a.pt.latitude < step_b.pt.latitude)
    {
        if ((location.latitude >= step_a.pt.latitude)
            && (location.latitude <= step_b.pt.latitude))
        {
            is_inLine = true;
        }
    }
    else
    {
        if ((location.latitude <= step_a.pt.latitude)
            && (location.latitude >= step_b.pt.latitude))
        {
            is_inLine = true;
        }
    }
    
    if (step_a.pt.longitude < step_b.pt.longitude)
    {
        if ((location.longitude >= step_a.pt.longitude)
            && (location.longitude <= step_b.pt.longitude))
        {
            is_inLine = true;
        }
    }
    else
    {
        if ((location.longitude <= step_a.pt.longitude)
            && (location.longitude >= step_b.pt.longitude))
        {
            is_inLine = true;
        }
    }
    
    return is_inLine;
}



+ (BOOL) getPositionFromRoute:(BMKRoute *)route withLocation:(CLLocationCoordinate2D) locat
              andRetStepIndex:(int *)retStepIndex andretPointsIndex:(int*) retPointsIndex
{
    //关键路径点的数目
    int iStepCnt = route.steps.count;
    
    //可变数组，用于保存所有关键路径点的信息
    NSMutableArray *StepIndexs = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < (iStepCnt-1); i++)
    {
        BMKStep* step_a = [route.steps objectAtIndex:i];
        BMKStep* step_b = [route.steps objectAtIndex:(i+1)];
        
        //快速判断是否在大的路径上
        bool is_inLine = [self isPointInLine:locat withStepA:step_a andStepB:step_b];
        
        if (is_inLine)
        {
            CandidateSteps *candStep = [[CandidateSteps alloc] init];
            candStep.index = i;
            candStep.StPoint = step_a.pt;
            candStep.EdPoint = step_b.pt;
            [StepIndexs addObject:candStep];
        }
    }
    
    if (0 == StepIndexs.count)
    {
        //NSLog(@"No Mach of Road");
        return NO;
    }
    
    BMKMapPoint locationPoint = BMKMapPointForCoordinate(locat);
    
    int iRetStepIndex = 0;
    int iRetPointIndex = 0;
    STPointLineDistInfo stPLDinfo;
    CLLocationDistance nearestDist = 99999999999999999.0;
    
    for (int i=0; i<StepIndexs.count; i++)
    {
        CandidateSteps *candStep = [StepIndexs objectAtIndex:i];
        int RoutePointIndex = candStep.index+1; //路径点和关键信息提示点在百度地图Routeplan中的Index不一样!
        
        int iPointCnt =  [route getPointsNum:RoutePointIndex];
        if (iPointCnt < 1)
        {
            continue;
        }
        
        BMKMapPoint *roadPoints = (BMKMapPoint*)[route getPoints:RoutePointIndex];
        //CLLocationDistance distOfRoad =  getNearestDistanceOfRoad(locationPoint, roadPoints, iPointCnt, &stPLDinfo);
        
        stPLDinfo = [self getNearestDistanceOfRoad:locationPoint roadPoints:roadPoints pointCnt:iPointCnt];
        //BMKStep *pStep = [runningDataset.drivingRoute.steps objectAtIndex:(candStep.index)];
        //NSLog(@"Distance of Road==%@, %f", pStep.content, distOfRoad);
        
        if ((stPLDinfo.distance >= 0.0) && (stPLDinfo.distance < nearestDist))
        {
            nearestDist = stPLDinfo.distance ;
            iRetStepIndex = candStep.index;
            iRetPointIndex = stPLDinfo.pointindex;
        }
    }
    
    *retStepIndex = iRetStepIndex;
    *retPointsIndex = iRetPointIndex;
    
    if ((nearestDist >= 0.0) && (nearestDist <= 50.0) ) //小于50M的范围，在路径上
    {
        return YES;
    }
    else
    {
        return NO;
    }
    
}


+ (CLLocationDirection) cacDirectionChange:(CLLocationDirection)firstDrect secondDirection:(CLLocationDirection) secondDrect
{
    CLLocationDirection retValue = fabs(firstDrect - secondDrect);
    if (retValue > 180.0)
    {
        retValue = 360.0 - retValue;
    }
    
    return retValue;
}

@end
