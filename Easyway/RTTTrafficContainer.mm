//
//  RTTTrafficContainer.m
//  Easyway95
//
//  Created by Sean.Yie on 12-10-31.
//
//

#import "RTTTrafficContainer.h"

@implementation RTTTrafficContainer

- (id) init
{
    self = [super init];
    
    self.filteredRouteTrafficList = [[NSMutableArray alloc] init];
    self.routeTrafficFromTSS = [[NSMutableArray alloc] init];
    self.hotTrafficFromTSS   = [[NSMutableArray alloc] init];
    
    return self;
}




- (void) removeAllFilteredTraffic
{
    [self.filteredRouteTrafficList removeAllObjects];
}
- (void) removeAllRouteTraffic
{
    [self.routeTrafficFromTSS removeAllObjects];
}
- (void) removeAllHotTraffic
{
    [self.hotTrafficFromTSS removeAllObjects];
}

//过滤路径，//--进行拟合判断后写入runningDataset.filteredRouteTrafficList
//成功拟合后返回RttGMatchedTrafficInfo对象，否则返回NULL
- (RttGMatchedTrafficInfo *) createTrafficInfo2Dataset:(RTTFormatedTrafficFromTSS*) segTraffic withRttgRoadInfo:(RttGRoadInfo*) roadInfo
{
    int roadPoincnt = [roadInfo.pointlist count];
    
    CLLocationCoordinate2D minRectPoint;
    CLLocationCoordinate2D maxRectPoint;
    
    minRectPoint.longitude = 5000.0;
    minRectPoint.latitude = 50000.0;
    maxRectPoint.longitude = 0.0;
    maxRectPoint.latitude = 0.0;
    
    for (int i=0; i < roadInfo.pointlist.count; i++)
    {
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].latitude < minRectPoint.latitude)
        {
            minRectPoint.latitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].latitude;
        }
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].longitude < minRectPoint.longitude)
        {
            minRectPoint.longitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].longitude;
        }
        
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].latitude > maxRectPoint.latitude)
        {
            maxRectPoint.latitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].latitude;
        }
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].longitude > maxRectPoint.longitude)
        {
            maxRectPoint.longitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].longitude;
        }
    }
    
    BMKMapPoint roadPoint1 = BMKMapPointForCoordinate(minRectPoint);
    BMKMapPoint roadPoint2 = BMKMapPointForCoordinate(maxRectPoint);
    
    
    BMKMapRect roadRect = [RTTMapKit mapRectMakeFromPoint:roadPoint1 withPoint:roadPoint2];
    
    CLLocationCoordinate2D pPoints[2];// = new CLLocationCoordinate2D[2];
    pPoints[0] = segTraffic.startCoord;
    pPoints[1] = segTraffic.endCoord;
    
    //YSH_MODIFIED 2012-10-09 11:00
    //为了避免路径和拥堵线段都是地图上的平行或者垂直的时候，微小的偏差都会带来不能正确拟合的情况，这里人为增加拥堵路段的微小偏差
    if ( fabs(pPoints[1].latitude - pPoints[0].latitude) <= 0.000200)
    {
        if (pPoints[1].latitude < pPoints[0].latitude)
        {
            pPoints[1].latitude -= 0.000100;
            pPoints[0].latitude += 0.000100;
        }
        else
        {
            pPoints[1].latitude += 0.000100;
            pPoints[0].latitude -= 0.000100;
        }
    }
    
    if ( fabs(pPoints[1].longitude - pPoints[0].longitude) <= 0.000200)
    {
        if (pPoints[1].longitude < pPoints[0].longitude)
        {
            pPoints[1].longitude -= 0.000100;
            pPoints[0].longitude += 0.000100;
        }
        else
        {
            pPoints[1].longitude += 0.000100;
            pPoints[0].longitude -= 0.000100;
        }
    }
    //End Modify
    
    BMKMapPoint SegPoint1 = BMKMapPointForCoordinate(pPoints[0]);
    BMKMapPoint SegPoint2 = BMKMapPointForCoordinate(pPoints[1]);
    BMKMapRect segRect = [RTTMapKit mapRectMakeFromPoint:SegPoint1 withPoint:SegPoint2];
    
    BMKMapRect comRect = BMKMapRectIntersection(roadRect, segRect);
    if (BMKMapRectIsNull(comRect) || BMKMapRectIsEmpty(comRect)) //没有交集
    {
        //NSLog(@"没有拟合的矩形");
        return nil;
    }
    else
    {
        //NSLog(@"拟合矩形");
        BMKMapPoint comPoint1;
        BMKMapPoint comPoint2;
        
        double slope = (pPoints[1].latitude - pPoints[0].latitude)/(pPoints[1].longitude - pPoints[0].longitude);
        
        if (slope < 0.0) //正的斜率，取交集矩形最靠近坐标(0,0)的点和对角点; 地图坐标轴是以左上角为原点; 注意经纬度和直角坐标的区别;
        {
            if (pPoints[1].latitude < pPoints[0].latitude)
            {
                comPoint1 = comRect.origin;
                comPoint2.x = comRect.origin.x + comRect.size.width;
                comPoint2.y = comRect.origin.y + comRect.size.height;
            }
            else
            {
                comPoint2 = comRect.origin;
                comPoint1.x = comRect.origin.x + comRect.size.width;
                comPoint1.y = comRect.origin.y + comRect.size.height;
            }
            
        }
        else
        {
            if (pPoints[1].latitude > pPoints[0].latitude)
            {
                comPoint1.x = comRect.origin.x;
                comPoint1.y = comRect.origin.y+comRect.size.height;
                comPoint2.x = comRect.origin.x + comRect.size.width;
                comPoint2.y = comRect.origin.y;
            }
            else
            {
                comPoint2.x = comRect.origin.x;
                comPoint2.y = comRect.origin.y+comRect.size.height;
                comPoint1.x = comRect.origin.x + comRect.size.width;
                comPoint1.y = comRect.origin.y;
            }
        }
        
        CLLocationDistance cmbRange = BMKMetersBetweenMapPoints(comPoint1, comPoint2);
        if (cmbRange < 50.0) //避免转弯时路口坐标偏差导致的小段拥堵误报
        {
            return nil;
        }
        
        
        
        //逐段判断路径拟合点并保存
        __autoreleasing RttGMatchedTrafficInfo *pTrafficPath = [[RttGMatchedTrafficInfo alloc] init];
        pTrafficPath.roadname = roadInfo.roadname;
        pTrafficPath.detail = segTraffic.details;
        pTrafficPath.timeStamp = segTraffic.timestamp;
        
        
        BMKMapPoint roadPointList[roadPoincnt];// = new BMKMapPoint[roadPoincnt];
        for (int icp = 0; icp < roadPoincnt; icp++)
        {
            roadPointList[icp] = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:icp] coordinate]);
        }
        //        STPointLineDistInfo stPLDinfoC1;
        //        CLLocationDistance distCP1 = mMapView.getNearestDistanceOfRoad(comPoint1, roadPointList, roadPoincnt, &stPLDinfoC1);
        
        STPointLineDistInfo stPLDinfoC1 = [RTTMapKit getNearestDistanceOfRoad:comPoint1 roadPoints:roadPointList pointCnt:roadPoincnt];
        
        //        STPointLineDistInfo stPLDinfoC2;
        //        CLLocationDistance distCP2 = mMapView.getNearestDistanceOfRoad(comPoint2, roadPointList, roadPoincnt, &stPLDinfoC2);
        
        STPointLineDistInfo stPLDinfoC2 = [RTTMapKit getNearestDistanceOfRoad:comPoint2 roadPoints:roadPointList pointCnt:roadPoincnt];
        
        //NSLog(@"CP1, IDX=%d, Dist=%f; CP2, IDX=%d, Dist=%f", stPLDinfoC1.pointindex, distCP1, stPLDinfoC2.pointindex, distCP2);
        
        if ((stPLDinfoC1.distance >= 0.0 && stPLDinfoC1.distance <= 100.0) && (stPLDinfoC2.distance >= 0.0 && stPLDinfoC2.distance <= 100.0))
        {
            if (stPLDinfoC1.pointindex <= stPLDinfoC2.pointindex)
            {
                //如果拥堵路段比较短，在两个直线的端点之间；则需要判断两个投影点和起始端点的距离，通过这个距离来判断先后顺序（方向）
                if (stPLDinfoC1.pointindex == stPLDinfoC2.pointindex)
                {
                    BMKMapPoint rdPoint = roadPointList[stPLDinfoC1.pointindex];
                    CLLocationDistance distancM1 = BMKMetersBetweenMapPoints(stPLDinfoC1.projection, rdPoint);
                    CLLocationDistance distancM2 = BMKMetersBetweenMapPoints(stPLDinfoC2.projection, rdPoint);
                    if (distancM1 >= distancM2)
                    {
                        return nil;
                    }
                    
                }
                
                RttGMapPoint *mapPoint = [[RttGMapPoint alloc]init];
                mapPoint.mappoint = stPLDinfoC1.projection;
                [pTrafficPath.pointlist addObject:mapPoint];
                //保存拥堵路段起始点在规划路径中的位置，后续用于提示
                pTrafficPath.stepIndex = [[roadInfo.pointlist objectAtIndex:(stPLDinfoC1.pointindex)] stepIndex];
                pTrafficPath.nextPointIndex = [[roadInfo.pointlist objectAtIndex:(stPLDinfoC1.pointindex)] pointIndex];
                
                
                //中间路径
                int iRdPointCnt = (stPLDinfoC2.pointindex - stPLDinfoC1.pointindex);
                for (int iSPI = 0; iSPI < iRdPointCnt; iSPI++)
                {
                    RttGMapPoint *mapPointRd = [[RttGMapPoint alloc]init];
                    int pointIndexOfRoad = stPLDinfoC1.pointindex + iSPI + 1;
                    mapPointRd.mappoint = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:(pointIndexOfRoad)] coordinate]);
                    [pTrafficPath.pointlist addObject:mapPointRd];
                }
                
                //终点
                RttGMapPoint *mapPointE = [[RttGMapPoint alloc]init];
                mapPointE.mappoint = stPLDinfoC2.projection;
                [pTrafficPath.pointlist addObject:mapPointE];
            }
        }
        //        if (pTrafficPath.pointlist.count > 0)
        //        {
        //            [runningDataset.filteredRouteTrafficList addObject: pTrafficPath];//增加到数据集中
        //            //6.0对讯飞支持不好
        //            float verValue = runningDataset.deviceVersion.floatValue;
        //            if (verValue < 6.0)
        //            {
        //                NSString *strInfo = [[NSString alloc] initWithFormat:@"最新路况:%@ %@", pTrafficPath.roadname, pTrafficPath.detail];
        //                [mSynTTS addTrafficStr:strInfo];
        //            }
        //        }
        if (pTrafficPath.pointlist.count > 0)
        {
            return pTrafficPath;
        }
        else
        {
            return nil;
        }
    }
    
}

