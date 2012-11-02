//
//  RTTMapView.m
//  Easyway
//
//  Created by Ye Sean on 12-8-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTMapView.h"
#import "BMapKit.h"

#import "RTTMapPointAnnotation.h"
#import "RttGRoadInfo.h"
#import "RttGRouteInfo.h"
#import "RttGMapDataset.h"
#import "Tss.pb.h"
#import "RTTRunningDataSet.h"

#import <QuartzCore/QuartzCore.h>




//@implementation CandidateSteps
//@synthesize index = _index;
//@synthesize StPoint = _StPoint;
//@synthesize EdPoint = _EdPoint;
//@end



#pragma mark -
#pragma mark Implementation Extened View for Map

#pragma mark -
#pragma mark Initional

@implementation RTTMapView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initParam];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void) initParam
{
    self.trafficPolylineList = [[NSMutableArray alloc] init];
    self.undefAnnotationArray = [[NSMutableArray alloc] init];
}


//#pragma mark -
//#pragma mark MapKit
//
////判断pnt是否在由（p1, p2）两点组成的线段范围内
////方法：计算投影点，然后判断投影点是否在线段内；如果是，则返回距离，否则返回－1.0；
////Note: 允许投影点在线段两端的误差，目前本函数还没加入这个误差；
//CLLocationDistance GetNearLineDistance(BMKMapPoint pnt,  BMKMapPoint p1, BMKMapPoint p2, BMKMapPoint *retproj)
//{
//    double a;
//    double b;
//    double c;
//    
//    if(p2.x >= p1.y)
//    {
//        a=p2.y-p1.y;
//        b=p1.x-p2.x;
//        c=p1.y*p2.x-p1.x*p2.y;
//    }
//    else
//    {
//        a=p1.y-p2.y;
//        b=p2.x-p1.x;
//        c=p2.y*p1.x-p2.x*p1.y;
//    }
//    
//    double dSPtX = (b*b*pnt.x - a*(b*pnt.y + c))/(a*a + b*b);
//    double dSPtY = (a*a*pnt.y - b*(a*pnt.x + c))/(a*a + b*b);
//    
//    if (retproj)
//    {
//        retproj->x = dSPtX;
//        retproj->y = dSPtY;
//    }
//    
//    //投影点是否在线段内；之所以这么写是为了避免复杂浮点运算；
//    if (p1.x < p2.x)//横坐标判断
//    {
//        if ((dSPtX < p1.x) || (dSPtX > p2.x)) //不在线段内，还没加入误差
//        {
//            return -1.0;
//        }
//    }
//    else
//    {
//        if ((dSPtX > p1.x) || (dSPtX < p2.x)) //不在线段内，还没加入误差
//        {
//            return -1.0;
//        }
//    }
//    
//    if (p1.y < p2.y) //纵坐标判断
//    {
//        if ((dSPtY < p1.y) || (dSPtY > p2.y)) //不在线段内，还没加入误差
//        {
//            return -1.0;
//        }
//    }
//    else
//    {
//        if ((dSPtY > p1.y) || (dSPtY < p2.y)) //不在线段内，还没加入误差
//        {
//            return -1.0;
//        }
//    }
//    
//    //double s = fabs(a*pnt.x+b*pnt.y+c)/sqrt(a*a+b*b);
//    //return s;
//    
//    BMKMapPoint projectionPoint;
//    projectionPoint.x = dSPtX;
//    projectionPoint.y = dSPtY;
//    CLLocationDistance distance = BMKMetersBetweenMapPoints(pnt, projectionPoint);
//    return distance;
//    
//};
//
//
//
//- (STPointLineDistInfo) getNearestDistanceOfRoad:(BMKMapPoint)LoctionPoint roadPoints:(BMKMapPoint *)roadPoints pointCnt:(int) pointCount
//{
//    STPointLineDistInfo retPLDInfo;
//    
//    retPLDInfo.distance = -1.0;
//    retPLDInfo.pointindex = 0;
//    retPLDInfo.projection.x = 0.0;
//    retPLDInfo.projection.y = 0.0;
//    
//    
//    if (pointCount < 2)
//    {
//        return retPLDInfo;
//    }
//    
//    CLLocationDistance nearestDistance = BMKMetersBetweenMapPoints(LoctionPoint, roadPoints[0]);
//    retPLDInfo.projection = roadPoints[0];
//    retPLDInfo.pointindex = 0;
//    
//    BMKMapPoint projPoint;
//    for (int i=0; i<(pointCount-1); i++)
//    {
//        CLLocationDistance dist = GetNearLineDistance(LoctionPoint, roadPoints[i], roadPoints[i+1], &projPoint);
//        if ((dist>=0.0) && (dist <= nearestDistance))
//        {
//            nearestDistance = dist;
//            retPLDInfo.pointindex = i;
//            retPLDInfo.projection = projPoint;
//        }
//        dist = BMKMetersBetweenMapPoints(LoctionPoint, roadPoints[i+1]); //避免落在投影外的情况，譬如凸折现连接外的点
//        if ((dist>=0.0) && (dist <= nearestDistance))
//        {
//            nearestDistance = dist;
//            retPLDInfo.pointindex = i;
//            retPLDInfo.projection = roadPoints[i+1];
//        }
//    }
//    
//    retPLDInfo.distance = nearestDistance;
//    
//    return retPLDInfo;
//};
//
//
//- (BMKMapRect) mapRectMakeFromPoint:(BMKMapPoint) point1 withPoint:(BMKMapPoint) point2
//{
//    //BMKMapPoint *pointLeftTop = [[BMKMapPoint alloc] init];
//    BMKMapPoint pointLeftTop;
//    pointLeftTop.x = (point1.x < point2.x)? point1.x:point2.x;
//    pointLeftTop.y = (point1.y < point2.y)? point1.y:point2.y;
//    double rectwidth = fabs(point1.x - point2.x);
//    double rectheight = fabs(point1.y - point2.y);
//    
//    return BMKMapRectMake(pointLeftTop.x, pointLeftTop.y, rectwidth, rectheight);
//}
//
////获取能够抽取出来的路名列表；返回路名的条数，以及在retArray中的字符串对象
//- (int) GetRoadNamesFromBMKRoute:(BMKRoute*) route withRetArray:(NSMutableArray *)retArray
//{
//    if (!retArray)
//    {
//        __autoreleasing NSMutableArray *newArray = [[NSMutableArray alloc] init];
//        retArray = newArray;
//    }
//    
//    
//    //NSString *sRepStr = @"";
//    int iStepCnt = route.steps.count;
//    
//    for (int i = 0; i < iStepCnt; i++)
//    {
//        BMKStep* step = [route.steps objectAtIndex:i];
//        
//        //抽取路名，目前是根据“进入.....——xxKM“的规则来抽取
//        NSString *cmpFirstStr = @"进入";
//        NSString *cmpEndStr = @" - ";
//        
//        NSString *pKeyPtString =  [[NSString alloc] initWithString:step.content];
//        
//        NSRange strRange = [pKeyPtString rangeOfString:cmpFirstStr];
//        int iStrLocation = strRange.location;
//        int iStrLength = strRange.length;
//        
//        if (iStrLength > 0)
//        {
//            strRange = [pKeyPtString rangeOfString:cmpEndStr];
//            
//            if (strRange.length > 0) //存在“进入.........-XXKM”的描述字符，提取路名保存
//            {
//                iStrLocation = iStrLocation + iStrLength;
//                iStrLength = strRange.location - iStrLocation;
//                
//                NSString *string2 = [pKeyPtString substringWithRange:NSMakeRange(iStrLocation, iStrLength)];
//                NSString *strObj = [[NSString alloc] initWithString:string2];
//                
//                //比较路名是否重复，还没实现路名去重的功能(是否合理待考虑）
//                BOOL isRepeated = NO;
//                for (int j=0; j < retArray.count; j++)
//                {
//                    if ( [strObj isEqualToString:((NSString *)[retArray objectAtIndex:j])] )
//                    {
//                        isRepeated = YES;
//                        break;
//                    }
//                }
//                if (!isRepeated)
//                {
//                    [retArray addObject:strObj];
//                }
//            }
//        }
//    }
//    
//    return retArray.count;
//}
//
//- (NSString *) getRoadNameFromStepContent:(NSString *)stepContent
//{
//    NSString *roadName = @"";
//    
//    NSString *cmpFirstStr = @"进入";
//    NSString *cmpEndStr = @" - ";
//    
//    NSString *pKeyPtString =  [[NSString alloc] initWithString:stepContent];
//    NSRange strRange = [pKeyPtString rangeOfString:cmpFirstStr];
//    int iStrLocation = strRange.location;
//    int iStrLength = strRange.length;
//    if (iStrLength > 0)
//    {
//        strRange = [pKeyPtString rangeOfString:cmpEndStr];
//        
//        if (strRange.length > 0) //存在“进入.........-XXKM”的描述字符，提取路名保存
//        {
//            iStrLocation = iStrLocation + iStrLength;
//            iStrLength = strRange.location - iStrLocation;
//            roadName = [pKeyPtString substringWithRange:NSMakeRange(iStrLocation, iStrLength)];
//        }
//    }
//    
//    __autoreleasing NSString *strObj = [[NSString alloc] initWithString:roadName];
//    return strObj;
//}
//
//- (RTTStepInfo *) getStepInfoFromStepContent:(NSString *)stepContent
//{
//    
//    NSString *cmpSpliteStr = @" - ";
//    //    NSString *cmpMStr = @"米";
//    //    NSString *cmpKMStr = @"公里";
//    
//    
//    __autoreleasing RTTStepInfo * stepInfo = [[RTTStepInfo alloc] init];
//    stepInfo.discriptionStr = @"";
//    stepInfo.distanceStr = @"";
//    stepInfo.distanceMeter = 0;
//    stepInfo.degree = 0;
//    
//    
//    NSArray *listItems = [stepContent componentsSeparatedByString:cmpSpliteStr];
//    
//    if (listItems.count > 1)
//    {
//        stepInfo.discriptionStr = [listItems objectAtIndex:0];
//        stepInfo.distanceStr = [listItems objectAtIndex:1];
//    }
//    
//    return stepInfo;
//}
//
//
////快速判断点是否在线段范围内；使用井形判断，在井的四个角就认为不在线段范围内了
//- (bool) isPointInLine:(CLLocationCoordinate2D)location withStepA:(BMKStep*) step_a andStepB:(BMKStep*) step_b
//{
//    bool is_inLine = false;
//    if (step_a.pt.latitude < step_b.pt.latitude)
//    {
//        if ((location.latitude >= step_a.pt.latitude)
//            && (location.latitude <= step_b.pt.latitude))
//        {
//            is_inLine = true;
//        }
//    }
//    else
//    {
//        if ((location.latitude <= step_a.pt.latitude)
//            && (location.latitude >= step_b.pt.latitude))
//        {
//            is_inLine = true;
//        }
//    }
//    
//    if (step_a.pt.longitude < step_b.pt.longitude)
//    {
//        if ((location.longitude >= step_a.pt.longitude)
//            && (location.longitude <= step_b.pt.longitude))
//        {
//            is_inLine = true;
//        }
//    }
//    else
//    {
//        if ((location.longitude <= step_a.pt.longitude)
//            && (location.longitude >= step_b.pt.longitude))
//        {
//            is_inLine = true;
//        }
//    }
//    
//    return is_inLine;
//}
//
//
//
//- (BOOL) getPositionFromRoute:(BMKRoute *)route withLocation:(CLLocationCoordinate2D) locat
//              andRetStepIndex:(int *)retStepIndex andretPointsIndex:(int*) retPointsIndex
//{
//    //关键路径点的数目
//    int iStepCnt = route.steps.count;
//    
//    //可变数组，用于保存所有关键路径点的信息
//    NSMutableArray *StepIndexs = [[NSMutableArray alloc] init];
//    
//    for (int i = 0; i < (iStepCnt-1); i++)
//    {
//        BMKStep* step_a = [route.steps objectAtIndex:i];
//        BMKStep* step_b = [route.steps objectAtIndex:(i+1)];
//        
//        //快速判断是否在大的路径上
//        bool is_inLine = [self isPointInLine:locat withStepA:step_a andStepB:step_b];
//        
//        if (is_inLine)
//        {
//            CandidateSteps *candStep = [[CandidateSteps alloc] init];
//            candStep.index = i;
//            candStep.StPoint = step_a.pt;
//            candStep.EdPoint = step_b.pt;
//            [StepIndexs addObject:candStep];
//        }
//    }
//    
//    if (0 == StepIndexs.count)
//    {
//        //NSLog(@"No Mach of Road");
//        return NO;
//    }
//    
//    BMKMapPoint locationPoint = BMKMapPointForCoordinate(locat);
//    
//    int iRetStepIndex = 0;
//    int iRetPointIndex = 0;
//    STPointLineDistInfo stPLDinfo;
//    CLLocationDistance nearestDist = 99999999999999999.0;
//    
//    for (int i=0; i<StepIndexs.count; i++)
//    {
//        CandidateSteps *candStep = [StepIndexs objectAtIndex:i];
//        int RoutePointIndex = candStep.index+1; //路径点和关键信息提示点在百度地图Routeplan中的Index不一样!
//        
//        int iPointCnt =  [route getPointsNum:RoutePointIndex];
//        if (iPointCnt < 1)
//        {
//            continue;
//        }
//        
//        BMKMapPoint *roadPoints = (BMKMapPoint*)[route getPoints:RoutePointIndex];
//        //CLLocationDistance distOfRoad =  getNearestDistanceOfRoad(locationPoint, roadPoints, iPointCnt, &stPLDinfo);
//        
//        stPLDinfo = [self getNearestDistanceOfRoad:locationPoint roadPoints:roadPoints pointCnt:iPointCnt];
//        //BMKStep *pStep = [runningDataset.drivingRoute.steps objectAtIndex:(candStep.index)];
//        //NSLog(@"Distance of Road==%@, %f", pStep.content, distOfRoad);
//        
//        if ((stPLDinfo.distance >= 0.0) && (stPLDinfo.distance < nearestDist))
//        {
//            nearestDist = stPLDinfo.distance ;
//            iRetStepIndex = candStep.index;
//            iRetPointIndex = stPLDinfo.pointindex;
//        }
//    }
//    
//    *retStepIndex = iRetStepIndex;
//    *retPointsIndex = iRetPointIndex;
//    
//    if ((nearestDist >= 0.0) && (nearestDist <= 50.0) ) //小于50M的范围，在路径上
//    {
//        return YES;
//    }
//    else
//    {
//        return NO;
//    }
//    
//}


