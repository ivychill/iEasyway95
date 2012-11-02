//
//  RTTMapView.h
//  Easyway
//
//  Created by Ye Sean on 12-8-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


@class RTTMapPointAnnotation;
//@class RTTRunningDataSet;
@class RTTStepInfo;

#import "BMKMapView.h"
#import "BMapKit.h"
#import "RTTMapPointAnnotation.h"
#import "RTTMapKit.h"


//@interface CandidateSteps:NSObject
//{
//	int _index;
//	CLLocationCoordinate2D _StPoint;
//    CLLocationCoordinate2D _EdPoint;
//}
//@property (nonatomic) int index;
//@property (nonatomic) CLLocationCoordinate2D StPoint;
//@property (nonatomic) CLLocationCoordinate2D EdPoint;
//@end
//
//
//struct STPointLineDistInfo
//{
//    CLLocationDistance distance;
//    BMKMapPoint projection;
//    int pointindex;
//};


//目前只是为了保证扩展性，继承了百度的MAPView类
@interface RTTMapView : BMKMapView


@property BMKPolyline     *pCurrentlyPolyLine;
@property NSMutableArray *trafficPolylineList;

@property RTTMapPointAnnotation *startPointAnnotation;
@property RTTMapPointAnnotation *endPointAnnotation;
//@property RTTMapPointAnnotation *undefAnnotation;
@property NSMutableArray *undefAnnotationArray;  //当前未定义的点


@property RTTMapPointAnnotation *currentlySelectedAnnotation;  //当前选择的点；由外部selected的回调函数设置
@property RTTMapPointAnnotation *waitingPOIResultAnnotation;  //当前等待返回POI结果的点；由外部设置

//@property RTTRunningDataSet *runningDataset;

//- (STPointLineDistInfo) getNearestDistanceOfRoad:(BMKMapPoint)LoctionPoint roadPoints:(BMKMapPoint *)roadPoints pointCnt:(int) pointCount;
//
//- (int) GetRoadNamesFromBMKRoute:(BMKRoute*) route withRetArray:(NSMutableArray *)retArray;
//- (NSString *) getRoadNameFromStepContent:(NSString *)stepContent;
//- (RTTStepInfo *) getStepInfoFromStepContent:(NSString *)stepContent;
//- (BMKMapRect) mapRectMakeFromPoint:(BMKMapPoint) point1 withPoint:(BMKMapPoint) point2;
//- (BOOL) getPositionFromRoute:(BMKRoute *)route withLocation:(CLLocationCoordinate2D) locat andRetStepIndex:(int *)retStepIndex andretPointsIndex:(int*) retPointsIndex;
//- (bool) isPointInLine:(CLLocationCoordinate2D)location withStepA:(BMKStep*) step_a andStepB:(BMKStep*) step_b;

- (void) setCenterOfMapView:(CLLocationCoordinate2D)coordinate;
- (void) DrawTrafficPolyline:(NSMutableArray*)trafficSegList;
- (void) AddDrivingRouteOverlay:(BMKRoute*) route;
- (void) DrawSpeedPolyline: (double) speed startPoint:(CLLocationCoordinate2D)startPoint endPoint:(CLLocationCoordinate2D)endPoint;
- (void) addRouteGuidePoints;
- (void) changeMapVisibleRect:(BMKRoute*) route withIndex:(int) stepIndex;
- (RTTMapPointAnnotation*) addAnnotation2Map:(CLLocationCoordinate2D)coordinate withType:(RTTEN_MAPPOINTTYPE) type addr:(NSString*) addrTxt;
- (CLLocationCoordinate2D)addUndefAnnotationWithTouchPoint:(CGPoint) touchPoint;

- (RTTMapPointAnnotation*) getSelectedAnnotation;
- (void) removeAllTrafficPolylines;
- (void) removeAllUndefAnnotation;
-(void) setWaitingPOIAnnotationAddress:(BMKAddrInfo*)addrinfo;

- (CLLocationCoordinate2D) getCurLocation;
- (BOOL) checkIfLocOutofRange;

@end





