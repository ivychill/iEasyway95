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
    //IBOutlet UIView *mMapView;
    

    IBOutlet UIView *mCenterView;
    
    //非路径提示版本这些都不用了
//    IBOutlet UIButton *mRoutePreviewBTN;
//    IBOutlet UIView *mInfoboadView;
//    IBOutlet UIButton *mOnGoBTN;
//    IBOutlet UIButton *mRoutePreviewInInfoBoadBTN;
    
    
    RTTMapView *mMapView;
    RNSwipeBar *mSwipeBar;
    BMKSearch  *mBMKSearch;
    RTTGuideBoardView *mGuideBoard;
    RTTTrafficBoardView *mTrafficInfoBoard;
    RTTSearchBarView *mTopSearchBar;

    
    RTTSuggestionListViewController *mSuggestionListVC;
    RNSwipeBar *mTopbar;
    
    UIActivityIndicatorView *mActivityIndicatorView;
    RTTModeActivityIndicatorView *mModeIndicatorView;

    
//    BOOL mIsHomeAddrSetting;
//    BMKPoiInfo *mHomeAddrInfo;
//    BMKPoiInfo *mOfficeAddrInfo;
//    NSInteger *mCurrentRoute;
    
//    BMKPolyline     *pCurrentlyPolyLine;
//    NSMutableArray *trafficPolylineList;
//    
//    RTTMapPointAnnotation *pStartPointAnnotation;
//    RTTMapPointAnnotation *pEndPointAnnotation;
//    RTTMapPointAnnotation *pHomePointAnnotation;
//    RTTMapPointAnnotation *pUndefAnnotation;
//
//    RTTMapPointAnnotation *pCurrentlySelectedAnnotation;  //当前选择的点
//    RTTMapPointAnnotation *pWaitPOIResultAnnotation;  //当前等待返回POI结果的点
//    
//    NSMutableArray *mAnnotationArray;  //当前未定义的点
//
//
//    
    RTTRunningDataSet *runningDataset;
    
    CLLocationCoordinate2D mLastOnPlanLocation;
    
    //BOOL isSearchBarInuse;
    
//    ZMQContext *zmqTSSContext;
//    ZMQSocket *zmqTSSSocket;
//    NSOperationQueue *rttThreadQue; 
    RTTComm4TSS *mComm4TSS;
    
//    NSTimer *locUpdateTimer;
//    NSTimer *btnDismissTimer;
    NSTimer *mModeIndicatorTimer;
    
    enum RTTEN_ACTIVITYTYPE mRunningActivity;
    NSTimer *mActivityTimer;

    
//    bool isBTNDismissTimeOut;
//    int iTestLocIndex;
    
//    BMKPointAnnotation *pTestCareAnnotation;
//    NSMutableArray *testLocationList;
//
//    NSTimer *mStart2GoTimer;
//    int     mTicks4StartGo;
    
    int mTSSMessageSerialNum;
    
    int mSpeedIndex;
    NSMutableArray *mSpeedSedList;
    
    RTTSynthesizeTTS *mSynTTS;
    
    BOOL mIsOutofRange;
    
    //UIDevice *dev; //= [UIDevice currentDevice];
    //NSString *deviceVersion; //= dev.systemVersion;
    //NSString *deviceUuid; //= dev.uniqueIdentifier;
}

//@property (nonatomic) CLLocationCoordinate2D lastOnPlanLocation;
@property CLLocationCoordinate2D currentlyRouteEndPoint;
@property NSString *currentlyRouteEndAddr;
@property BOOL isViewMap;

@property BOOL TTSSwitchOnOff;
@property BOOL autoScaleOnOff;
@property BOOL autoDetectOnOff;

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


- (NSInteger) detectPath;

- (bool) sendDeviceInfo2TSS:(NSData *)deviceToken;



@end