#pragma mark -
#pragma get Map Items
//- (RTTMapPointAnnotation*) getSelectedAnnotation
//{
//    return self.pCurrentlySelectedAnnotation;
//}

- (CLLocationCoordinate2D) getCurLocation
{
    NSLog(@"UserLocation=%.6f, %.6f", self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude);
    
    if ((self.userLocation == nil) || [self checkIfLocOutofRange])
    {
        CLLocationCoordinate2D locShenzhenCenter = {22.549325, 114.0662};
        return locShenzhenCenter;
    }
    else
    {
        return self.userLocation.coordinate;
    }
}


- (BOOL) checkIfLocOutofRange
{
    if (!((self.userLocation.location.coordinate.latitude >= 18.0 && self.userLocation.location.coordinate.latitude <= 54.0)
          && (self.userLocation.location.coordinate.longitude >= 73.0 && self.userLocation.location.coordinate.longitude <= 135.0)) )
    {
        return YES;
    }
    else
    {
        return NO;
    }

}

#pragma mark -
#pragma mark Process View for Map

- (void) setCenterOfMapView:(CLLocationCoordinate2D)coordinate
{
    //Lon: 73-135, Lat:18-54
    if ((coordinate.latitude >= 18.0 && coordinate.latitude <= 54.0)
        && (coordinate.longitude >= 73.0 && coordinate.longitude <= 135.0) )
    {
        [self setCenterCoordinate:coordinate animated:0];
    }
}


