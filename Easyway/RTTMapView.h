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




//目前只是为了保证扩展性，继承了百度的MAPView类
@interface RTTMapView : BMKMapView


@property BMKPolyline     *pCurrentlyPolyLine;
@property NSMutableArray *trafficPolylineList;
@property BMKPolyline     *offsetPolyLine;
@property RTTMapPointAnnotation *offsetCenPoint;


@property RTTMapPointAnnotation *startPointAnnotation;
@property RTTMapPointAnnotation *endPointAnnotation;
//@property RTTMapPointAnnotation *undefAnnotation;
@property NSMutableArray *undefAnnotationArray;  //当前未定义的点


@property RTTMapPointAnnotation *currentlySelectedAnnotation;  //当前选择的点；由外部selected的回调函数设置
@property RTTMapPointAnnotation *waitingPOIResultAnnotation;  //当前等待返回POI结果的点；由外部设置


- (void) setCenterOfMapView:(CLLocationCoordinate2D)coordinate;
- (void) DrawTrafficPolyline:(NSMutableArray*)trafficSegList;
- (void) AddDrivingRouteOverlay:(BMKRoute*) route;
- (void) DrawSpeedPolyline: (double) speed startPoint:(CLLocationCoordinate2D)startPoint endPoint:(CLLocationCoordinate2D)endPoint;
//- (void) addRouteGuidePoints;
- (void) changeMapVisibleRect:(BMKRoute*) route withIndex:(int) stepIndex;
- (RTTMapPointAnnotation*) addAnnotation2Map:(CLLocationCoordinate2D)coordinate withType:(RTTEN_MAPPOINTTYPE) type addr:(NSString*) addrTxt;
- (CLLocationCoordinate2D)addUndefAnnotationWithTouchPoint:(CGPoint) touchPoint;

- (RTTMapPointAnnotation*) getSelectedAnnotation;
- (void) removeAllTrafficPolylines;
- (void) removeAllUndefAnnotation;
-(void) setWaitingPOIAnnotationAddress:(BMKAddrInfo*)addrinfo;

- (CLLocationCoordinate2D) getCurLocation;
- (BOOL) checkIfLocOutofRange;

- (void) lineCurLoc2MapCenterLoc:(CGPoint)centerPoint;

@end





