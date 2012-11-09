//
//  RTTBMKSvrOperation.h
//  Easyway95
//
//  Created by Sean.Yie on 12-11-7.
//
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"


@interface RTTBMKSvrOperation : NSOperation <BMKSearchDelegate>


@property BOOL isResultReturned;

@end