- (void) removeAllUndefAnnotation
{
    int annCnt = self.undefAnnotationArray.count;
    for (int i=0; i<annCnt; i++)
    {
        [self removeAnnotation:[self.undefAnnotationArray objectAtIndex:i]];
    }
    
    [self.undefAnnotationArray removeAllObjects];
}


- (void) removeAllTrafficPolylines
{
    int polyCnt = self.trafficPolylineList.count;
    for (int i=0; i<polyCnt; i++)
    {
        [self removeOverlay:[self.trafficPolylineList objectAtIndex:i]];
    }
    
    [self.trafficPolylineList removeAllObjects];
}



- (void) DrawTrafficPolyline:(NSMutableArray*)trafficSegList
{
    [self removeAllTrafficPolylines];
    
    int trafficSegCnt = trafficSegList.count;
    
    for (int i=0; i<trafficSegCnt; i++)
    {
        
        RttGMatchedTrafficInfo *trfInfo = [trafficSegList objectAtIndex:i];
        int pointCnt = trfInfo.pointlist.count;
        
        //CLLocationCoordinate2D *pPoints = new CLLocationCoordinate2D[pointCnt];
        CLLocationCoordinate2D pPoints[pointCnt];// = new CLLocationCoordinate2D[pointCnt];

        for (int j = 0; j < pointCnt; j++)
        {
            BMKMapPoint linePoint = [[trfInfo.pointlist objectAtIndex:j] mappoint];
            pPoints[j] = BMKCoordinateForMapPoint(linePoint);
        }
        
        BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:pPoints count:pointCnt];
        polyLine.title = @"traffic";
        
        //NSLog(@"Draw Traffic polyline.........");
        [self insertOverlay:polyLine atIndex:0];//放在导航线路下面效果会更好
        [self.trafficPolylineList addObject:polyLine];
        
        //delete []pPoints;
    }
}