//路径规划后，重新匹配拥堵路径
//之所以这么做，是因为TSS是逐条下发，并且客户端判断重复没有超时后就不处理了；所以重新规划后批量刷新
- (void) reFilteTrafficWithRoadList:(NSMutableArray*)roadList
{
    [self.filteredRouteTrafficList removeAllObjects];
    
    
    for (RTTFormatedTrafficFromTSS *tssTrf in self.routeTrafficFromTSS)
    {
        for (RttGRoadInfo *road in roadList)
        {
            if ([road.roadname isEqualToString:tssTrf.roadName])
            {
                //LYSegmentTraffic *pSegTrf = [pRdTrc.segmentTrafficsList objectAtIndex:k];
                RttGMatchedTrafficInfo *retMatchedTrf = [self createTrafficInfo2Dataset:tssTrf withRttgRoadInfo:road];
                if (retMatchedTrf)
                {
                    //[self DrawTrafficPolyline:NO];
                    tssTrf.matchedTrafficInfo = retMatchedTrf;//
                    [self.filteredRouteTrafficList addObject:retMatchedTrf];// lastObject;
                }
            }
            
        }
    }
    
}


//增加拥堵路径到runningDataset.routeTrafficFromTSS，不做过滤，只做覆盖
//返回RttGMatchedTrafficInfo 的NSMutableArray
- (NSMutableArray *) addTSSTraffic2RunningDataset4Route:(NSString *)roadName segment:(LYSegmentTraffic*) trfSegment roadList:(NSMutableArray*)roadList
{
    
    __autoreleasing NSMutableArray *retMatchedTrfList = [[NSMutableArray alloc] init];
    
    //先检查重复的
    BOOL hasExistRecord = NO;
    for (RTTFormatedTrafficFromTSS *trfSegInfo in self.routeTrafficFromTSS)
    {
#warning 判断Detail不准确（譬如，速度不一样），要修改为判断坐标(or+ 速度)
        if ([trfSegInfo.details isEqualToString:trfSegment.details]) //判断Detail不准确，
        {
            trfSegInfo.timestamp = trfSegment.timestamp; //更新时间戳即可
            hasExistRecord = YES;
            
#warning matchedTrafficInfo需要清理（路径规划后）
            if (trfSegInfo.matchedTrafficInfo != nil)
            {
                trfSegInfo.matchedTrafficInfo.timeStamp = trfSegment.timestamp; //强类型引用，关联修改
                trfSegInfo.matchedTrafficInfo.speedKMPH = trfSegment.speed; //强类型引用，关联修改
                [retMatchedTrfList addObject:trfSegInfo.matchedTrafficInfo];
            }
            
            break;
        }
    }
    
    if (!hasExistRecord)
    {
        
        RTTFormatedTrafficFromTSS *trfSegInfo = [[RTTFormatedTrafficFromTSS alloc] init];
        trfSegInfo.roadName = roadName;
        trfSegInfo.details = trfSegment.details;
        trfSegInfo.speedKMPH = trfSegment.speed;
        trfSegInfo.timestamp = trfSegment.timestamp;
        
        CLLocationCoordinate2D tmpStCoord;
        tmpStCoord.latitude = trfSegment.segment.start.lat;
        tmpStCoord.longitude = trfSegment.segment.start.lng;
        [trfSegInfo setStartCoord:tmpStCoord];
        
        CLLocationCoordinate2D tmpEdCoord;
        tmpEdCoord.latitude = trfSegment.segment.end.lat;
        tmpEdCoord.longitude = trfSegment.segment.end.lng;
        [trfSegInfo setEndCoord:tmpEdCoord];
        
        [self.routeTrafficFromTSS addObject:trfSegInfo];
        
        for (RttGRoadInfo *road in roadList)
        {
            if ([road.roadname isEqualToString:trfSegInfo.roadName])
            {
                RttGMatchedTrafficInfo *retMatchedTrf = [self createTrafficInfo2Dataset:trfSegInfo withRttgRoadInfo:road];
                if (retMatchedTrf != nil)
                {
                    retMatchedTrf.speedKMPH = trfSegInfo.speedKMPH;
                    trfSegInfo.matchedTrafficInfo = retMatchedTrf;//
                    [self.filteredRouteTrafficList addObject:retMatchedTrf];// lastObject;
                    
                    [retMatchedTrfList addObject:retMatchedTrf];
                    
                }
            }
        }
        
    }
    
    return retMatchedTrfList;
}

