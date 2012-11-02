//
//  RTTSynthesizeTraffic.m
//  Easyway95
//
//  Created by Sean.Yie on 12-9-25.
//
//

#import "RTTSynthesizeTTS.h"
#import "RTTSynTTSOpr.h"


@implementation RTTSynthesizeTTS
@synthesize speechSynOprQue;
@synthesize hiTTSArray;
@synthesize miTTSArray;
@synthesize loTTSArray;
@synthesize loArrayBuffLen;

@synthesize synTTSOpr;

- (id) init:(int) FifoBuffLen
{
    loArrayBuffLen = FifoBuffLen;
    hiTTSArray = [[NSMutableArray alloc] initWithCapacity:1];
    miTTSArray = [[NSMutableArray alloc] initWithCapacity:3];
    loTTSArray = [[NSMutableArray alloc] initWithCapacity:FifoBuffLen];
    
    synTTSOpr = [[RTTSynTTSOpr alloc] init:hiTTSArray miArray:miTTSArray loArray:loTTSArray];
        
    speechSynOprQue = [[NSOperationQueue alloc] init];
    
    [speechSynOprQue addOperation:synTTSOpr];
    
    return self;
}




- (void) addEmegencyStr:(NSString*) strInfo
{
    if (hiTTSArray.count >= 1)
    {
        [hiTTSArray removeAllObjects];
    }
    [hiTTSArray addObject:strInfo];

}
- (void) addGuideStr:(NSString*) strInfo
{
    if (miTTSArray.count >= 3)
    {
        [miTTSArray removeObjectAtIndex:0];
    }
    [miTTSArray addObject:strInfo];
}

- (void) addTrafficStr:(NSString*) strInfo
{
    if (loTTSArray.count >= loArrayBuffLen)
    {
        [loTTSArray removeObjectAtIndex:0];
    }
    [loTTSArray addObject:strInfo];
}

@end