- (void) AddDrivingRouteOverlay:(BMKRoute*) route
{
    [self removeAllUndefAnnotation];
    
    if (self.startPointAnnotation != nil){
        [self removeAnnotation:self.startPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    if (self.endPointAnnotation != nil){
        [self removeAnnotation:self.endPointAnnotation]; //地图上只保留一个起始点或者终点
    }

    self.startPointAnnotation = [self addAnnotation2Map:route.startPt withType:MAPPOINTTYPE_START addr:nil];
    self.endPointAnnotation = [self addAnnotation2Map:route.endPt withType:MAPPOINTTYPE_END addr:nil];

    
    int iRoutePointCnt = 0; //路径上所有坐标点的个数
    for (int j = 0; j < route.pointsCount; j++)
    {
        int len = [route getPointsNum:j];
        iRoutePointCnt += len;
    }
    NSLog(@"Points Cnt in Steps: %d", iRoutePointCnt);
    
    
    //DrivingRoute = route;//[plan.routes objectAtIndex:i];
    //BMKMapPoint* points = new BMKMapPoint[iRoutePointCnt];
    BMKMapPoint points[iRoutePointCnt];// = new BMKMapPoint[iRoutePointCnt];
    
    int index = 0; //YSH_DEBUGING...............................................
    for (int j = 0; j < route.pointsCount; j++)
    {
        int len = [route getPointsNum:j];
        BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
        memcpy(points + index, pointArray, len * sizeof(BMKMapPoint));
        index += len;
    }
    
    if (self.pCurrentlyPolyLine)
    {
        [self removeOverlay:self.pCurrentlyPolyLine];
        self.pCurrentlyPolyLine = nil;
    }
    //在地图上画出规划的路线
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:iRoutePointCnt];
    polyLine.title = @"Route";
    [self addOverlay:polyLine];
    
    self.pCurrentlyPolyLine = polyLine;
    //[mMapView setCenterCoordinate:(BMKCoordinateForMapPoint(points[0]))];
    [self setCenterOfMapView:(BMKCoordinateForMapPoint(points[0]))];
    
    //delete []points;
}


- (void) DrawSpeedPolyline: (double) speed startPoint:(CLLocationCoordinate2D)startPoint endPoint:(CLLocationCoordinate2D)endPoint
{
    int pointCnt = 2;
    
    CLLocationCoordinate2D pPoints[2];// = new CLLocationCoordinate2D[pointCnt];
    
    pPoints[0] = startPoint;
    pPoints[1] = endPoint;
    
    
    BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:pPoints count:pointCnt];
    polyLine.title = [[NSString alloc] initWithFormat:@"Seg4Speed--%f", speed];
    [self addOverlay:polyLine];
    
    //        [mMapView insertOverlay:polyLine atIndex:0];//放在导航线路下面效果会更好
    //        [trafficPolylineList addObject:polyLine];
    
    //delete []pPoints;
}


