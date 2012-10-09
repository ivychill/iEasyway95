//
//  RTTTrafficTTSPlayRecord.m
//  Easyway95
//
//  Created by Sean.Yie on 12-9-26.
//
//

#import "RTTTrafficTTSPlayRecord.h"

@implementation RTTTrafficTTSPlayRecord
@synthesize DistanceIndex;
@synthesize pointIndex;
@synthesize stepIndex;


- (void) record:(double)distance stepIndex:(int)step pointIndex:(int)pntIdx
{
    stepIndex = step;
    pointIndex = pntIdx;
    DistanceIndex = (int)(distance/500);
}

- (BOOL) ifRecorded:(double)distance stepIndex:(int)step pointIndex:(int)pntIdx
{
    if (stepIndex == step && pointIndex == pntIdx)
    {
        int interrange = (int)(distance/500);
        if (interrange >= DistanceIndex)
        {
            return true;
        }
    }
    return false;
}

- (void) clear
{
    stepIndex = 999999999999;
    pointIndex = 99999999999;
    DistanceIndex = 10000000;
}

@end
