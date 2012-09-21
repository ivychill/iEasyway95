//
//  RttGSettingRoutePointViewController.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RttGPassDataV2C.h"

//@protocol passSelectedtoVCDelegate
//
//- (void)didResultlistSelected:(NSString *)poiName;
//
//@end


@interface RttGDLTViewControler: UITableViewController 
{
//	NSString		*_searchText;
//	NSString		*_selectedText;
//	NSMutableArray	*_resultList;
//	id <PassValueDelegate>	_delegate;
}

@property (nonatomic, copy)NSString		*_searchText;
@property (nonatomic, copy)NSString		*_selectedText;
@property (nonatomic, retain)NSMutableArray	*_resultList;
@property (assign) id <RttGPassDataV2C> _delegate;
//@property NSArray *poiSuggestionList;


- (void)updateData;

@end