//For Test
//- (void) addRouteGuidePoints
//{
//    int iStepCnt = self.runningDataset.drivingRoute.steps.count;
//    
//    for (int i = 0; i < iStepCnt; i++)
//    {
//        BMKStep* step_a = [self.runningDataset.drivingRoute.steps objectAtIndex:i];
//        RTTMapPointAnnotation *stepAnnot = [[RTTMapPointAnnotation alloc] init];
//        stepAnnot.coordinate = step_a.pt;
//        stepAnnot.title = step_a.content;
//        [self addAnnotation:stepAnnot];
//    }
//    
//}

//stepIndex 小于0 则取全路径的范围
- (void) changeMapVisibleRect:(BMKRoute*) route withIndex:(int) stepIndex
{
    int iRoutePointCnt = 0;
    if (stepIndex < 0)
    {
        //int stepCnt = route.pointsCount;
        
        for (int i = 0; i < route.pointsCount; i++)
        {
            int len = [route getPointsNum:i];
            iRoutePointCnt += len;
        }
        
        if (iRoutePointCnt > 0)
        {
            //BMKMapPoint* points = new BMKMapPoint[iRoutePointCnt];
            BMKMapPoint points[iRoutePointCnt];// = new BMKMapPoint[iRoutePointCnt];
            
            int index = 0;
            for (int j = 0; j < route.pointsCount; j++)
            {
                int len = [route getPointsNum:j];
                BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
                memcpy(points + index, pointArray, len * sizeof(BMKMapPoint));
                index += len;
            }
            
            BMKMapRect segRect = [RTTMapKit mapRectMakeFromPoint:points[0] withPoint:(points[iRoutePointCnt-1])];
            UIEdgeInsets edgeFrame={10,10,10,10};
            BMKMapRect fitRect = [self mapRectThatFits:segRect edgePadding:edgeFrame];
            [self setVisibleMapRect:fitRect animated:NO];
            
            //delete[] points;
        }
        
    }
    else
    {
        iRoutePointCnt = [route getPointsNum:stepIndex];
        if (iRoutePointCnt > 0)
        {
            
            BMKMapPoint* points = (BMKMapPoint*)[route getPoints:stepIndex];
            
            BMKMapRect segRect = [RTTMapKit mapRectMakeFromPoint:points[0] withPoint:(points[iRoutePointCnt-1])];
            UIEdgeInsets edgeFrame={10,10,10,10};
            BMKMapRect fitRect = [self mapRectThatFits:segRect edgePadding:edgeFrame];
            [self setVisibleMapRect:fitRect animated:NO];
        }
    }
    
    
}


