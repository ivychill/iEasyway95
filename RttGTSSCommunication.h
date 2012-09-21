//
//  RttGTSSCommunication.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-6-20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RttGTSSCommunication <NSObject>
- (void) OnRceivePacket:(NSData*) rcvdata;
@end
