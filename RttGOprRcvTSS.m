//
//  RttGOprRcvTSS.m
//  RTTGUIDE
//
//  Created by Ye Sean on 12-6-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

//#import "RttGViewController.h"
#import "RttGOprRcvTSS.h"

@implementation RttGOprRcvTSS


@synthesize zmqTSSContx;
@synthesize zmqTSSSocket;
@synthesize delegate;

- (id) initWithZMQ:(ZMQContext*) zmqctx andSocket:(ZMQSocket*)zmqsocket
{
    self = [super init];
    self.zmqTSSContx = zmqctx;
    self.zmqTSSSocket = zmqsocket;
    
    return self;
}

- (void)main 
{ 
    
    @autoreleasepool
    {
//        NSString *text = @"########Data###########";
//        
//        [self.delegate performSelectorOnMainThread:@selector(OnRceivePacket:) withObject:(NSData*)text waitUntilDone:0];// modes:nil];
//        NSLog(@"Sending Message with data: %@", text);

        while (true)
        {
            
            NSData *reply = [[zmqTSSSocket receiveDataWithFlags:0] copy];
            //reply.copy;
            
            if (reply != nil)
            {
                [self.delegate performSelectorOnMainThread:@selector(OnRceivePacket:) withObject:(NSData*)reply waitUntilDone:0];
                //NSLog(@"Received reply");
            }
        }
    }
    
} 

@end
