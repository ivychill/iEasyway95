//
//  RTTViewController.h
//  Easyway
//
//  Created by Ye Sean on 12-8-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

@class RTTMapPointAnnotation;
@class RTTMapView;
//@class RNSwipeBar;
@class ZMQContext;
@class ZMQSocket;
@class RTTRunningDataSet;
@class RTTGuideBoardView;
@class RTTSuggestionListViewController;
//@class RTTTopBarView;
@class RTTTrafficBoardView;
@class RTTModeActivityIndicatorView;
@class RTTComm4TSS;
@class RTTSynthesizeTTS;
@class RTTSearchBarView;

@class Reachability;

#import <UIKit/UIKit.h>
#import "BMapKit.h"
//#import "RTTMapView.h"
#import "RNSwipeBar.h"
#import "RttGTSSCommunication.h"
#import "RTTMapPointSettingViewController.h"
#import "RTTToolbarView.h"
#import "RTTVCDelegate.h"
#import "RTTSynthesizeTTS.h"




//为了方便异步的异常处理，下面这些百度服务动作必须同时只能进行一个，靠定时器保护
enum RTTEN_ACTIVITYTYPE {
    RTTEN_ACTIVITYTYPE_IDLE = 0,
    RTTEN_ACTIVITYTYPE_GETTINGPOI = 1,
    RTTEN_ACTIVITYTYPE_GETTINGGEO = 2,
    RTTEN_ACTIVITYTYPE_GETTINGROUTE = 3,
    RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE = 4,
    RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE = 5,
};


@interface RTTViewController : UIViewController <UITableViewDelegate, RNSwipeBarDelegate, BMKMapViewDelegate, BMKSearchDelegate, UISearchBarDelegate, RttGTSSCommunication, RttgRDVCdelegate, RTTVCDelegate>
//<BMKMapViewDelegate, BMKSearchDelegate, RttGTSSCommunication, RttgRDVCdelegate, UISearchBarDelegate, RttGPassDataV2C, UIGestureRecognizerDelegate, IFlySynthesizerControlDelegate> 

{
    IBOutlet UIView *mCenterView;
        
    RTTMapView *mMapView;
    RNSwipeBar *mSwipeBar;
    BMKSearch  *mBMKSearch;
    RTTGuideBoardView *mGuideBoard;
    RTTTrafficBoardView *mTrafficInfoBoard;
    RTTSearchBarView *mTopSearchBar;

    UIButton *mRetryButton;
    
    RTTSuggestionListViewController *mSuggestionListVC;
    
    UIActivityIndicatorView *mActivityIndicatorView;
    RTTModeActivityIndicatorView *mModeIndicatorView;

    RTTRunningDataSet *runningDataset;
    
    CLLocationCoordinate2D mLastOnPlanLocation;
    

    RTTComm4TSS *mComm4TSS;
    int mTSSMessageSerialNum;
    
    NSTimer *mModeIndicatorTimer;
    NSTimer *mActivityTimer;
    NSTimer *mCheckBKJobTimer;
    NSTimer *mFirstTimeInitDelayToDoTimer;
    NSTimer *mSendSampePoints2TSSTimer;
    NSTimer *mClearOutDateTimer;

    
    enum RTTEN_ACTIVITYTYPE mRunningActivity;

    
    int mSpeedIndex;
    NSMutableArray *mSpeedSedList;
    NSMutableArray *mSpeedSamplePoints;

    
    RTTSynthesizeTTS *mSynTTS;
    
    
    BOOL mIsOutofRange;
    
    BOOL mIsGetedH2ORoute;
    BOOL mISGetedO2HRoute;
}

//@property (nonatomic) CLLocationCoordinate2D lastOnPlanLocation;
@property CLLocationCoordinate2D currentlyRouteEndPoint;
@property NSString *currentlyRouteEndAddr;
@property BOOL isMoveMap;
@property CGPoint beginSpanPoint;


@property BOOL TTSSwitchOnOff;
@property BOOL autoScaleOnOff;
@property BOOL autoDetectOnOff;

@property Reachability *internetReachable;
@property Reachability *hostReachable;
@property BOOL internetActive;
@property BOOL hostActive;

@property (strong, nonatomic) IBOutlet UIButton *back2locBTN;
@property (strong, nonatomic) IBOutlet UIButton *showTrafficViewBTN;
@property (strong, nonatomic) IBOutlet UIButton *showSearchBarBTN;
@property (strong, nonatomic) IBOutlet UILabel *uiDestinationLBL;

- (IBAction)didSaveSpeedSegs:(id)sender;

- (IBAction)didShowTraffic:(id)sender;
- (IBAction)didPanOnMap:(id)sender;
- (IBAction)didLongPress:(UILongPressGestureRecognizer *)sender;
//- (IBAction)didShowRoutePreview:(id)sender;
//- (IBAction)didStart2Go:(id)sender;
//- (IBAction)didShowRoutePreviewAfterPlan:(id)sender;
- (IBAction)didBack2UserLocation:(id)sender;
- (IBAction)didShowSearchbar:(id)sender;

//- (IBAction)didTrafficTitleSwipeRight:(UISwipeGestureRecognizer *)sender;

- (NSInteger) detectPath;

- (bool) sendDeviceInfo2TSS:(NSData *)deviceToken;

-(void)checkNetworkStatus:(NSNotification*)notice;

@end