- (void) clearOutofDateTrafficData4Route
{
    int segCnt = self.routeTrafficFromTSS.count;
    for (int i=(segCnt-1); i >= 0; i--)
    {
        RTTFormatedTrafficFromTSS *trfseg = [self.routeTrafficFromTSS objectAtIndex:i];
        
        NSDate *segDate = [NSDate dateWithTimeIntervalSince1970:trfseg.timestamp];
        NSTimeInterval secondsBetweenNow =  [segDate timeIntervalSinceNow];
        if (secondsBetweenNow <= -360.0) //间隔超过6分钟就丢弃
        {
#warning WORKING.......
            //先删除地图上的图层，以及队列信息
            RttGMatchedTrafficInfo* matchedTrf =
            ((RTTFormatedTrafficFromTSS*)(self.routeTrafficFromTSS[i])).matchedTrafficInfo;
#warning 处理地图上的拥堵痕迹
//            if (matchedTrf && matchedTrf.trafficPolyLine)
//            {
//                [mMapView removeOverlay:matchedTrf.trafficPolyLine];
//            }
            
            for (RttGMatchedTrafficInfo *trfElement in self.filteredRouteTrafficList)
            {
                if (trfElement == matchedTrf)
                {
                    [self.filteredRouteTrafficList removeObject:trfElement];
                    break;
                }
            }
            //if (runningDataset.filteredRouteTrafficList[i]
            
            [self.routeTrafficFromTSS removeObjectAtIndex:i];
        }
    }
}