- (RTTMapPointAnnotation*) addAnnotation2Map:(CLLocationCoordinate2D)coordinate withType:(RTTEN_MAPPOINTTYPE) type addr:(NSString*) addrTxt
{
    __autoreleasing RTTMapPointAnnotation *pointAnnotation = [[RTTMapPointAnnotation alloc] init];
    pointAnnotation.coordinate = coordinate;
    
    switch (type) {
        case MAPPOINTTYPE_START:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_START;
            pointAnnotation.title = @"起点";
        }
            break;
        case MAPPOINTTYPE_END:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_END;
            pointAnnotation.title = @"终点";
        }
            break;
        case MAPPOINTTYPE_HOME:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_HOME;
            pointAnnotation.title = @"家";
        }
            break;
        default:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_UNDEF;
            pointAnnotation.title = @"点击设置";
            
//            if(self.pUndefAnnotation)
//            {
//                [self removeAnnotation:_pUndefAnnotation];
//            }
//            self.pUndefAnnotation = pointAnnotation;
            [self.undefAnnotationArray  addObject:pointAnnotation];
        }
            break;
    }
    
    if (addrTxt != nil)
    {
        NSLog(@"AddrTxt=%@", addrTxt);
        pointAnnotation.addrString = [[NSString alloc] initWithString:addrTxt];
    }
    
    [self addAnnotation:pointAnnotation];
    
    
    //    switch (type) {
    //        case MAPPOINTTYPE_START:
    //        {
    //            pStartPointAnnotation = pointAnnotation;
    //        }
    //            break;
    //        case MAPPOINTTYPE_END:
    //        {
    //            pEndPointAnnotation = pointAnnotation;
    //        }
    //            break;
    //
    //        default:
    //            break;
    //    }
    
    
    //因为百度API是异步通过网络返回坐标POI信息，并且没有消息元素区分，所以多个点加入的时间比较短的话有可能会有错误（待处理）
    //pCurrentlyAnnotation = pointAnnotation;
    //
    //#warning "导航中路径重规划的时候应该取消查找"?
    //    [self getGeoInfofromMAPSVR:coordinate];
    //
    return pointAnnotation;
}


