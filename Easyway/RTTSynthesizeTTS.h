//
//  RTTSynthesizeTraffic.h
//  Easyway95
//
//  Created by Sean.Yie on 12-9-25.
//
//
@class RTTSynTTSOpr;

#import <Foundation/Foundation.h>

@interface RTTSynthesizeTTS : NSObject

@property NSOperationQueue *speechSynOprQue;
@property NSMutableArray *hiTTSArray;
@property NSMutableArray *miTTSArray;
@property NSMutableArray *loTTSArray;
@property int loArrayBuffLen;

@property RTTSynTTSOpr *synTTSOpr;

- (id) init:(int) FifoBuffLen;
- (void) addEmegencyStr:(NSString*) strInfo; //高优先级  譬如重新获取路况（实际是路径重新规划）
- (void) addGuideStr:(NSString*) strInfo;    //中优先级  譬如提示前方拥堵，或者提示等
- (void) addTrafficStr:(NSString*) strInfo;  //低优先级  譬如路况

@end
