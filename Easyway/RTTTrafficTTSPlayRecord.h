//
//  RTTTrafficTTSPlayRecord.h
//  Easyway95
//
//  Created by Sean.Yie on 12-9-26.
//
//

#import <Foundation/Foundation.h>

@interface RTTTrafficTTSPlayRecord : NSObject
@property int stepIndex;
@property int pointIndex;
@property int DistanceIndex; //0,500,1000,1500=0,1,2,3,

- (void) record:(double)distance stepIndex:(int)step pointIndex:(int)pntIdx;
- (BOOL) ifRecorded:(double)distance stepIndex:(int)step pointIndex:(int)pntIdx;
- (void) clear;


@end
