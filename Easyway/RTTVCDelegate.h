//
//  RTTVCDelegate.h
//  Easyway
//
//  Created by Ye Sean on 12-8-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
@class RttGHistoryPathInfo;
#import <Foundation/Foundation.h>

@protocol RTTVCDelegate <NSObject>

//- (void)didBookmarkPathSelected:(RttGHistoryPathInfo*) pathInfo;       //返回选中路径书签中的某条路径

- (void)didResultlistSelected:(NSString *)poiName;  //返回选中的POI的名字

//- (void)didRTTToolbarButtonWasPressed:(NSString*)buttonName;

- (void)didToolbarHomeSettingBTN:(id)sender;

- (void)didToolbarAccountBTN:(id)sender;

//- (void)didToolbarBookmarkBTN:(id)sender;

- (void)didToolbarGoHomeBTN:(id)sender;

- (void)didToolbarGoOfficeBTN:(id)sender;

- (void)didHomeAddrReset:(id)sender;

- (void)gotUserLoginToken:(NSString*) token;

- (void)didAddrSearchWasPressed:(NSString*)inputStr;
- (void)didAddrSearchInputWasChanged:(NSString*)inputStr;
- (void)didAddrSearchBegin:(id)sender;
- (void)didHideAddrSearchBar:(id)sender;

- (void)didTTSSwitchOnOff:(BOOL)isOn;
- (void)didAutoDetectSwitchOnOff:(BOOL)isOn;
- (void)didAutoScaleMapSwitchOnOff:(BOOL)isOn;




@end