- (CLLocationCoordinate2D)addUndefAnnotationWithTouchPoint:(CGPoint) touchPoint
{
    [self removeAllUndefAnnotation];
    //得到经纬度，指触摸区域
    CLLocationCoordinate2D touchMapCoordinate = [self convertPoint:touchPoint toCoordinateFromView:self];
    
    self.waitingPOIResultAnnotation = [self addAnnotation2Map:touchMapCoordinate withType:MAPPOINTTYPE_UNDEF addr:nil];
//    self.pUndefAnnotation = self.waitingPOIResultAnnotation;
    [self.undefAnnotationArray addObject:self.waitingPOIResultAnnotation];
    
    return touchMapCoordinate;
}


//给返回的Annotation点设置地址信息，方便进入地图点类型选择视图的时候显示出来。
-(void) setWaitingPOIAnnotationAddress:(BMKAddrInfo*)addrinfo
{
    //if (addrinfo.addressComponent
    
    NSString *StrProv = addrinfo.addressComponent.province;
    NSString *StrCity = addrinfo.addressComponent.city;
    NSString *StrDist = addrinfo.addressComponent.district;
    NSString *StrRoad = addrinfo.addressComponent.streetName;
    if (StrRoad == nil) {
        StrRoad = @"未知道路";
    }
    //NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"省份:%@\n城市:%@\n地区:%@\n街道:%@", StrProv, StrCity,StrDist,StrRoad];
    NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"%@%@\n%@", StrCity,StrDist,StrRoad];

    
    //    注意：直接比较坐标的方式不可用，因为百度返回的坐标是存在变化的
    //    这种直接比较的方式是错误的
    //    if((pCurrentlyAnnotation.coordinate.latitude == addrinfo.geoPt.latitude)
    //        && (pCurrentlyAnnotation.coordinate.longitude == addrinfo.geoPt.longitude) )
    //    {
    //        NSLog(@"坐标匹配");
    //    }
    
    //下面代码是为了避免异步的情况下，把地址信息错误地标识到其他的点
    CLLocationDistance pointDistance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(self.waitingPOIResultAnnotation.coordinate),
                                                                 BMKMapPointForCoordinate(addrinfo.geoPt));
    if (pointDistance < 30.0)
    {
        //NSLog(@"坐标匹配");
        self.waitingPOIResultAnnotation.addrInfo = addrinfo;
        self.waitingPOIResultAnnotation.AddrString = StrFormatedInfo;
    }
    
    
}




@end
