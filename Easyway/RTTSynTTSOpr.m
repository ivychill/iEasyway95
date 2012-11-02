//
//  RTTSynTrafficTTSOpr.m
//  Easyway95
//
//  Created by Sean.Yie on 12-9-25.
//
//

#import "RTTSynTTSOpr.h"

@implementation RTTSynTTSOpr
@synthesize hiTTSArray;
@synthesize miTTSArray;
@synthesize loTTSArray;
@synthesize timeLoop;
@synthesize isInProgress;
@synthesize progressTimer;
@synthesize iFlySynthesizerControl;
//@synthesize moSynControl;
//@synthesize hiSynControl;

- (id) init:(NSMutableArray *) hArray miArray:(NSMutableArray *) mArray loArray:(NSMutableArray *) lArray
{
    self = [super init];

    hiTTSArray = hArray;
    miTTSArray = mArray;
    loTTSArray = lArray;
    
    //trafficStrArray = trafficArray;//[[NSMutableArray alloc] initWithCapacity:FifoBuffLen];
    isInProgress = NO;
    //timeLoop  = loopPeriod;
    progressTimer = 0;
    
//    NSString *initParam = [[NSString alloc] initWithFormat:
//						   @"server_url=%@,appid=%@",ENGINE_URL,APPID];
//	
//	// 合成控件
//	iFlySynthesizerControl = [[IFlySynthesizerControl alloc] initWithOrigin:H_CONTROL_ORIGIN theInitParam:initParam];
//	iFlySynthesizerControl.delegate = self;
//	//[self.view addSubview:iFlySynthesizerControl];
//    
//    [iFlySynthesizerControl setShowUI:NO];
    
    return self;
}

- (void)main
{
    
    @autoreleasepool
    {
        NSString *initParam = [[NSString alloc] initWithFormat:
                               @"server_url=%@,appid=%@",ENGINE_URL,APPID];
        
        // 合成控件
        iFlySynthesizerControl = [[IFlySynthesizerControl alloc] initWithOrigin:H_CONTROL_ORIGIN theInitParam:initParam];
        iFlySynthesizerControl.delegate = self;
        //[self.view addSubview:iFlySynthesizerControl];
        
        [iFlySynthesizerControl setShowUI:NO];
        
//        // 合成控件
//        hiSynControl = [[IFlySynthesizerControl alloc] initWithOrigin:H_CONTROL_ORIGIN theInitParam:initParam];
//        hiSynControl.delegate = self;
//        //[self.view addSubview:iFlySynthesizerControl];
//        
//        [hiSynControl setShowUI:NO];
//        
//        // 合成控件
//        moSynControl = [[IFlySynthesizerControl alloc] initWithOrigin:H_CONTROL_ORIGIN theInitParam:initParam];
//        moSynControl.delegate = self;
//        //[self.view addSubview:iFlySynthesizerControl];
//        
//        [moSynControl setShowUI:NO];
        
        while (true)
        {
            sleep(1);
            
#if defined(DEBUG)
            if (hiTTSArray.count >0 || miTTSArray.count >0 || loTTSArray.count >0)
            {
                NSLog(@"into TTS synthinize loop, hi=%d, mi=%d, lo=%d", hiTTSArray.count, miTTSArray.count, loTTSArray.count);
            }
#endif
            if (isInProgress)
            {
                if (hiTTSArray.count > 0) //如果最高优先级有数据，则抢占
                {
                    [iFlySynthesizerControl cancel];
                    isInProgress = NO;
                    NSLog(@"高优先级抢占");
                    //这里不紧接着播，是因为讯飞API需要先等待一段时间才能继续处理，否则失败
                }
                else
                {
                    //NSLog(@"Progressing");
                    progressTimer--;   //防止异常的超时保护，初始设置建议为30S
                    if (progressTimer ==0)
                    {
                        NSLog(@"语音合成响应超时");
                        [iFlySynthesizerControl cancel];
                        isInProgress = NO;
                    }
                }
                continue;
            }
            
            
            if (hiTTSArray.count > 0) //如果最高优先级有数据，顺序最先处理
            {
                NSString *strTTS =  [[NSString alloc] initWithString:[hiTTSArray objectAtIndex:0]];
                [self startHighPerioritySynTTS:strTTS];
                
                [hiTTSArray removeObjectAtIndex:0];
                continue;
            }
            
            if (miTTSArray.count > 0)
            {
                //发送合成请求；
                NSString *strTTS =  [[NSString alloc] initWithString:[miTTSArray objectAtIndex:0]];
                NSLog(@"Traffic Array Count=%d", miTTSArray.count);
                [self startSynTTS:strTTS];
                [miTTSArray removeObjectAtIndex:0];
                continue;
            }
            
            if (loTTSArray.count > 0)
            {
                //发送合成请求；
                NSString *strTTS =  [[NSString alloc] initWithString:[loTTSArray objectAtIndex:0]];
                NSLog(@"Traffic Array Count=%d", loTTSArray.count);
                [self startSynTTS:strTTS];
                [loTTSArray removeObjectAtIndex:0];
            }

        }
    }
    
} 

- (BOOL) startSynTTS:(NSString*) strInfo
{
    NSLog(@"Will Send TTS Request: %@", strInfo);
    if ((strInfo == nil) && [strInfo isEqualToString:@""])
    {
        return NO;
    }
    
    [iFlySynthesizerControl setText:strInfo theParams:nil];
    BOOL ret = [iFlySynthesizerControl start];
    if(ret)
    {
        //[self disableButton];
        NSLog(@"Begin TTS.....");
        isInProgress = YES;
        progressTimer = 60;
    }
    else
    {
        NSLog(@"Synthesize Fault......");
    }
    
    return ret;
}

- (BOOL) startHighPerioritySynTTS:(NSString*) strInfo
{
    NSLog(@"Will Send TSS Request");
    [iFlySynthesizerControl setText:strInfo theParams:nil];
    BOOL ret = [iFlySynthesizerControl start];
    if(ret)
    {
        //[self disableButton];
        NSLog(@"Begin Hi TTS.....");
        isInProgress = YES;
        progressTimer = 60;
    }
    else
    {
        NSLog(@"Synthesize Fault......");
    }
    
    return ret;
}


//	合成结束回调, mainThread
- (void)onSynthesizerEnd:(IFlySynthesizerControl *)iFlySynthesizerControl theError:(SpeechError) error
{
	NSLog(@"finish.....");
	//[self enableButton];
    self.isInProgress = NO;
	
	NSLog(@"upFlow:%d,downFlow:%d",[self.iFlySynthesizerControl getUpflow], [self.iFlySynthesizerControl getDownflow]);
}
//xlhou add 20120305
- (void)onSynthesizerBufferProgress:(float)bufferProgress
{
    //NSLog(@"onSynthesizerBufferProgress = %f",bufferProgress);
}
- (void)onSynthesizerPlayProgress:(float)playProgress
{
    //NSLog(@"onSynthesizerPlayProgress = %f",playProgress);
//    if (playProgress >= 99.0)
//    {
//        isInProgress = NO;
//    }
}


@end