//增加拥堵路径到runningDataset.hotTrafficFromTSS，不做过滤，只做覆盖
- (void) addTSSTraffic2RunningDataset4Hot:(NSString *)roadName segment:(LYSegmentTraffic*) trfSegment
{
    
    //先检查重复的
    BOOL hasExistRecord = NO;
    for (RTTFormatedTrafficFromTSS *trfSegInfo in self.hotTrafficFromTSS)
    {
#warning 判断Detail不准确（譬如，速度不一样），要修改为判断坐标(or+ 速度)
        if ([trfSegInfo.details isEqualToString:trfSegment.details]) //判断Detail不准确，
        {
            trfSegInfo.timestamp = trfSegment.timestamp; //更新时间戳即可
            hasExistRecord = YES;
            break;
        }
    }
    
    if (!hasExistRecord)
    {
        
        RTTFormatedTrafficFromTSS *trfSegInfo = [[RTTFormatedTrafficFromTSS alloc] init];
        trfSegInfo.roadName = roadName;
        trfSegInfo.details = trfSegment.details;
        trfSegInfo.speedKMPH = trfSegment.speed;
        trfSegInfo.timestamp = trfSegment.timestamp;
        
        CLLocationCoordinate2D tmpStCoord;
        tmpStCoord.latitude = trfSegment.segment.start.lat;
        tmpStCoord.longitude = trfSegment.segment.start.lng;
        [trfSegInfo setStartCoord:tmpStCoord];
        
        CLLocationCoordinate2D tmpEdCoord;
        tmpEdCoord.latitude = trfSegment.segment.end.lat;
        tmpEdCoord.longitude = trfSegment.segment.end.lng;
        [trfSegInfo setEndCoord:tmpEdCoord];
        
        [self.hotTrafficFromTSS addObject:trfSegInfo];
        
    }
}

