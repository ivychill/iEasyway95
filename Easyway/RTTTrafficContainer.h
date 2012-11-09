//
//  RTTTrafficContainer.h
//  Easyway95
//
//  Created by Sean.Yie on 12-10-31.
//
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"
#import "RttGRoadInfo.h"
#import "RttGRouteInfo.h"
#import "RttGMapDataset.h"
#import "Tss.pb.h"
//#import "RttGHistoryPathInfo.h"
#import "Tss.pb.h"
#import "RTTTrafficTTSPlayRecord.h"

#import "RTTMapKit.h"

@interface RTTTrafficContainer : NSObject


@property NSMutableArray *filteredRouteTrafficList;         //RttGMatchedTrafficInfo
@property NSMutableArray *routeTrafficFromTSS ;             //RTTFormatedTrafficFromTSS;
@property NSMutableArray *hotTrafficFromTSS;                //RTTFormatedTrafficFromTSS;

//- (id) init;
- (void) removeAllFilteredTraffic;
- (void) removeAllRouteTraffic;
- (void) removeAllHotTraffic;
- (void) reFilteTraffic:(NSMutableArray*) RouteTrafficList roadList:(NSMutableArray*)roadList;

- (void) clearOutofDateTrafficData4Hot;
- (void) addTSSTraffic2RunningDataset4Hot:(NSString *)roadName segment:(LYSegmentTraffic*) trfSegment;

- (void) clearOutofDateTrafficData4Route;
- (NSMutableArray *) addTSSTraffic2RunningDataset4Route:(NSString *)roadName segment:(LYSegmentTraffic*) trfSegment roadList:(NSMutableArray*)roadList;

- (void) reFilteTrafficWithRoadList:(NSMutableArray*)roadList;
- (RttGMatchedTrafficInfo *) createTrafficInfo2Dataset:(RTTFormatedTrafficFromTSS*) segTraffic withRttgRoadInfo:(RttGRoadInfo*) roadInfo;

- (BOOL) checkIfTrafficOnAhead:(RttGMatchedTrafficInfo*) trfInfo steIndex:(int) stepIndex pointIndex:(int)pointIndex;
- (RttGMatchedTrafficInfo*) getNearestTrafficSeg:(int) stepIndex pointIndex:(int)pointIndex;

@end
