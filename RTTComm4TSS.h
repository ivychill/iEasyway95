//
//  RTTComm4TSS.h
//  Easyway
//
//  Created by Ye Sean on 12-9-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RttGTSSCommunication.h"
#import "ZMQSocket.h"

@class ZMQContext;
@class ZMQSocket;


@interface RTTComm4TSS : NSObject
{
    ZMQContext *zmqTSSContext;
    ZMQSocket *zmqTSSSocket;
    
    NSOperationQueue *rttThreadQue; 
}

- (id) initWithEndpoint:(NSString*) endpoint delegate:(NSObject <RttGTSSCommunication> *) delegate;
- (BOOL)sendData:(NSData *)messageData withFlags:(ZMQMessageSendFlags)flags;


@end
