//
//  RTTSuggestionListViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"

@interface RTTSuggestionListViewController : UITableViewController

@property (nonatomic, copy)NSString		*searchText;
@property (nonatomic, copy)NSString		*selectedText;
@property (nonatomic, retain)NSMutableArray	*resultList;
@property (assign) id <RTTVCDelegate> delegate;

- (void)updateData;
- (void)clearData;

@end
