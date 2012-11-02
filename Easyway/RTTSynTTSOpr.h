//
//  RTTSynTrafficTTSOpr.h
//  Easyway95
//
//  Created by Sean.Yie on 12-9-25.
//
//

#import <Foundation/Foundation.h>
#import "iFlyMSC/IFlySynthesizerControl.h"

// 文本框
#define H_BACK_TEXTVIEW_FRAME		CGRectMake(6, 0, 308, 187)
//#define H_TEXTVIEW_FRAME			CGRectMake(10, 3, 300, 179)
#define H_TEXTVIEW_FRAME			CGRectMake(6, 0, 308, 185)

// 图片名称
//#define PNG_BUTTON_NORMAL	@"commonnormal.png"
//#define PNG_BUTTON_PRESSED	@"commondown.png"
#define PNG_CONTENT_BACK	@"editbox.png"

//#define H_CONTROL_FRAME CGRectMake(20, 70, 282, 210)
#define H_CONTROL_ORIGIN CGPointMake(20, 70)

//此appid为您所申请,请勿随意修改
#define APPID @"4fb78f39"
#define ENGINE_URL @"http://dev.voicecloud.cn:1028/index.htm"


@interface RTTSynTTSOpr : NSOperation <IFlySynthesizerControlDelegate>
@property NSMutableArray *hiTTSArray;
@property NSMutableArray *miTTSArray;
@property NSMutableArray *loTTSArray;

@property int timeLoop;
@property (nonatomic) BOOL isInProgress;
@property int progressTimer;
//@property IFlySynthesizerControl *moSynControl;
//@property IFlySynthesizerControl *hiSynControl;
@property IFlySynthesizerControl *iFlySynthesizerControl;


//- (id) init:(NSMutableArray *) trafficArray bufflen:(int) FifoBuffLen tickTime:(int) loopPeriod;
- (id) init:(NSMutableArray *) hArray miArray:(NSMutableArray *) mArray loArray:(NSMutableArray *) lArray;

@end