- (void) clearOutofDateTrafficData4Hot
{
    int segCnt = self.hotTrafficFromTSS.count;
    for (int i=(segCnt-1); i >= 0; i--)
    {
        RTTFormatedTrafficFromTSS *trfseg = [self.hotTrafficFromTSS objectAtIndex:i];
        
        NSDate *segDate = [NSDate dateWithTimeIntervalSince1970:trfseg.timestamp];
        NSTimeInterval secondsBetweenNow =  [segDate timeIntervalSinceNow];
        if (secondsBetweenNow <= -360.0) //间隔超过6分钟就丢弃
        {
            [self.hotTrafficFromTSS removeObjectAtIndex:i];
        }
    }
}


- (RttGMatchedTrafficInfo*) getNearestTrafficSeg:(int) stepIndex pointIndex:(int)pointIndex
{
    //判断拥堵提示
    int trafficSegCnt = self.filteredRouteTrafficList.count;
    
    RttGMatchedTrafficInfo *retTrafficSeg = nil;
    
    for (int trfindex = 0; trfindex < trafficSegCnt; trfindex++)
    {
        RttGMatchedTrafficInfo *trfinfo = [self.filteredRouteTrafficList objectAtIndex:trfindex];
        
        //如果当前点的Step位置和拥堵点相同，并且路径点中下一点小于拥堵点在路径点中相关位置（意味着还没到）
        //或者当前点的Step位置比拥堵点小
        if ((stepIndex == trfinfo.stepIndex && pointIndex<= trfinfo.nextPointIndex)
            || (stepIndex < trfinfo.stepIndex))
        {
            
            if (retTrafficSeg == nil)
            {
                retTrafficSeg = trfinfo;
            }
            else
            {
                if ((retTrafficSeg.stepIndex > trfinfo.stepIndex)
                    || ((retTrafficSeg.stepIndex == trfinfo.stepIndex) && (retTrafficSeg.nextPointIndex > trfinfo.nextPointIndex)) )
                {
                    retTrafficSeg = trfinfo;
                }
            }
            
        }
    }
    
    return retTrafficSeg;
}

- (BOOL) checkIfTrafficOnAhead:(RttGMatchedTrafficInfo*) trfInfo steIndex:(int) stepIndex pointIndex:(int)pointIndex
{
    if ((stepIndex == trfInfo.stepIndex && pointIndex<= trfInfo.nextPointIndex)
        || (stepIndex < trfInfo.stepIndex))
    {
        return YES;
    }
    else
    {
        return NO;
    }

}


@end
