//
//  RTTMapKit.h
//  Easyway95
//
//  Created by Sean.Yie on 12-10-31.
//
//

@class RTTStepInfo;

#import <Foundation/Foundation.h>
#import "BMapKit.h"

@interface CandidateSteps:NSObject
{
	int _index;
	CLLocationCoordinate2D _StPoint;
    CLLocationCoordinate2D _EdPoint;
}
@property (nonatomic) int index;
@property (nonatomic) CLLocationCoordinate2D StPoint;
@property (nonatomic) CLLocationCoordinate2D EdPoint;
@end

struct STPointLineDistInfo
{
    CLLocationDistance distance;
    BMKMapPoint projection;
    int pointindex;
};


@interface RTTMapKit : NSObject

+ (struct STPointLineDistInfo) getNearestDistanceOfRoad:(BMKMapPoint)LoctionPoint roadPoints:(BMKMapPoint *)roadPoints pointCnt:(int) pointCount;
+ (int) GetRoadNamesFromBMKRoute:(BMKRoute*) route withRetArray:(NSMutableArray *)retArray;
+ (NSString *) getRoadNameFromStepContent:(NSString *)stepContent;
+ (RTTStepInfo *) getStepInfoFromStepContent:(NSString *)stepContent;
+ (BMKMapRect) mapRectMakeFromPoint:(BMKMapPoint) point1 withPoint:(BMKMapPoint) point2;
+ (BOOL) getPositionFromRoute:(BMKRoute *)route withLocation:(CLLocationCoordinate2D) locat andRetStepIndex:(int *)retStepIndex andretPointsIndex:(int*) retPointsIndex;
+ (bool) isPointInLine:(CLLocationCoordinate2D)location withStepA:(BMKStep*) step_a andStepB:(BMKStep*) step_b;

+ (CLLocationDirection) cacDirectionChange:(CLLocationDirection)firstDrect secondDirection:(CLLocationDirection) secondDrect;

@end
