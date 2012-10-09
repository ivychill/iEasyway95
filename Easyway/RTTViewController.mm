//
//  RTTViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTViewController.h"
#import "RNSwipeBar.h"
#import "RTTToolbarView.h"
#import "RTTMapPointAnnotation.h"
#import "RTTMapView.h"

//#import "ZMQSocket.h"
//#import "ZMQContext.h"
#import "RttGTSSCommunication.h"
#import "RTTMapPointAnnotation.h"
#import "RttGRoadInfo.h"
#import "RttGRouteInfo.h"
#import "RttGMapDataset.h"
#import "Tss.pb.h"
//#import "RttGPolyline.h"
//#import "RttGSettingRoutePointViewController.h"
#import "RTTRunningDataSet.h"
//#import "RttGDLTViewControler.h"
//#import "RttGPassDataV2C.h"
//#import "RttGRoutePreviewViewController.h"
//#import "RttGOprRcvTSS.h"

#import "RTTMapPointSettingViewController.h"
#import "RTTRoutePreviewViewController.h"
#import "RTTRouteBookmarkViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RTTGuideBoardView.h"
#import "RTTSuggestionListViewController.h"
#import "RTTTopBarView.h"
#import "RTTHomeAddrViewController.h"
#import "RTTTrafficListViewController.h"
#import "RTTIntroPageViewController.h"
#import "RTTAccountViewController.h"
#import "RTTTrafficBoardView.h"
#import "RTTModeActivityIndicatorView.h"
#import "RTTComm4TSS.h"
#import "RTTSynthesizeTTS.h"


#pragma mark -
#pragma mark Some Gloable Process
@interface RouteAnnotation : BMKPointAnnotation
{
	int _type; ///<0:起点 1：终点 2：公交 3：地铁 4:驾乘
	int _degree;
}

@property (nonatomic) int type;
@property (nonatomic) int degree;
@end

@implementation RouteAnnotation

@synthesize type = _type;
@synthesize degree = _degree;
@end


@interface CandidateSteps:NSObject
{
	int _index;
	CLLocationCoordinate2D _StPoint;
    CLLocationCoordinate2D _EdPoint;
}
@property (nonatomic) int index;
@property (nonatomic) CLLocationCoordinate2D StPoint;
@property (nonatomic) CLLocationCoordinate2D EdPoint;
@end

@implementation CandidateSteps
@synthesize index = _index;
@synthesize StPoint = _StPoint;
@synthesize EdPoint = _EdPoint;
@end

//判断pnt是否在由（p1, p2）两点组成的线段范围内
//方法：计算投影点，然后判断投影点是否在线段内；如果是，则返回距离，否则返回－1.0；
//Note: 允许投影点在线段两端的误差，目前本函数还没加入这个误差；
CLLocationDistance GetNearLineDistance(BMKMapPoint pnt,  BMKMapPoint p1, BMKMapPoint p2, BMKMapPoint *retproj)
{
    double a;    
    double b;    
    double c;    
    
    if(p2.x >= p1.y)   
    {   
        a=p2.y-p1.y;
        b=p1.x-p2.x;
        c=p1.y*p2.x-p1.x*p2.y;    
    }
    else   
    {   
        a=p1.y-p2.y;    
        b=p2.x-p1.x;    
        c=p2.y*p1.x-p2.x*p1.y;    
    }
    
    double dSPtX = (b*b*pnt.x - a*(b*pnt.y + c))/(a*a + b*b);
    double dSPtY = (a*a*pnt.y - b*(a*pnt.x + c))/(a*a + b*b);
    
    if (retproj)
    {
        retproj->x = dSPtX;
        retproj->y = dSPtY;
    }
    
    //投影点是否在线段内；之所以这么写是为了避免复杂浮点运算；
    if (p1.x < p2.x)//横坐标判断
    {
        if ((dSPtX < p1.x) || (dSPtX > p2.x)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    else 
    {
        if ((dSPtX > p1.x) || (dSPtX < p2.x)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    
    if (p1.y < p2.y) //纵坐标判断
    {
        if ((dSPtY < p1.y) || (dSPtY > p2.y)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    else 
    {
        if ((dSPtY > p1.y) || (dSPtY < p2.y)) //不在线段内，还没加入误差
        {
            return -1.0;
        }
    }
    
    //double s = fabs(a*pnt.x+b*pnt.y+c)/sqrt(a*a+b*b);
    //return s;
    
    BMKMapPoint projectionPoint;
    projectionPoint.x = dSPtX;
    projectionPoint.y = dSPtY;
    CLLocationDistance distance = BMKMetersBetweenMapPoints(pnt, projectionPoint);
    return distance;
    
};

struct STPointLineDistInfo
{
    CLLocationDistance distance;
    BMKMapPoint projection;
    int pointindex;
};

CLLocationDistance getNearestDistanceOfRoad(BMKMapPoint LoctionPoint, BMKMapPoint *roadPoints, int pointCount, STPointLineDistInfo *retPLDInfo=nil)
{
    if (pointCount < 2)
        return -1.0;
    
    CLLocationDistance nearestDistance = BMKMetersBetweenMapPoints(LoctionPoint, roadPoints[0]);
    if (retPLDInfo!=nil){
        retPLDInfo->projection = roadPoints[0];
        retPLDInfo->pointindex = 0;
    }
    
    BMKMapPoint projPoint;
    for (int i=0; i<(pointCount-1); i++)
    {
        CLLocationDistance dist = GetNearLineDistance(LoctionPoint, roadPoints[i], roadPoints[i+1], &projPoint);
        if ((dist>=0.0) && (dist <= nearestDistance))
        {
            nearestDistance = dist;
            if (retPLDInfo!=nil){
                retPLDInfo->pointindex = i;
                retPLDInfo->projection = projPoint;
            }
        }
        dist = BMKMetersBetweenMapPoints(LoctionPoint, roadPoints[i+1]); //避免落在投影外的情况，譬如凸折现连接外的点
        if ((dist>=0.0) && (dist <= nearestDistance))
        {
            nearestDistance = dist;
            if (retPLDInfo!=nil){
                retPLDInfo->pointindex = i;
                retPLDInfo->projection = roadPoints[i+1];
            }
        }
    }
    
    if (retPLDInfo!=nil){
        retPLDInfo->distance = nearestDistance;
    }
    
    return nearestDistance;
};



#pragma mark -
#pragma mark -
#pragma mark RTTViewController

@interface RTTViewController ()

@end

@implementation RTTViewController
@synthesize back2locBTN;
@synthesize showTrafficViewBTN;

#pragma mark -
#pragma mark view init
- (void)viewDidLoad
{
    NSLog(@"INIT....................................");
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //初始化百度地图相关
    [self initBaiduMap];

    //初始化各种窗口部件
    [self initMainViewUnit];

    //初始化各种运行时视图相关内存参数
    [self initRunningParam];
    
    //初始化和启动通信模块
    [self initCommUnit];
    
    //增加测试数据
    [self addTestData];
    
    
    [self initLoadData];

    [self processIntroPage];
    
    [self detectPath];
    
}

- (void)viewDidUnload
{
    //mMapView = nil;
    mAddrSearchBar = nil;
    mCenterView = nil;
    mRoutePreviewBTN = nil;
    mInfoboadView = nil;
    mOnGoBTN = nil;
    mRoutePreviewBTN = nil;
    [self setBack2locBTN:nil];
    [self setShowTrafficViewBTN:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) initTimer
{
    
}

- (void) initBaiduMap
{
    //初始化百度地图相关
    RTTMapView *baiduMapView = [[RTTMapView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    if (!baiduMapView)
    {
        NSLog(@"Error when init baidu map");
        return;
    }
    
    mMapView = baiduMapView;
    
    mMapView.delegate = self;
    CLLocationCoordinate2D centerlocation = CLLocationCoordinate2DMake(22.546154, 114.06859);
    //[mMapView setCenterCoordinate:(centerlocation)];
    [self setCenterOfMapView:centerlocation];
    
    //百度地图API，允许获取和显示用户当前位置
    [mMapView setShowsUserLocation:YES];
    // 地图比例尺级别，在手机上当前可使用的级别为3-18级
    [mMapView setZoomLevel:15];
    
    [mCenterView addSubview:mMapView];
    //mCenterView = mMapView;
    
//    CALayer *overlayCover = [[CALayer alloc] init];
//    overlayCover.backgroundColor = [[[UIColor brownColor] colorWithAlphaComponent:0.8] CGColor];
//    [mMapView.layer addSublayer:overlayCover];
    
    //[mMapView setCenterCoordinate:(mMapView.userLocation.coordinate)];
    [self setCenterOfMapView:(mMapView.userLocation.coordinate)];
    
    if (!mBMKSearch)
    {
        mBMKSearch = [[BMKSearch alloc] init];
        mBMKSearch.delegate = self;
    }
}

- (void) initMainViewUnit
{
    //初始化各种窗口部件
    [mRoutePreviewBTN setHidden:NO];
    
    //设置infoboard
    [self initInfoBoard];
    [self hideInfoBoardforStart2Go];
    
    
    //设置guide board
    [self initGuideBoard];
    [self hideGuideBoard];
    
    //设置Traffic board
    [self initTrafficBoard];
    [self hideTrafficBoard];
    
    [self initModeIndicator];
    [self closeModeIndicator];
    
    //设置搜索建议结果列表框
    [self initSuggestionListView];
    [self.view addSubview:mSuggestionListVC.view];
    
    [self initButtomBar];
    [self initTopBar];
    
    //地图上的小按钮
    //设置阴影
    back2locBTN.layer.shadowColor = [[UIColor blackColor] CGColor];
    back2locBTN.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    back2locBTN.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    back2locBTN.layer.shadowRadius = 10.0f; // 阴影发散的程度

    
    
#if defined (HUAWEIVER)
    [mAddrSearchBar removeFromSuperview];    
#endif

}

- (void) initRunningParam
{
    pCurrentlySelectedAnnotation = nil;
    pWaitPOIResultAnnotation = nil;
    
    pStartPointAnnotation = nil;
    pEndPointAnnotation = nil;
    pHomePointAnnotation = nil;
    pUndefAnnotation = nil;
    trafficPolylineList = [[NSMutableArray alloc] init];
    
    runningDataset = [[RTTRunningDataSet alloc] init];//运行时所有的数据集都在这个大类里头, datamodel
    
    mIsHomeAddrSetting = NO;
    
    mRunningActivity = RTTEN_ACTIVITYTYPE_IDLE;
    mActivityTimer = nil;
    
    mSpeedIndex = 0;
    mSpeedSedList = [[NSMutableArray alloc] initWithCapacity:1000];
    
    mIsOutofRange = NO;
    
    
    dev = [UIDevice currentDevice];
    deviceVersion = dev.systemVersion;
    deviceUuid = dev.uniqueIdentifier;
}

- (void) initCommUnit
{
    //初始化和启动通信模块
    mTSSMessageSerialNum = 0; //消息序列号
    
    mComm4TSS = [[RTTComm4TSS alloc] initWithEndpoint:@"tcp://roadclouding.com:7001" delegate:self];
    
    
    mSynTTS = [[RTTSynthesizeTTS alloc] init:10];
}

- (void) initLoadData
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (!documentsDirectory) {
        NSLog(@"Documents directory not found!");
    }
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"Savedatas.plist"];
    
    NSLog(@"PATH: %@", appFile);
    
    //Load Home Address Info
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *loadArray = [saveDefaults objectForKey:@"HomeOfficeSaveKey"];
    if (loadArray.count < 3)
    {
        return;
    }
    NSString *loadHomeAddr = [loadArray objectAtIndex:0];
    NSString *loadHomeLat = [loadArray objectAtIndex:1];
    NSString *loadHomeLon = [loadArray objectAtIndex:2];
    if (!loadHomeAddr || !loadHomeLat || !loadHomeLon)
    {
        return;
    }
    NSLog(@"str:%@, %@, %@",loadHomeAddr, loadHomeLat, loadHomeLon);
    
    __autoreleasing BMKPoiInfo *homePoi = [[BMKPoiInfo alloc] init];
    homePoi.address = loadHomeAddr;
    CLLocationCoordinate2D loadHomeLoc;
    loadHomeLoc.latitude = [loadHomeLat floatValue];
    loadHomeLoc.longitude = [loadHomeLon floatValue];
    homePoi.pt = loadHomeLoc;
    runningDataset.homeAddrInfo = homePoi;
}

- (void) processIntroPage
{
    if (runningDataset.homeAddrInfo)
    {
        return;
    }
    
    RTTIntroPageViewController *introPageVW = [[RTTIntroPageViewController alloc] init];
    introPageVW.delegate = self;
    [self.navigationController pushViewController:introPageVW animated:NO];

    
}

#pragma mark -
#pragma mark Timer process
- (void) setStart2GoTimer:(int) seconds
{
    if (mStart2GoTimer)
    {
        [mStart2GoTimer invalidate];
        mStart2GoTimer = nil;
    }
    mStart2GoTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(time2TickStartGo) userInfo:nil repeats:YES]; 
    mTicks4StartGo = 9;
}

- (void) stopStart2GoTimer
{
    if (mStart2GoTimer)
    {
        [mStart2GoTimer invalidate];
        mStart2GoTimer = nil;
    }
}

- (void) time2TickStartGo
{
    if (mTicks4StartGo <= 0)
    {
        [self start2Go];
    }
    else
    {
    NSString *strTitile = [[NSString alloc] initWithFormat:@"随路播报%1d", mTicks4StartGo]; 
    mOnGoBTN.titleLabel.text = strTitile;
    mTicks4StartGo--;
    }
}

- (void) setModeIndicatorTimer:(int) seconds
{
    if (mModeIndicatorTimer)
    {
        [mModeIndicatorTimer invalidate];
        mModeIndicatorTimer = nil;
    }
    mModeIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(didModeIndicatorTimeout) userInfo:nil repeats:NO]; 
}

- (void) didModeIndicatorTimeout
{
    //清除定时器的动作统一在Close中完成
    [self closeModeIndicator];
}

- (void) setRunningActivityTimer:(int) seconds activity:(RTTEN_ACTIVITYTYPE) acttype
{
    mRunningActivity = acttype;
    if (mActivityTimer)
    {
        [mActivityTimer invalidate];
        mActivityTimer = nil;
    }
    mActivityTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(didRunningActivityTimeout) userInfo:nil repeats:NO]; 
}

- (void) stopRunningActivityTimer
{
    if (mActivityTimer)
    {
        [mActivityTimer invalidate];
        mActivityTimer = nil;
    }
    
    mRunningActivity = RTTEN_ACTIVITYTYPE_IDLE;
}

- (void) didRunningActivityTimeout
{
    if (mActivityTimer)
    {
        [mActivityTimer invalidate];
        mActivityTimer = nil;
    }
    
    //进行超时错误处理
    NSString * errorMsg;
    switch (mRunningActivity) {
        case RTTEN_ACTIVITYTYPE_GETTINGPOI:
        {
            errorMsg = @"获取地址的PIO信息超时";
        }
            break;
            
        case RTTEN_ACTIVITYTYPE_GETTINGGEO:
        {
            errorMsg = @"获取地名对应的地理位置超时";
        }
            break;
            
        case RTTEN_ACTIVITYTYPE_GETTINGROUTE:
        {
            errorMsg = @"获取到目的地的路径超时";
        }
            break;
            
        case RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE:
        {
            errorMsg = @"获取到办公室的路径超时";
        }
            break;
            
        case RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE:
        {
            errorMsg = @"获取到家的路径超时";
        }
            break;
            
        default:
            break;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:errorMsg 
                                                      delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
    [alertView show];
    
    mRunningActivity = RTTEN_ACTIVITYTYPE_IDLE;
}

#pragma mark -
#pragma mark UI event process
//- (IBAction)didShowLeftView:(id)sender 
//{
////    if (!PointSettingView)
////    {
////        NSArray *nibObjs = [[NSBundle mainBundle] loadNibNamed:@"RoutPointSetting" owner:self options:nil];
////        PointSettingView = [nibObjs objectAtIndex:0];
////    }
////    
////    PointInfoLabel.text = pCurrentlyAnnotation.AddrString;
////    [self.view sendSubviewToBack:_mapView];
////    [self.view insertSubview:PointSettingView aboveSubview:_mapView];
//
//    [mNaviBar setHidden:YES];
//    [mLeftView setHidden:NO];
//}

- (void) gotUserLoginToken:(NSString*) token
{
    [runningDataset setUserToken:token];
    //[self sendUserProfile2Server:token];
    NSLog(@"Will Send Profile to Server");
}


- (IBAction)didSaveSpeedSegs:(id)sender
{
    //路况1
    //6.0对讯飞支持不好
    float verValue = deviceVersion.floatValue;
    if (verValue < 6.0)
    {
        [mSynTTS addEmegencyStr:@"您已经偏移路径，正在重新获取路况"];
        
        [mSynTTS addTrafficStr:@"深南大道 前方拥堵：南山大道路口到南新路路口 方向：西向"];
        
        [mSynTTS addTrafficStr:@"南海大道 前方拥堵: 北环立交到东滨路路口 方向：蛇口方向"];
    }
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docPath = [paths objectAtIndex:0];
//    NSString *myFile = [docPath stringByAppendingPathComponent:@"SpeedInfo.data"];
//
//    [mSpeedSedList writeToFile:myFile atomically:YES];
    
}

- (IBAction)didShowTraffic:(id)sender 
{
    RTTTrafficListViewController *trafficVC = [[RTTTrafficListViewController alloc] init];
    [trafficVC setRuntimeDataset:runningDataset];
    if (sender == nil)
    {
        [trafficVC setIsShowAllTraffic:YES];
    }
    [self.navigationController pushViewController:trafficVC animated:YES];
    
}


- (void)didBookmarkPathSelected:(RttGHistoryPathInfo*) pathInfo;       //处理选中路径书签中的某条路径
{
    if (pathInfo) 
    {
        [mMapView removeAnnotation:pStartPointAnnotation];
        [mMapView removeAnnotation:pEndPointAnnotation];
        //pCurrentlyAnnotation = nil;
        
        
        CLLocationCoordinate2D point1 = pathInfo.startPointInfo.geoPt;
        [self addAnnotation2Map:point1 withType:MAPPOINTTYPE_START];
        CLLocationCoordinate2D point2 = pathInfo.endPointInfo.geoPt;
        [self addAnnotation2Map:point2 withType:MAPPOINTTYPE_END];
        
        pStartPointAnnotation.addrInfo = pathInfo.startPointInfo;
        pEndPointAnnotation.addrInfo = pathInfo.endPointInfo;
        
        NSString *StrProv = pathInfo.startPointInfo.addressComponent.province;
        NSString *StrCity = pathInfo.startPointInfo.addressComponent.city;
        NSString *StrDist = pathInfo.startPointInfo.addressComponent.district;
        NSString *StrRoad = pathInfo.startPointInfo.addressComponent.streetName;
        if (StrRoad == nil) {
            StrRoad = @"未知道路";
        }
        NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"省份:%@\n城市:%@\n地区%@\n街道:%@", StrProv, StrCity,StrDist,StrRoad];
        
        pStartPointAnnotation.AddrString = StrFormatedInfo;
        NSString *StrProv2 = pathInfo.endPointInfo.addressComponent.province;
        NSString *StrCity2 = pathInfo.endPointInfo.addressComponent.city;
        NSString *StrDist2 = pathInfo.endPointInfo.addressComponent.district;
        NSString *StrRoad2 = pathInfo.endPointInfo.addressComponent.streetName;
        if (StrRoad2 == nil) {
            StrRoad2 = @"未知道路";
        }
        NSString *StrFormatedInfo2 = [[NSString alloc] initWithFormat:@"省份:%@\n城市:%@\n地区%@\n街道:%@", StrProv2, StrCity2,StrDist2,StrRoad2];
        pEndPointAnnotation.AddrString = StrFormatedInfo2;
        
        bool ret = [self RoutePlanning:point1 end:point2];
        if (!ret)
        {
            NSLog(@"History Route Planing Fail!");
        }
        else {
            [self showModeIndicator:@"路况获取中" seconds:10];
            [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
        }
        
        runningDataset.startPointInfo = pathInfo.startPointInfo;
        runningDataset.endPointInfo = pathInfo.endPointInfo;
    }

}

- (void) didHomeAddrReset:(id)sender
{
    [self toHomeSettingView];
}

- (void) didToolbarHomeSettingBTN:(id)sender
{
    
    if (runningDataset.homeAddrInfo)
    {
        [self toHomeAddrReview];
    }
    else 
    {
        [self toHomeSettingView];
    }
}

- (void) toHomeAddrReview
{
    RTTHomeAddrViewController *homeAddrPreviewVC = [[RTTHomeAddrViewController alloc] init];
    //homeAddrPreviewVC.mHomeAddrLBL.text = mHomeAddrInfo.address;
    NSString *addrStr;
    if (runningDataset.homeAddrInfo.name != nil)
    {
        addrStr = [[NSString alloc] initWithFormat:@"%@\n%@", runningDataset.homeAddrInfo.name, runningDataset.homeAddrInfo.address];
    }
    else {
        addrStr =  runningDataset.homeAddrInfo.address;
    }
    
    homeAddrPreviewVC.addrTxt = addrStr;
    homeAddrPreviewVC.addrLocation = runningDataset.homeAddrInfo.pt;
    
    [homeAddrPreviewVC setDelegate:self];  
    
    [mSwipeBar toggle:NO];
    [self.navigationController pushViewController:homeAddrPreviewVC animated:YES];
    
}
- (void) toHomeSettingView
{
    [mAddrSearchBar removeFromSuperview];
    
    UISearchBar *topSeachBar=[[UISearchBar alloc] init];
    [topSeachBar setFrame:CGRectMake(0, 0, 200, 20)];
    topSeachBar.backgroundColor=[UIColor clearColor];  
    for (UIView *subview in topSeachBar.subviews)   
    {    
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")])  
        {    
            [subview removeFromSuperview];    
            break;  
        }   
    } 
    
    //[topSeachBar showsCancelButton];
    topSeachBar.delegate = self;
    mAddrSearchBar = topSeachBar;
    self.navigationItem.titleView = topSeachBar;
    //[topSeachBar showsCancelButton];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
//    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]initWithTitle:@"取消键盘" 
//                                                                      style:UIBarButtonItemStylePlain target:self action:@selector(didSearchKeyboardDiss)];
    
    // UIBarButtonItemStylePlain
//    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]initWithTitle:@"退出设置" 
//                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(didQuiteHomeSetting)];
//    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]initWithImage:([UIImage imageNamed:@"keyboardv2.png"]) style:UIBarButtonItemStylePlain target:self action:@selector(didSearchKeyboardDiss)];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]initWithImage:([UIImage imageNamed:@"keyboardv2.png"]) style:UIBarButtonItemStylePlain target:self action:@selector(didSearchKeyboardDiss)];
    
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(didQuiteHomeSetting)];
    
    
    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
    [mSwipeBar toggle:NO];
    [mSuggestionListVC.view setFrame:CGRectMake(20, 5, 0, 0)];
    
    mIsHomeAddrSetting = YES;
    
    [self hideButtonsOnMap];
    
    [self DrawTrafficPolyline:YES];
    if (pCurrentlyPolyLine)
    {
        [mMapView removeOverlay:pCurrentlyPolyLine];
        pCurrentlyPolyLine = nil;
    }
    if (pStartPointAnnotation != nil){
        [mMapView removeAnnotation:pStartPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    if (pEndPointAnnotation != nil){
        [mMapView removeAnnotation:pEndPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    
    if (runningDataset)
    {
        runningDataset.currentlyRoute = ROUTEUNKNOW;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"您可以通过搜索条或者在地图上长时间触摸相应位置以设置您的家庭地址\r\n注意：目前只限于在深圳市范围使用"
                                                      delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
    [alertView show];
    
    //[mMapView setCenterCoordinate:(mMapView.userLocation.coordinate)];
    [self setCenterOfMapView:(mMapView.userLocation.coordinate)];

}


- (void) didToolbarAccountBTN:(id)sender
{
    
    RTTAccountViewController *accountVM = [[RTTAccountViewController alloc] init];
    //[accountVM setWebpageStr:@"http://www.baidu.com"];
    [self.navigationController pushViewController:accountVM animated:YES];
}

- (void)didToolbarGoHomeBTN:(id)sender
{
    if (runningDataset.homeAddrInfo == nil)
    {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"您的家庭地址未设置，请先进行设置"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        return;
    }
    [self routePlantoHome];

}

- (void)didToolbarGoOfficeBTN:(id)sender
{
    if (runningDataset.homeAddrInfo == nil)
    {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"您的家庭地址未设置，请先进行设置"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        return;
    }
    
    [self routePlantoOffice];
}


- (void)didToolbarBookmarkBTN:(id)sender;
{
    NSLog(@"Prepare to BookMark");
    [mSwipeBar toggle:NO];
    RTTRouteBookmarkViewController *routeBookmarkVC = [[RTTRouteBookmarkViewController alloc] init];
    [routeBookmarkVC setRuntimeDataset:runningDataset];  
    [routeBookmarkVC setDelegate:self];
    [self.navigationController pushViewController:routeBookmarkVC animated:YES];
}

- (void) didSearchKeyboardDiss
{
    [mAddrSearchBar resignFirstResponder];
}

- (void) didQuiteHomeSetting
{
    mIsHomeAddrSetting = NO;
    [mAddrSearchBar resignFirstResponder];
    [self.navigationItem setLeftBarButtonItem:nil];
    [self.navigationItem  setRightBarButtonItem:nil];
    [self.navigationItem  setTitleView:nil];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [mSwipeBar toggle:NO];
    //mSwipeBar 
    [mTopbar toggle];
    
    [self showButtonsOnMap];
    
    [self detectPath];
}


- (void)didRTTToolbarButtonWasPressed:(NSString*)buttonName
{
    [mSwipeBar toggle];

    if (buttonName == @"RouteBookmarkBTN")
    {
        NSLog(@"Prepare to BookMark");
        RTTRouteBookmarkViewController *routeBookmarkVC = [[RTTRouteBookmarkViewController alloc] init];
        [routeBookmarkVC setRuntimeDataset:runningDataset];  
        [routeBookmarkVC setDelegate:self];
        [self.navigationController pushViewController:routeBookmarkVC animated:YES];
    }
    
}


- (IBAction)didShowRoutePreview:(id)sender {
    RTTRoutePreviewViewController *routePreviewVC = [[RTTRoutePreviewViewController alloc] init];
    [routePreviewVC setRuntimeDataset:runningDataset];  
    [self.navigationController pushViewController:routePreviewVC animated:YES];
   
}

- (IBAction)didStart2Go:(id)sender 
{
    [self start2Go];
}

- (IBAction)didShowRoutePreviewAfterPlan:(id)sender 
{
    [self stopStart2GoTimer];
    [self didShowRoutePreview:sender];
}

- (IBAction)didBack2UserLocation:(id)sender 
{
    //[mMapView setCenterCoordinate:[mMapView userLocation].coordinate animated:0];
    [self setCenterOfMapView:([mMapView userLocation].coordinate)];

}


-(void) showSettingRoutPointView:(int) pointtype
{

    RTTMapPointSettingViewController *mapPointVC = [[RTTMapPointSettingViewController alloc] init];
    mapPointVC.delegate = self;
    mapPointVC.addrTxt = pCurrentlySelectedAnnotation.addrString;
    
    [self.navigationController pushViewController:mapPointVC animated:YES];    
}

- (void)viewDidDisappear:(BOOL)animated
{
    //NSLog(@"LSLSLS");
}

- (void)viewDidAppear:(BOOL)animated
{
    //NSLog(@"VVVVVV");
    //[self.navigationController setHidesBottomBarWhenPushed:YES];
    //[self.navigationController setNavigationBarHidden:YES animated:(NO)];
}

- (void)viewWillAppear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES animated:(NO)];

}

//
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {  
//    if ( viewController ==  self) {  
//        [navigationController setNavigationBarHidden:YES animated:animated];  
//    } else if ( [navigationController isNavigationBarHidden] ) {  
//        [navigationController setNavigationBarHidden:NO animated:animated];  
//    }  
//}  

//设置导航点视图通过消息回调这个delegate的方法，对所选的点进行处理
- (void) SetRoutePointType:(RttGRoutePointType*) pointtype
{
    switch (pointtype.pointtype) 
    {
        case RTTSETMAPPOIN_START:
        {
            if (pStartPointAnnotation != nil){
                [mMapView removeAnnotation:pStartPointAnnotation]; //地图上只保留一个起始点或者终点
            }
            
            runningDataset.startPointInfo = pCurrentlySelectedAnnotation.addrInfo;
            CLLocationCoordinate2D annLoc = pCurrentlySelectedAnnotation.coordinate;
            //通过删除和增加的方式，改变大头针的视图
            [mMapView removeAnnotation:pCurrentlySelectedAnnotation]; 
            pStartPointAnnotation = [self addAnnotation2Map:annLoc withType:MAPPOINTTYPE_START];
            pCurrentlySelectedAnnotation = nil;
        }
            break;
            
        case RTTSETMAPPOIN_END:
        {
            if (pEndPointAnnotation != nil){
                [mMapView removeAnnotation:pEndPointAnnotation]; //地图上只保留一个起始点或者终点
            }
            
            runningDataset.endPointInfo = pCurrentlySelectedAnnotation.addrInfo;
            CLLocationCoordinate2D annLoc = pCurrentlySelectedAnnotation.coordinate;
            //通过删除和增加的方式，改变大头针的视图
            [mMapView removeAnnotation:pCurrentlySelectedAnnotation]; 
            pEndPointAnnotation = [self addAnnotation2Map:annLoc withType:MAPPOINTTYPE_END];
            pCurrentlySelectedAnnotation = nil;
        }
            break;
            
        case RTTSETMAPPOIN_ROUTETO:
        {
            if (pStartPointAnnotation != nil){
                [mMapView removeAnnotation:pStartPointAnnotation]; //地图上只保留一个起始点或者终点
            }
            if (pEndPointAnnotation != nil){
                [mMapView removeAnnotation:pEndPointAnnotation]; //地图上只保留一个起始点或者终点
            }
            
            pStartPointAnnotation = [self addAnnotation2Map:mMapView.userLocation.coordinate withType:MAPPOINTTYPE_START];
                        
            CLLocationCoordinate2D endLoc = pCurrentlySelectedAnnotation.coordinate;
            //通过删除和增加的方式，改变大头针的视图
            [mMapView removeAnnotation:pCurrentlySelectedAnnotation]; //地图上只保留一个起始点或者终点
            pEndPointAnnotation = [self addAnnotation2Map:endLoc withType:MAPPOINTTYPE_END];
            pCurrentlySelectedAnnotation = nil;
        }
            break;
            
        case RTTSETMAPPOIN_DELETE:
        {
            [mMapView removeAnnotation:pCurrentlySelectedAnnotation];
        }
            break;
            
        default:
            break;
    }
    
    //因为只能有一个Undefine的点，所以设置了具体类型后，这个点就不是Undef了。
    pUndefAnnotation = nil;
    
    [self CheckPointsSettingCompleted:0];
    
}

#pragma mark -
#pragma mark History Route Data Source and delegate

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    // Return the number of sections.
//    return 2;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    // Return the number of rows in the section.
//    //int iTrfSegCnt = runtimeDataset.filteredRouteTrafficList.count;
//    //NSLog(@"SegCnt=%d", iTrfSegCnt);
//    if (section == 1)
//    {
//    return 8;
//    }
//    else {
//        return 2;
//    }
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"TrafficRoadSeg";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    
//    // Configure the cell...
//    if (!cell)
//    {
//        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];//
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
//    }
//    
//    [[cell textLabel] setText:@"Routes"];
//    
////    int iSegCnt = runtimeDataset.filteredRouteTrafficList.count;
////    
////    if (indexPath.row < iSegCnt)
////    {
////        RttGTrafficInfo *ptrfInfo = [runtimeDataset.filteredRouteTrafficList objectAtIndex:indexPath.row];
////        if (ptrfInfo)
////        {
////            NSString *cellString = ptrfInfo.roadname;
////            [[cell textLabel] setText:cellString];
////            [[cell detailTextLabel] setText:ptrfInfo.detail];
////        }
////    }
//    
//    return cell;
//}
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Navigation logic may go here. Create and push another view controller.
//    /*
//     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
//     // ...
//     // Pass the selected object to the new view controller.
//     [self.navigationController pushViewController:detailViewController animated:YES];
//     */
//}
//
//


#pragma mark -
#pragma mark Searchbar delegate



- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText 
{
    if ( [searchBar isEqual:mAddrSearchBar])
    {
        if ([searchText length] != 0) 
        {
            //BOOL callresult = [mBMKSearch suggestionSearch:searchText];
            BOOL callresult = [self getPoinameSuggestionfromMAPSVR:searchText];
            if (!callresult)
            {
                NSLog(@"######Call sugession Error");
            }
            
            mSuggestionListVC.searchText = searchText;
            [mSuggestionListVC updateData];
            [self setSearchListHidden:NO];
        }
        else
        {
            [self setSearchListHidden:YES];
        }
        
        //isSearchBarInuse = YES;
    }
    
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar 
{
    if ( [searchBar isEqual:mAddrSearchBar])
    {
        //isSearchBarInuse = YES;
    }
	return YES;
}

- (void) searchBarSearchButtonClicked:(UISearchBar*)activeSearchbar
{
    if ( [activeSearchbar isEqual:mAddrSearchBar])
    {
        NSString *strPOIName = activeSearchbar.text;
        //[mBMKSearch poiSearchInCity:@"深圳" withKey:strPOIName pageIndex:0];
        BOOL result = [self getPoiLocationInCityfromMAPSVR:@"深圳" poiName:strPOIName];
        if (!result)
        {
            
            NSLog(@"Failure when get poi location from map server");
            //百度已经有提示了，所以不用重复提示
//            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:errorMsg 
//                                                              delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
//            [alertView show];
            return;
        }
        else 
        {
            [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGGEO];
            [self showModeIndicator:@"获取地理坐标信息" seconds:10];
        }
        
        //uiAddrSearchBar.text = @"";
        [activeSearchbar resignFirstResponder];
        [self setSearchListHidden:YES];
        //isSearchBarInuse = NO;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if ( [searchBar isEqual:mAddrSearchBar])
    {
        [mAddrSearchBar resignFirstResponder];
    }
    //
}

- (void)didResultlistSelected:(NSString *)poiName
{
	if (poiName) 
    {
		mAddrSearchBar.text = poiName;
		[self searchBarSearchButtonClicked:mAddrSearchBar];
	}
    [self setSearchListHidden:YES];
    [mAddrSearchBar resignFirstResponder];
    
    //isSearchBarInuse = NO;

}


#pragma mark -
#pragma mark gesture recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{
    //[self OnClickSearchInputCancel:nil];
    return YES;
}



- (IBAction)didLongPress:(UILongPressGestureRecognizer *)sender 
{
#if defined (HUAWEIVER)
    if (!mIsHomeAddrSetting)
    {
        return;
    }
#endif
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        //坐标转换
        CGPoint touchPoint = [sender locationInView:mMapView];
        //得到经纬度，指触摸区域
        CLLocationCoordinate2D touchMapCoordinate = [mMapView convertPoint:touchPoint toCoordinateFromView:mMapView];
        
        if (!mIsHomeAddrSetting)
        {
            pWaitPOIResultAnnotation = [self addAnnotation2Map:touchMapCoordinate withType:MAPPOINTTYPE_UNDEF];
            if (pHomePointAnnotation != nil)
            {
                [mMapView removeAnnotation:pHomePointAnnotation];
            }
            pUndefAnnotation = pWaitPOIResultAnnotation;
        }
        else 
        {
            pWaitPOIResultAnnotation = [self addAnnotation2Map:touchMapCoordinate withType:MAPPOINTTYPE_HOME];

            if (pHomePointAnnotation != nil)
            {
                [mMapView removeAnnotation:pHomePointAnnotation];
            }
            pHomePointAnnotation = pWaitPOIResultAnnotation;
            
            __autoreleasing BMKPoiInfo *addInfo = [[BMKPoiInfo alloc] init];
            runningDataset.homeAddrInfo = addInfo;
            runningDataset.homeAddrInfo.pt = touchMapCoordinate;
        }
        
        BOOL result = [self getGeoInfofromMAPSVR:touchMapCoordinate];
        if (result)
        {
            //等待动作指示以及串行超时处理
            [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGPOI];
            [self showModeIndicator:@"获取坐标对应的地址信息" seconds:10];
        }
    }
}


#pragma mark -
#pragma mark Baidu Delegate Event Process
- (void)onGetSuggestionResult:(BMKSuggestionResult*)result errorCode:(int)error
{
    if (error != BMKErrorOk)
    {
        NSLog(@"######get sugession Error, errorcode:%d", error);
        //        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"无法获得输入建议" 
        //                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        //        [alertView show];
        return;
    }
    
    //poiSuggestionList = result.keyList;
    [mSuggestionListVC.resultList removeAllObjects];
    
    for (int i = 0; i < result.keyList.count; i++)
    {
        NSString *strPoiName = [result.keyList objectAtIndex:i];
        NSLog(@"POISuggestion: %@", strPoiName);
        
        [mSuggestionListVC.resultList addObject:strPoiName];
        [mSuggestionListVC updateData];
    }
    
}


//得到Poi的地理位置坐标信息
- (void)onGetPoiResult:(NSArray*)poiResultList searchType:(int)type errorCode:(int)error
{
    [self closeModeIndicator];
    if (mRunningActivity == RTTEN_ACTIVITYTYPE_GETTINGGEO)
    {
        [self stopRunningActivityTimer];
    }
    
	if (error == BMKErrorOk) 
    {
		BMKPoiResult* result = (BMKPoiResult*) [poiResultList objectAtIndex:0];
        
        if (result.poiInfoList.count > 0)
        {
            BMKPoiInfo* poi = [result.poiInfoList objectAtIndex:0];
            
            if (!mIsHomeAddrSetting)
            {
                [self addAnnotation2Map:poi.pt withType:MAPPOINTTYPE_UNDEF];
            }
            else 
            {
                if (pHomePointAnnotation != nil)
                {
                    [mMapView removeAnnotation:pHomePointAnnotation];
                }
                
                pHomePointAnnotation = [self addAnnotation2Map:poi.pt withType:MAPPOINTTYPE_HOME];
                runningDataset.homeAddrInfo = [result.poiInfoList objectAtIndex:0];
                
                [self HomeSettingSuccuess];
            }
            
            
            //[mMapView setCenterCoordinate:poi.pt];
            [self setCenterOfMapView:poi.pt];
        }
	}
    else 
    {
        NSLog(@"POI Search Fail, Error Code=%d", error);
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"无法获取检索结果" 
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];

    }
    

}


//获取地理位置的路名地址等POI信息
- (void)onGetAddrResult:(BMKAddrInfo*)result errorCode:(int)error
{
    [self closeModeIndicator];
    if (mRunningActivity == RTTEN_ACTIVITYTYPE_GETTINGPOI)
    {
        [self stopRunningActivityTimer];
    }
    
	if (error != BMKErrorOk) 
    {
    	NSLog(@"onGetDrivingRouteResult:error:%d", error);
        //self->uilRoadName.text = @"获取地理信息错误";
        return;
    }
    
    if (result.addressComponent.streetName != nil)
    {
        //self->uilRoadName.text = result.addressComponent.streetName;
    }
    else {
        //self->uilRoadName.text = @"未知路名";
    }
    
    [self setRoutPlaningViewAddress:result];
    
    if (mIsHomeAddrSetting)
    {
        NSString *StrProv = result.addressComponent.province;
        NSString *StrCity = result.addressComponent.city;
        NSString *StrDist = result.addressComponent.district;
        NSString *StrRoad = result.addressComponent.streetName;
        if (StrRoad == nil) {
            StrRoad = @"未知道路";
        }
        NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"省份:%@\n城市:%@\n地区%@\n街道:%@", StrProv, StrCity,StrDist,StrRoad];

        
        runningDataset.homeAddrInfo.address = StrFormatedInfo;
        [self HomeSettingSuccuess];
    }
}

- (void)onGetDrivingRouteResult:(BMKPlanResult*)result errorCode:(int)error
{
	NSLog(@"onGetDrivingRouteResult, activity=%d", mRunningActivity);
    
    [self closeModeIndicator];

    switch (mRunningActivity) {
        case RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE:
        {
            [self stopRunningActivityTimer];
            [self didGetedRouteH2O:result errorCode:error];
        }
            break;
            
        case RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE:
        {
            [self stopRunningActivityTimer];
            [self didGetedRouteO2H:result errorCode:error];
        }
            break;
            
        case RTTEN_ACTIVITYTYPE_GETTINGROUTE:
        {
            [self stopRunningActivityTimer];
            [self processGetedDrivingRoute:result errorCode:error];
        }
            break;
            
        default:
            break;
    }
    
}

- (void) didGetedRouteH2O:(BMKPlanResult*)result errorCode:(int)error
{
    NSLog(@"Processing H2O route result");

    if (error != BMKErrorOk) 
    {
        NSLog(@"######onGetDrivingRouteResult-Error, errorcode:%d", error);
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"无法获取上下班路径，请重新设定家庭地址" 
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        
        return;
    }
    
    //目前百度只提供一个方案
    BMKRoutePlan* plan = (BMKRoutePlan*)[result.plans objectAtIndex:0];
    
    //int iRoutePointCnt = 0; //路径上所有坐标点的个数
    int iRouteCnt = [plan.routes count]; //每个方案上路径的个数，目前只有一条路径，也就说数组的个数是1
    NSLog(@"routes counts:%d", iRouteCnt);
    if (iRouteCnt < 1)
    {
        return;
    }
    
    //目前只有一个路径，因此固定写成1；还没做多条路径的处理
    for (int i = 0; i < 1; i++)
    {
        [self formateHomeOfficeRouteInfoandSave:runningDataset.drivingRoute direction:0];
        [self sendRouteInfo2TSS:runningDataset.formatedH2ORouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE];
    }
    
    if (runningDataset.currentlyRoute == GOTOOFFICE)
    {
        [self processGetedDrivingRoute:result errorCode:error];
    }
    
    //已经获得上班路线，继续获取下班路线
    [self getO2HRoute];
}


- (void) didGetedRouteO2H:(BMKPlanResult*)result errorCode:(int)error
{
    NSLog(@"Processing O2H route result");

    if (error != BMKErrorOk) 
    {
        NSLog(@"######onGetDrivingRouteResult-Error, errorcode:%d", error);
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"无法获取上下班路径，请重新设定家庭地址" 
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        
        return;
    }
    
    //目前百度只提供一个方案
    BMKRoutePlan* plan = (BMKRoutePlan*)[result.plans objectAtIndex:0];
    
    //int iRoutePointCnt = 0; //路径上所有坐标点的个数
    int iRouteCnt = [plan.routes count]; //每个方案上路径的个数，目前只有一条路径，也就说数组的个数是1
    NSLog(@"routes counts:%d", iRouteCnt);
    if (iRouteCnt < 1)
    {
        return;
    }
    
    //目前只有一个路径，因此固定写成1；还没做多条路径的处理
    for (int i = 0; i < 1; i++)
    {
        [self formateHomeOfficeRouteInfoandSave:runningDataset.drivingRoute direction:1];
        [self sendRouteInfo2TSS:runningDataset.formatedO2HRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE];
    }
    if (runningDataset.currentlyRoute == GOHOME)
    {
        [self processGetedDrivingRoute:result errorCode:error];
    }
    
    [self detectPath];
}

- (void) processGetedDrivingRoute:(BMKPlanResult*)result errorCode:(int)error
{
    NSLog(@"Processing Driving route result");

    if (error != BMKErrorOk) 
    {
        NSLog(@"######onGetDrivingRouteResult-Error, errorcode:%d", error);
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"无法规划路径" 
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        
        return;
    }
    
    //目前百度只提供一个方案
    BMKRoutePlan* plan = (BMKRoutePlan*)[result.plans objectAtIndex:0];
    
    //int iRoutePointCnt = 0; //路径上所有坐标点的个数
    int iRouteCnt = [plan.routes count]; //每个方案上路径的个数，目前只有一条路径，也就说数组的个数是1
    NSLog(@"routes counts:%d", iRouteCnt);
    if (iRouteCnt < 1)
    {
        return;
    }
    
    for (int i = 0; i < iRouteCnt; i++)
    {
        [runningDataset setDrivingRoute:[plan.routes objectAtIndex:i]];
        [self AddDrivingRouteOverlay:runningDataset.drivingRoute];
        //[self GetDataandSendtoTSS:runningDataset.drivingRoute];
        [self formateRouteInfoandSave:runningDataset.drivingRoute];
        [self sendRouteInfo2TSS:runningDataset.formatedRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
        
#warning FOR TEST 增加提示点
        //[self addRouteGuidePoints];
    }
    
    [self changeMapVisibleRect:runningDataset.drivingRoute withIndex:-1];
    
    [runningDataset setIsPlaned:YES];
    
    //清理地图和路况数据
    [self DrawTrafficPolyline:YES];
    [trafficPolylineList removeAllObjects];
    [runningDataset.filteredRouteTrafficList removeAllObjects];
    [runningDataset.allRouteTrafficFromTSS removeAllObjects];

    
    [mAddrSearchBar setHidden:YES];
    [mSwipeBar toggle:NO];
#if !defined (HUAWEIVER)
    [self setStart2GoTimer:1];
    [self showInfoBoardforStart2Go];
#else
    [self start2Go];
#endif
    
#warning FOR TEST 增加测试用拥堵路段//
#if defined (DEBUG)
//    TSSCityTraffic* pTSSTraffic = [self ConstructTSSData];//:(BMKRoute*) routeinfo
//    [runningDataset setCityTraffic4Me:pTSSTraffic];
//    [self AddTrafficOverlay:pTSSTraffic];
#endif
}


-(void) mapView: (BMKMapView*) pmapview didUpdateUserLocation: (BMKUserLocation*)userLocation
{
    
    if (userLocation.isUpdating)
    {
        return;
    }    
    
    if (!((userLocation.location.coordinate.latitude >= 18.0 && userLocation.location.coordinate.latitude <= 54.0)
          && (userLocation.location.coordinate.longitude >= 73.0 && userLocation.location.coordinate.longitude <= 135.0)) )
    {
        if (!mIsOutofRange)
        {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"抱歉！\r\n本应用目前只支持中国深圳市范围内的路况播报，您当前所在的位置不在此范围中，对此造成的不便我们表示十分的歉意！"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
            [alertView show];
            
            mIsOutofRange = YES;
        }
        return;
    }
    else
    {
        mIsOutofRange = NO;
    }
        
    //判断和上次更新的距离，用于获取速度，以及减少路径相关计算
    CLLocationDistance distance = 0.0;
    distance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(userLocation.location.coordinate),
                                         BMKMapPointForCoordinate(runningDataset.lastUserLocation.coordinate));
    
    NSTimeInterval locupdateTimeInterval = [userLocation.location.timestamp timeIntervalSinceDate:(runningDataset.lastUserLocation.timestamp)];
    
    double avgSegSpeed = 0.0;
    
    //减少计算量，以及刷新地图的频率; 后续建议根据速度动态调整该值
    //目前尝试根据准确度来调整更新，避免在基站和WiFi等情况下乱漂移。
    CLLocationAccuracy accuracy = (userLocation.location.horizontalAccuracy + userLocation.location.verticalAccuracy)/2.0;
    if (distance < (accuracy*2.0)) //20.0)
    {
        if (locupdateTimeInterval >= 60.0) //如果时间间隔过长，意味着可能是重新打开应用程序，先记录当前位置待后续位置更新后处理
        {
            runningDataset.lastUserLocation = userLocation.location;
            return;
        }
        if ((locupdateTimeInterval <= 5.0))
        {
            return;
        }
    }
    

    
    avgSegSpeed = distance/locupdateTimeInterval*3600.0/1000.0;
    //avgSegSpeed = avgSegSpeed/4000.0*80.0;
    if (avgSegSpeed <= 80.0)
    {
//        [self DrawSpeedPolyline:avgSegSpeed startPoint:(runningDataset.lastUserLocation.coordinate) endPoint:userLocation.location.coordinate];
//        [self saveSpeed:avgSegSpeed startPoint:(runningDataset.lastUserLocation.coordinate) endPoint:userLocation.location.coordinate];
    }
    
    //更新上一次获得的当前坐标
    //#warning BMKUserLocation似乎不能正确执行copy方法；缺省赋值保存后内容和userLocation一致了，无法使用 
    runningDataset.lastUserLocation = userLocation.location;
    
    
    //如果路径没有规划，则不需要做路径计算
    if (!runningDataset.isPlaned)
    {
        //如果路径规划失败，这里进行重试
        if (runningDataset.isPlaningFailed)
        {
            [self RePlanRouting:userLocation.location.coordinate];
        }
        
        return;
    }
    
    
    //获取通过定位得到的当前用户位置
    CLLocationCoordinate2D temp_userLocation;
    temp_userLocation = userLocation.location.coordinate;
    if (runningDataset.isDriving)
    {
        //[pmapview setCenterCoordinate:temp_userLocation animated:0];
        [self setCenterOfMapView:temp_userLocation];
    }
        
    BMKMapPoint LocationPoint = BMKMapPointForCoordinate(temp_userLocation);
    int stepIndex, pointIndex;
    
    //NSLog(@"stepIndex.count= %d", StepIndexs.count);
    bool isOnPlan = false; //是否在路径上
    
    isOnPlan = [self getPositionFromRoute:runningDataset.drivingRoute withLocation:temp_userLocation 
                          andRetStepIndex:&stepIndex andretPointsIndex:&pointIndex];
    
    
    //如果在规划路径内，则显示路名，或者提示关键动作
    if (isOnPlan)
    {
        //首先先关闭所有的提示窗口
        [self hideGuideBoard];
        [self hideTrafficBoard];
        

#if !defined (HUAWEIVER)
        //切换视图
        if (runningDataset.currentRoadStep !=  stepIndex)
        {
            [self changeMapVisibleRect:runningDataset.drivingRoute withIndex:stepIndex+1];
            //[pmapview setCenterCoordinate:temp_userLocation animated:0];
            [self setCenterOfMapView:temp_userLocation];
        }
#endif
        //保存当前在Step的哪一步了
        runningDataset.currentRoadStep = stepIndex;
        runningDataset.nextRoadPointIndex = pointIndex;
        isOnPlan = true;
        
        
        //路名和提示
        if (stepIndex < ([runningDataset.drivingRoute.steps count]-1)) //如果是最后一段了，不提示？
        {
            BMKStep* step = [runningDataset.drivingRoute.steps objectAtIndex:stepIndex];
            BMKStep* pNextStep = [runningDataset.drivingRoute.steps objectAtIndex:stepIndex+1];
            
            CLLocationDistance nextPointDistance = BMKMetersBetweenMapPoints(LocationPoint,
                                                                             BMKMapPointForCoordinate(pNextStep.pt));    
            
            if (nextPointDistance < 300.0) //和下一点距离小于300米就提示关键信息
            {
                //self->uilRoadName.text = pNextStep.content; //下一个Step的提示信息
#if !defined (HUAWEIVER)
                [self setGuideBoardContent:pNextStep.content];
#endif
            }
            else //否则提示路名
            {
                //NSString *stepInfo = [[NSString alloc] initWithString:step.content];
                //抽取路名，目前是根据“进入.....——xxKM“的规则来抽取
                NSString *roadName = [self getRoadNameFromStepContent:step.content];
                
                if (roadName.length > 0)
                {
                    //self->uilRoadName.text = roadName;
                    [self hideGuideBoard];
                }
                else 
                {
                    //如果导航信息没有包含路名，这里只是简单地把导航信息显示出来；
                    //但是实际上Baidu地图有个缺点是起点没有标注路名，如果起点就是再大路上并且直行很长一段的话就没有路名；这种情况需要考虑通过其他手段获得路名；
                    //self->uilRoadName.text = @"未知道路";
                    NSString *roadName = [self getRoadNameFromStepContent:step.content];
                }
            }
        }
        
        //判断拥堵提示
        int trafficSegCnt = runningDataset.filteredRouteTrafficList.count;
        for (int trfindex = 0; trfindex < trafficSegCnt; trfindex++)
        {
            RttGTrafficInfo *trfinfo = [runningDataset.filteredRouteTrafficList objectAtIndex:trfindex];
            
            //如果当前点的Step位置和拥堵点相同，并且路径点中下一点小于拥堵点在路径点中相关位置（意味着还没到）
            //或者当前点的Step位置比拥堵点小
            if ((runningDataset.currentRoadStep == trfinfo.stepIndex && runningDataset.nextRoadPointIndex <= trfinfo.nextPointIndex)
                || (runningDataset.currentRoadStep < trfinfo.stepIndex))
            {
                RttGMapPoint *trafficpoint = [trfinfo.pointlist objectAtIndex:0];
                CLLocationDistance nextTrafficDistance = BMKMetersBetweenMapPoints(LocationPoint,
                                                                                   trafficpoint.mappoint);    
                
                if (nextTrafficDistance < 2000.0) //和下一个拥堵点距离小于2000米就提示关键信息
                {
                    NSString *trafficInfoText = [[NSString alloc] initWithFormat:@"%@",   trfinfo.roadname];                            

                    [self setTrafficBoardContent:trfinfo.roadname distance:nextTrafficDistance detail:trfinfo.detail];
                    [self showTrafficBoard];

                    NSLog(@"%@", trafficInfoText);
                    
                    //播放语音，每隔500M
                    if (![runningDataset.trffTTSPlayRec ifRecorded:nextTrafficDistance stepIndex:trfinfo.stepIndex pointIndex:trfinfo.nextPointIndex])
                    {
                        [runningDataset.trffTTSPlayRec record:nextTrafficDistance stepIndex:trfinfo.stepIndex pointIndex:trfinfo.nextPointIndex];
                        NSString *distanceStr;
                        if (nextTrafficDistance > 1000.0)
                        {
                            distanceStr = [[NSString alloc] initWithFormat:@"%.1f公里", nextTrafficDistance/1000.0];
                        }
                        else
                        {
                            distanceStr  = [[NSString alloc] initWithFormat:@"%d米", (int)nextTrafficDistance];
                        }
                        
                        //6.0对讯飞支持不好
                        float verValue = deviceVersion.floatValue;
                        if (verValue < 6.0)
                        {
                            NSString *strInfo = [[NSString alloc] initWithFormat:@"路况提示：前方约%@，%@，%@", distanceStr, trfinfo.roadname, trfinfo.detail];
                            [mSynTTS addGuideStr:strInfo];
                        }
                    }
                    
                    //if (nextTrafficDistance)
                }
                else 
                {
                    [self hideTrafficBoard];
                }
            }
            else 
            {
                [self hideTrafficBoard];
            }
        }
        
        //保存最后判断的在规划路径上的点坐标，用于判断偏离距离
        mLastOnPlanLocation = temp_userLocation;
    }
    else 
    {
        
        distance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(mLastOnPlanLocation),
                                             BMKMapPointForCoordinate(temp_userLocation));    
        
        if (distance > 100.0)
        {
            [self hideGuideBoard];
            [self hideTrafficBoard];
            //[self showModeIndicator:@"您已经偏离航线" seconds:2];
            
            if (distance > 200)
            {
#warning 调试屏蔽重规划
                [self RePlanRouting:temp_userLocation];
                
                //6.0对讯飞支持不好
                float verValue = deviceVersion.floatValue;
                if (verValue < 6.0)
                {
                    [mSynTTS addEmegencyStr:@"您已经偏移路径，正在重新获取路况"];
                }
//                //[self showModeIndicator:@"路径重算中..." seconds:0];
            }

        }
    }
    
}



-(void) mapView: (BMKMapView*)mapView didSelectAnnotationView:(BMKAnnotationView*) view
{
    pCurrentlySelectedAnnotation = view.annotation;
}

-(void) mapView: (BMKMapView*) mapView didDeselectAnnotationView: (BMKAnnotationView*) view
{
    pCurrentlySelectedAnnotation = nil;
    //NSLog(@"UnTouched Annotation****************");
}

-(void) mapView: (BMKMapView*) mapView annotationViewForBubble: (BMKAnnotationView*) view
{
    //NSLog(@"Bubble Selected");
    pCurrentlySelectedAnnotation = view.annotation;
}

#pragma mark -
#pragma mark - process View for Window

- (void) hideButtonsOnMap
{
    [back2locBTN setHidden:YES];
    [showTrafficViewBTN setHidden:YES];
}

- (void) showButtonsOnMap
{
    [back2locBTN setHidden:NO];
    [showTrafficViewBTN setHidden:NO];
}

- (void) HomeSettingSuccuess
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"家庭地址设置成功！" 
                                                      delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
    [alertView show];
    [self didQuiteHomeSetting];
    [self toHomeAddrReview];
    [mSwipeBar toggle:NO];
    
    [self saveHomeData];
    [mMapView removeAnnotation:pHomePointAnnotation];
    
    [self showButtonsOnMap];
    
    //获取上班路线；这个将触发-获取上班路线-获取下班路线-判断当前合适的路径等一系列动作
    [self getH2ORoute];
    //[self detectPath];
}


- (void) saveSpeed:(CLLocationSpeed)speed startPoint:(CLLocationCoordinate2D) startpoint endPoint:(CLLocationCoordinate2D) endpoint
{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docPath = [paths objectAtIndex:0];
//    NSString *myFile = [docPath stringByAppendingPathComponent:@"SpeedInfo.data"];
//    

    NSString *strSpeed = [[NSString alloc] initWithFormat:@"%.2f", speed];
    NSString *stpt = [[NSString alloc] initWithFormat:@"%f, %f", startpoint.longitude, startpoint.latitude];
    NSString *edpt = [[NSString alloc] initWithFormat:@"%f, %f", endpoint.longitude, endpoint.latitude];

    NSArray *writearray = [NSArray arrayWithObjects: strSpeed, stpt, edpt, nil];

    //NSDictionary *myDictionary = [NSDictionary dictionaryWithObjectsAndKeys:writearray,strIndex,nil];//注意用nil结束

    [mSpeedSedList addObject:writearray];
    
    //[myDictionary writeToFile:myFile atomically:NO];
}

- (void) saveHomeData
{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
//    NSString *docPath = [paths objectAtIndex:0];  
//    NSString *myFile = [docPath stringByAppendingPathComponent:@"HomeInfo.data"];  
//    
//    NSMutableData *data1 = [[NSMutableData alloc] init];  
//    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data1];  
//    [archiver encodeObject:(runningDataset.homeAddrInfo) forKey:@"data"];  
//    [archiver finishEncoding];
//    [data1 writeToFile:myFile atomically:YES];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    if (!documentsDirectory) {
//        NSLog(@"Documents directory not found!");
//    }
//    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"Savedatas.plist"];
//     NSArray *array = [NSArray arrayWithObjects:runningDataset.homeAddrInfo, runningDataset.officeAddrInfo, nil];
//    [[NSArray arrayWithObjects:array,nil] writeToFile:appFile atomically:NO];    
//    
//    NSLog(@"PATH: %@", appFile);
//    
//    //load
//    NSMutableArray *SaveDataArray;
//    if([[NSFileManager defaultManager] fileExistsAtPath:appFile])
//    {
//         SaveDataArray = [NSMutableArray arrayWithContentsOfFile:appFile];     
//    }
//    else
//    {
//        SaveDataArray = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Savedatas" ofType:@"plist"]];
//    }
//    NSArray *strArray = [SaveDataArray objectAtIndex:0];
//    
//    BMKPoiInfo *savePoi1 = [strArray objectAtIndex:0];
//    BMKPoiInfo *savePoi2 = [strArray objectAtIndex:1];
//    
////  
    NSString *strAddr = runningDataset.homeAddrInfo.address;
    NSString *HomeLat = [[NSString alloc] initWithFormat:@"%f",runningDataset.homeAddrInfo.pt.latitude];
    NSString *HomeLon = [[NSString alloc] initWithFormat:@"%f",runningDataset.homeAddrInfo.pt.longitude];

    NSArray *array = [NSArray arrayWithObjects:strAddr, HomeLat, HomeLon, nil];
    //Save
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    [saveDefaults setObject:array forKey:@"HomeOfficeSaveKey"];
    
    
//    NSArray *loadArray = [saveDefaults objectForKey:@"HomeOfficeSaveKey"];
//    NSString *loadHomeAddr = [loadArray objectAtIndex:0];
//    NSString *loadHomeLat = [loadArray objectAtIndex:1];
//    NSString *loadHomeLon = [loadArray objectAtIndex:2];
//
//    NSLog(@"str:%@, %@, %@",loadHomeAddr, loadHomeLat, loadHomeLon);
    
}

- (void) initButtomBar
{
    //初始化和显示底部可隐藏工具条
    RNSwipeBar *swipeBar = [[RNSwipeBar alloc] initWithMainView:[self view] withType:0];
    [swipeBar setPadding:22.0f];
    [swipeBar setDelegate:self];
    mSwipeBar = swipeBar;
    [[self view] addSubview:mSwipeBar];
    
    RTTToolbarView *toolbarView = [[[NSBundle mainBundle] loadNibNamed:@"RTTToolbarView" owner:self options:nil] lastObject];
    [toolbarView setDelegate:self];
    [swipeBar setBarView:toolbarView];
 
#if defined (HUAWEIVER)
    //[toolbarView.routeBookmarkBTN setHidden:YES];
#endif
}


- (void)setSearchListHidden:(BOOL)hidden 
{
    if (!hidden)
    {
        [mSuggestionListVC.view setHidden:NO];
    }
	NSInteger height = hidden ? 0 : 180;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];
	//[mSuggestionListVC.view setFrame:CGRectMake(mSuggestionListVC.view.frame.origin.x, mSuggestionListVC.view.frame.origin.y, 210, height)];
    [mSuggestionListVC.view setFrame:CGRectMake(mSuggestionListVC.view.frame.origin.x, mSuggestionListVC.view.frame.origin.y, 210, height)];
	[UIView commitAnimations];
    
    
    if (hidden)
    {
        [mSuggestionListVC clearData];
        [mSuggestionListVC updateData];
        [mSuggestionListVC.view setHidden:YES];
    }
}

- (void) initSuggestionListView
{
    //poiResultList = [[RttGDLTViewControler alloc] initWithStyle:UITableViewStylePlain];

    mSuggestionListVC = [[RTTSuggestionListViewController alloc] initWithStyle:UITableViewStylePlain];    
    mSuggestionListVC.delegate = self;
    [mSuggestionListVC.view setFrame:CGRectMake(20, 46, 0, 0)];

    //[self.view addSubview:mSuggestionListVC.view];
}

- (void) start2Go
{
    if (mStart2GoTimer)
    {
        [mStart2GoTimer invalidate];
    }
    
    if(runningDataset && runningDataset.isPlaned)
    {
        runningDataset.isDriving = YES;
    }
    [self stopStart2GoTimer];
    [self hideInfoBoardforStart2Go];
#if !defined (HUAWEIVER)
    [self showGuideBoard];
#endif
    RTTTopBarView *topbarView = [[[NSBundle mainBundle] loadNibNamed:@"RTTTopBarView" owner:self options:nil] lastObject];
    [topbarView setDelegate:self];
    [mTopbar setBarView:topbarView];
    [mTopbar show:NO];
}

- (void) initTopBar
{    
    mTopbar = [[RNSwipeBar alloc] initWithMainView:[self view] withType:1];
    [mTopbar setPadding:10.0f];
    [mTopbar setDelegate:self];
    [[self view] addSubview:mTopbar];
    //    
    RTTTopBarView *topbarView = [[[NSBundle mainBundle] loadNibNamed:@"RTTTopBarView" owner:self options:nil] lastObject];
    [topbarView setDelegate:self];
    //[mTopbar setBarView:topbarView];
    //[mTopbar setBarView:mAddrSearchBar];
#if defined (HUAWEIVER)
    [mTopbar setPadding:0.0f];
    [mTopbar show:NO];
    [mTopbar setHidden:YES];
#else
    [mTopbar show:YES];
#endif
    
}


-(void) initGuideBoard
{
    
    mGuideBoard = [[[NSBundle mainBundle] loadNibNamed:@"GuideBoard" owner:self options:nil] lastObject];
    [mGuideBoard setCenter:CGPointMake(160.0, 80.0)];
    [[self view] addSubview:mGuideBoard];
    
    //设置圆角
    [mGuideBoard.layer setCornerRadius:12.0f];
    
    //设置阴影
    mGuideBoard.layer.shadowColor = [[UIColor blackColor] CGColor];
    mGuideBoard.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    mGuideBoard.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    mGuideBoard.layer.shadowRadius = 10.0f; // 阴影发散的程度
}

- (void) showGuideBoard
{
    [mGuideBoard setHidden:NO];
}

- (void) hideGuideBoard
{
    [mGuideBoard setHidden:YES];
}

- (void) setGuideBoardContent:(NSString *)content
{
    RTTStepInfo *stepInfo = [self getStepInfoFromStepContent:content];
    mGuideBoard.rangeLABEL.text = stepInfo.distanceStr;
    mGuideBoard.descLABEL.text = stepInfo.discriptionStr;

    [self showGuideBoard];
}

- (void) setGuideBoardAberranted
{
    mGuideBoard.rangeLABEL.text = @"您已经偏离航线";
    mGuideBoard.descLABEL.text = @"即将重新计算路线";
    [self showGuideBoard];
}

- (void) setGuideBoardReplaning
{
    mGuideBoard.rangeLABEL.text = @"您已经偏离航线";
    mGuideBoard.descLABEL.text = @"正在重新获取路线";
    
    [self showGuideBoard];
}

- (void) setGuideBoardDesc:(NSString *)description
{
    mGuideBoard.descLABEL.text = description;
}

- (void) setGuideBoardDistance:(int) distance
{
    if (distance > 1000)
    {
        mGuideBoard.rangeLABEL.text = [[NSString alloc] initWithFormat:@"%.1f 公里", distance/1000.0];
    }
    else 
    {
        mGuideBoard.rangeLABEL.text = [[NSString alloc] initWithFormat:@"%d 米", distance];
    }
}

- (void) setGuideBoardImage:(NSString *)description
{
    
}


- (void) showInfoBoardforStart2Go
{
    [mInfoboadView setHidden:NO];
}

- (void) hideInfoBoardforStart2Go
{
    [mInfoboadView setHidden:YES];
}

- (void) initInfoBoard
{
    //设置圆角
    [mInfoboadView.layer setCornerRadius:12.0f];
    
    //设置阴影
    mInfoboadView.layer.shadowColor = [[UIColor blackColor] CGColor];
    mInfoboadView.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    mInfoboadView.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    mInfoboadView.layer.shadowRadius = 10.0f; // 阴影发散的程度
    
    //    CAGradientLayer *gradient = [CAGradientLayer layer];
    //    gradient.frame = mInfoboadView.bounds;
    //
    //    UIColor *color1 = [[UIColor alloc] initWithRed:0.1 green:0.8 blue:0.1 alpha:1];
    //    UIColor *color2 = [[UIColor alloc] initWithRed:0.1 green:0.5 blue:0.1 alpha:1];
    //
    //    gradient.colors = [NSArray arrayWithObjects:(id)
    //                       [color1 CGColor], (id)[color2 CGColor], nil]; // 由上到下的漸層顏色
    //    [mInfoboadView.layer insertSublayer:gradient atIndex:0];
    
}



-(void) initTrafficBoard
{
    
    mTrafficInfoBoard = [[[NSBundle mainBundle] loadNibNamed:@"RTTTrafficBoard" owner:self options:nil] lastObject];
    [mTrafficInfoBoard setCenter:CGPointMake(160.0, 80.0)];
    [[self view] addSubview:mTrafficInfoBoard];
    
    //设置圆角
    [mTrafficInfoBoard.layer setCornerRadius:12.0f];
    
    //设置阴影
    mTrafficInfoBoard.layer.shadowColor = [[UIColor blackColor] CGColor];
    mTrafficInfoBoard.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    mTrafficInfoBoard.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    mTrafficInfoBoard.layer.shadowRadius = 10.0f; // 阴影发散的程度
}

- (void) showTrafficBoard
{
    [mTrafficInfoBoard setHidden:NO];
}

- (void) hideTrafficBoard
{
    [mTrafficInfoBoard setHidden:YES];
}

- (void) setTrafficBoardContent:(NSString*) roadname distance:(NSInteger) distance detail:(NSString*) detail
{
    if (distance > 1000)
    {
        mTrafficInfoBoard.mainInfoLBL.text = [[NSString alloc] initWithFormat:@"%.1fKM %@", distance/1000.0, roadname];
    }
    else 
    {
        mTrafficInfoBoard.mainInfoLBL.text  = [[NSString alloc] initWithFormat:@"%dM %@", distance, roadname];
    }
    
    mTrafficInfoBoard.detailInfoLBL.text = detail;
}

- (void) setTrafficBoardMainInfo:(NSString *)content
{
    mTrafficInfoBoard.mainInfoLBL.text = content;
    //[self showTrafficBoard];
}

- (void) setTrafficBoardDetailInfo:(NSString *)detail
{
    mTrafficInfoBoard.detailInfoLBL.text = detail;
    //[self showTrafficBoard];
}


- (void) setTrafficBoardDistance:(int) distance
{
    if (distance > 1000)
    {
        mTrafficInfoBoard.mainInfoLBL.text = [[NSString alloc] initWithFormat:@"%.1f 公里", distance/1000.0];
    }
    else 
    {
        mTrafficInfoBoard.mainInfoLBL.text  = [[NSString alloc] initWithFormat:@"%d 米", distance];
    }
}


-(void) initModeIndicator
{
    
    mModeIndicatorView = [[[NSBundle mainBundle] loadNibNamed:@"RTTModeActivityIndicator" owner:self options:nil] lastObject];
    [[self view] addSubview:mModeIndicatorView];
//    [mModeIndicatorView setCenter:CGPointMake(160.0, 80.0)];
//    
//    //设置圆角
//    [mModeIndicatorView.layer setCornerRadius:12.0f];
//    
//    //设置阴影
//    mModeIndicatorView.layer.shadowColor = [[UIColor blackColor] CGColor];
//    mModeIndicatorView.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
//    mModeIndicatorView.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
//    mModeIndicatorView.layer.shadowRadius = 10.0f; // 阴影发散的程度
    
    [mModeIndicatorView.backgroundBoardVW setCenter:CGPointMake(160.0, 80.0)];
    
    //设置圆角
    [mModeIndicatorView.backgroundBoardVW.layer setCornerRadius:12.0f];
    
    //设置阴影
    mModeIndicatorView.backgroundBoardVW.layer.shadowColor = [[UIColor blackColor] CGColor];
    mModeIndicatorView.backgroundBoardVW.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    mModeIndicatorView.backgroundBoardVW.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    mModeIndicatorView.backgroundBoardVW.layer.shadowRadius = 10.0f; // 阴影发散的程度
    
    //mActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame : CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)] ;
    mActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [mModeIndicatorView addSubview: mActivityIndicatorView];

//    CGFloat cX = mModeIndicatorView.frame.size.width/2.0;
//    CGFloat cY = mModeIndicatorView.frame.size.height/2.0+12.0;
//    CGFloat cX = (mModeIndicatorView.backgroundBoardVW).frame.size.width/2.0;
//    CGFloat cY = (mModeIndicatorView.backgroundBoardVW).frame.size.height/2.0+12.0;
    [mActivityIndicatorView setCenter: CGPointMake(160, 92)] ;
    //[mActivityIndicatorView setActivityIndicatorViewStyle: UIActivityIndicatorViewStyleWhite] ; 
    [mActivityIndicatorView setHidesWhenStopped:YES];
    
    
}


- (void) showModeIndicator:(NSString *)actinfo seconds:(NSInteger) seconds
{
    mModeIndicatorView.activityDescLBL.text = actinfo;
    [mModeIndicatorView setHidden:NO];
    [self.view bringSubviewToFront:mModeIndicatorView];
    [mActivityIndicatorView startAnimating];
    
    if (seconds > 0)
    {
        [self setModeIndicatorTimer:seconds];
    }
}

- (void) closeModeIndicator
{
    if (mModeIndicatorTimer)
    {
        [mModeIndicatorTimer invalidate];
        mModeIndicatorTimer = nil;
    }
    [mActivityIndicatorView stopAnimating];
    [mModeIndicatorView setHidden:YES];
}




#pragma mark -
#pragma mark Process View for Map

- (void) setCenterOfMapView:(CLLocationCoordinate2D)coordinate
{
    //Lon: 73-135, Lat:18-54
    if ((coordinate.latitude >= 18.0 && coordinate.latitude <= 54.0)
        && (coordinate.longitude >= 73.0 && coordinate.longitude <= 135.0) )
    {
        [mMapView setCenterCoordinate:coordinate animated:0];
    }
}

//修改协议后废弃
//- (void) AddTrafficOverlay:(LYCityTraffic*) trafficinfo
//{
//    [runningDataset.filteredRouteTrafficList removeAllObjects];
//    
//    //int iSegRdCnt = trafficinfo.roadtrafficList.count;
//    int iSegRdCnt = trafficinfo.roadTrafficsList.count;
//
//    
//    LYRoadTraffic *pRdTrc;
//    
//    for (int i=0; i<iSegRdCnt; i++)
//    {
//        pRdTrc = [trafficinfo.roadTrafficsList objectAtIndex:i];
//        int iSegCnt = pRdTrc.segmentTrafficsList.count;
//        
//        int iRoadCnt = runningDataset.formatedRouteInfo.roadlist.count;
//        for (int j = 0; j < iRoadCnt; j++)
//        {
//            RttGRoadInfo *road = [runningDataset.formatedRouteInfo.roadlist objectAtIndex:j];
//            
//            //int iPoincnt = [road.pointlist count];
//            //NSLog(@"===RoadName:%@, SegName:%@", road.roadname, pRdTrc.road);
//            
//            //判断路名是否相同，这里用相同路名的拥堵路段和路径中的相同路名的路段进行比较得到拟合线段
//            if ([road.roadname isEqualToString:pRdTrc.road])
//            {
//                //NSLog(road.roadname);
//                for (int k=0; k<iSegCnt; k++)
//                {
//                    LYSegmentTraffic *pSegTrf = [pRdTrc.segmentTrafficsList objectAtIndex:k];
//                    BOOL ret = [self createTrafficPolylineInfo:pSegTrf withRttgRoadInfo:road];
//                    if (ret)
//                    {
//                        [self DrawTrafficPolyline:NO];
//                    }
//                }
//            }
//        }
//    }
//    
//    [self DrawTrafficPolyline:NO];
//}


- (void) formatAndSaveTrafficData:(LYCityTraffic*) trafficinfo
{
    [runningDataset.filteredRouteTrafficList removeAllObjects];
    
    int iRdCnt = trafficinfo.roadTrafficsList.count;
    
    
    LYRoadTraffic *pRdTrc;
    
    [self clearOutofDateTrafficData];//先清理超时的路况信息
    
    for (LYRoadTraffic *pRdTrc in trafficinfo.roadTrafficsList)
    {
        for (LYSegmentTraffic *pSegTrf in pRdTrc.segmentTrafficsList)
        {
            
            //把所有的拥堵路段都加入队列中
//            RTTFormatedTrafficFromTSS *trfSegInfo = [[RTTFormatedTrafficFromTSS alloc] init];
//            trfSegInfo.roadName = pRdTrc.road;
//            trfSegInfo.details = pSegTrf.details;
//            trfSegInfo.speedKMPH = pSegTrf.speed;
//            trfSegInfo.timestamp = pSegTrf.timestamp;
//            
//            CLLocationCoordinate2D tmpStCoord;
//            tmpStCoord.latitude = pSegTrf.segment.start.lat;
//            tmpStCoord.longitude = pSegTrf.segment.start.lng;
//            [trfSegInfo setStartCoord:tmpStCoord];
//            
//            CLLocationCoordinate2D tmpEdCoord;
//            tmpEdCoord.latitude = pSegTrf.segment.end.lat;
//            tmpEdCoord.longitude = pSegTrf.segment.end.lng;
//            [trfSegInfo setEndCoord:tmpEdCoord];
//            
//            [runningDataset.allRouteTrafficFromTSS addObject:trfSegInfo];
            
            [self addTSSTraffic2RunningDataset:pRdTrc.road segment:pSegTrf];
        }
    }
    
    for (RTTFormatedTrafficFromTSS *tssTrf in runningDataset.allRouteTrafficFromTSS)
    {
        for (RttGRoadInfo *road in runningDataset.formatedRouteInfo.roadlist)
        {
            if ([road.roadname isEqualToString:tssTrf.roadName])
            {
                //LYSegmentTraffic *pSegTrf = [pRdTrc.segmentTrafficsList objectAtIndex:k];
                BOOL ret = [self createTrafficInfo2Dataset:tssTrf withRttgRoadInfo:road];
                if (ret)
                {
                    //[self DrawTrafficPolyline:NO];
                }
            }

        }
    }

    [self DrawTrafficPolyline:NO];
}


//增加拥堵路径到runningDataset.allRouteTrafficFromTSS，不做过滤，只做覆盖
- (void) addTSSTraffic2RunningDataset:(NSString *)roadName segment:(LYSegmentTraffic*) trfSegment
{
    
    //先检查重复的
    BOOL hasExistRecord = NO;
    for (RTTFormatedTrafficFromTSS *trfSegInfo in runningDataset.allRouteTrafficFromTSS)
    {
        if ([trfSegInfo.details isEqualToString:trfSegment.details])
        {
            trfSegInfo.timestamp = trfSegment.timestamp; //更新时间戳即可
            hasExistRecord = YES;
            break;
        }
    }
    
    if (!hasExistRecord)
    {
        
        RTTFormatedTrafficFromTSS *trfSegInfo = [[RTTFormatedTrafficFromTSS alloc] init];
        trfSegInfo.roadName = roadName;
        trfSegInfo.details = trfSegment.details;
        trfSegInfo.speedKMPH = trfSegment.speed;
        trfSegInfo.timestamp = trfSegment.timestamp;
        
        CLLocationCoordinate2D tmpStCoord;
        tmpStCoord.latitude = trfSegment.segment.start.lat;
        tmpStCoord.longitude = trfSegment.segment.start.lng;
        [trfSegInfo setStartCoord:tmpStCoord];
        
        CLLocationCoordinate2D tmpEdCoord;
        tmpEdCoord.latitude = trfSegment.segment.end.lat;
        tmpEdCoord.longitude = trfSegment.segment.end.lng;
        [trfSegInfo setEndCoord:tmpEdCoord];
        
        [runningDataset.allRouteTrafficFromTSS addObject:trfSegInfo];
    }
}

- (void) clearOutofDateTrafficData
{
    int segCnt = runningDataset.allRouteTrafficFromTSS.count;
    for (int i=(segCnt-1); i >= 0; i--)// * trfseg in runningDataset.allRouteTrafficFromTSS)
    {
        RTTFormatedTrafficFromTSS *trfseg = [runningDataset.allRouteTrafficFromTSS objectAtIndex:i];
        
        NSDate *segDate = [NSDate dateWithTimeIntervalSince1970:trfseg.timestamp];
        NSTimeInterval secondsBetweenNow =  [segDate timeIntervalSinceNow];
        if (secondsBetweenNow <= -900.0) //间隔超过15分钟就丢弃
        {
            [runningDataset.allRouteTrafficFromTSS removeObjectAtIndex:i];
        }
    }
}

- (void) DrawTrafficPolyline:(BOOL) isRemove
{
    int polyCnt = trafficPolylineList.count;
    for (int i=0; i<polyCnt; i++)
    {
        [mMapView removeOverlay:[trafficPolylineList objectAtIndex:i]];
    }
    
    [trafficPolylineList removeAllObjects];

    if (isRemove)
    {
        return;
    }
    
    int trafficSegCnt = runningDataset.filteredRouteTrafficList.count;
    
    for (int i=0; i<trafficSegCnt; i++)
    {
        
        RttGTrafficInfo *trfInfo = [runningDataset.filteredRouteTrafficList objectAtIndex:i];
        int pointCnt = trfInfo.pointlist.count;
        
        CLLocationCoordinate2D *pPoints = new CLLocationCoordinate2D[pointCnt];
        
        for (int j = 0; j < pointCnt; j++)
        {
            BMKMapPoint linePoint = [[trfInfo.pointlist objectAtIndex:j] mappoint];
            pPoints[j] = BMKCoordinateForMapPoint(linePoint);
        }
        
        BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:pPoints count:pointCnt];
        polyLine.title = @"traffic";
        
        //NSLog(@"Draw Traffic polyline.........");
        [mMapView insertOverlay:polyLine atIndex:0];//放在导航线路下面效果会更好
        [trafficPolylineList addObject:polyLine];
        
        delete []pPoints;
    }
}


- (void) AddDrivingRouteOverlay:(BMKRoute*) route
{
    int iRoutePointCnt = 0; //路径上所有坐标点的个数
    for (int j = 0; j < route.pointsCount; j++) 
    {
        int len = [route getPointsNum:j];
        iRoutePointCnt += len;
    }
    NSLog(@"Points Cnt in Steps: %d", iRoutePointCnt);
    
    
    //DrivingRoute = route;//[plan.routes objectAtIndex:i];
    BMKMapPoint* points = new BMKMapPoint[iRoutePointCnt];
    
    
    int index = 0; //YSH_DEBUGING...............................................
    for (int j = 0; j < route.pointsCount; j++) 
    {
        int len = [route getPointsNum:j];
        BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
        memcpy(points + index, pointArray, len * sizeof(BMKMapPoint));
        index += len;
    }
    
    if (pCurrentlyPolyLine)
    {
        [mMapView removeOverlay:pCurrentlyPolyLine];
        pCurrentlyPolyLine = nil;
    }
    //在地图上画出规划的路线
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:iRoutePointCnt];
    polyLine.title = @"Route";
    [mMapView addOverlay:polyLine];
    
    pCurrentlyPolyLine = polyLine; 
    //[mMapView setCenterCoordinate:(BMKCoordinateForMapPoint(points[0]))];
    [self setCenterOfMapView:(BMKCoordinateForMapPoint(points[0]))];
    
    delete []points;
}


- (void) DrawSpeedPolyline: (double) speed startPoint:(CLLocationCoordinate2D)startPoint endPoint:(CLLocationCoordinate2D)endPoint
{
    int pointCnt = 2;
    
    CLLocationCoordinate2D pPoints[2];// = new CLLocationCoordinate2D[pointCnt];
    
    pPoints[0] = startPoint;
    pPoints[1] = endPoint;
    
    
    BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:pPoints count:pointCnt];
    polyLine.title = [[NSString alloc] initWithFormat:@"Seg4Speed--%f", speed];
    [mMapView addOverlay:polyLine];
    
    //        [mMapView insertOverlay:polyLine atIndex:0];//放在导航线路下面效果会更好
    //        [trafficPolylineList addObject:polyLine];
    
    //delete []pPoints;
}


//For Test
- (void) addRouteGuidePoints
{
    int iStepCnt = runningDataset.drivingRoute.steps.count;
    
    for (int i = 0; i < iStepCnt; i++) 
    {
        BMKStep* step_a = [runningDataset.drivingRoute.steps objectAtIndex:i];
        RTTMapPointAnnotation *stepAnnot = [[RTTMapPointAnnotation alloc] init];
        stepAnnot.coordinate = step_a.pt;
        stepAnnot.title = step_a.content;
        [mMapView addAnnotation:stepAnnot];
    }
    
}


- (BMKAnnotationView *)mapView:(BMKMapView *)bmkmapview viewForAnnotation:(id <BMKAnnotation>)annotation
{    
    if ([annotation isKindOfClass:[BMKUserLocation class]])
    {
        return nil;  
    }
    
    // 处理自定义的导航起始点Annotation  
    if ([annotation isKindOfClass:[RTTMapPointAnnotation class]]) 
    {   
        RTTMapPointAnnotation *pointAnnotation = (RTTMapPointAnnotation*) annotation;
        static NSString* RoutePlanAnnotationIdentifier = @"RoutePlanAnnotationIdentifier";  
        __autoreleasing BMKPinAnnotationView* pinView = (BMKPinAnnotationView *) [mMapView dequeueReusableAnnotationViewWithIdentifier:RoutePlanAnnotationIdentifier];  
        if (!pinView)  
        {
            // if an existing pin view was not available, create one  
            BMKPinAnnotationView* customPinView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:RoutePlanAnnotationIdentifier];
            
//            customPinView.animatesDrop = NO;  //如果需要从天而降的动画效果，设置为YES即可。
//            customPinView.opaque = YES;
//            
//            switch (pointAnnotation.pointType) {
//                case MAPPOINTTYPE_START:
//                {customPinView.pinColor = BMKPinAnnotationColorGreen;}
//                    break;
//                    
//                case MAPPOINTTYPE_END:
//                {customPinView.pinColor = BMKPinAnnotationColorPurple;}
//                    break;
//                    
//                case MAPPOINTTYPE_HOME:
//                {customPinView.pinColor = BMKPinAnnotationColorRed;}
//                    break;
//                    
//                default:
//                {
//                    customPinView.pinColor = BMKPinAnnotationColorRed;
//                    customPinView.canShowCallout = YES;  //运行点击弹出标签 
//                    if ((pointAnnotation.pointType != MAPPOINTTYPE_START) && (pointAnnotation.pointType != MAPPOINTTYPE_END))
//                    {
//                        UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];  
//                        [rightButton addTarget:self  
//                                        action:@selector(showSettingRoutPointView:)  //点击右边的按钮之后，显示设置导航点的页面
//                              forControlEvents:UIControlEventTouchUpInside];
//                        customPinView.rightCalloutAccessoryView = rightButton; 
//                    }
//                }
//                    break;
//            }

            
//            customPinView.canShowCallout = YES;  //运行点击弹出标签 
//            if ((pointAnnotation.pointType != MAPPOINTTYPE_START) && (pointAnnotation.pointType != MAPPOINTTYPE_END))
//            {
//                UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];  
//                [rightButton addTarget:self  
//                                action:@selector(showSettingRoutPointView:)  //点击右边的按钮之后，显示设置导航点的页面
//                      forControlEvents:UIControlEventTouchUpInside];
//                customPinView.rightCalloutAccessoryView = rightButton; 
//            }
            //RTTMapPointAnnotation *rpAnnotation = (RTTMapPointAnnotation *)annotation;
            
            //rpAnnotation.pointType=MAPPOINTTYPE_UNDEF;
            
            pinView = customPinView;
        }  
        else  
        {  
            pinView.annotation = annotation;  
        }  
        
        pinView.animatesDrop = NO;  //如果需要从天而降的动画效果，设置为YES即可。
        pinView.opaque = YES;
        
        switch (pointAnnotation.pointType) {
            case MAPPOINTTYPE_START:
            {pinView.pinColor = BMKPinAnnotationColorGreen;}
                break;
                
            case MAPPOINTTYPE_END:
            {pinView.pinColor = BMKPinAnnotationColorPurple;}
                break;
                
            case MAPPOINTTYPE_HOME:
            {pinView.pinColor = BMKPinAnnotationColorRed;}
                break;
                
            default:
            {
                pinView.pinColor = BMKPinAnnotationColorRed;
                pinView.canShowCallout = YES;  //运行点击弹出标签 
                if ((pointAnnotation.pointType != MAPPOINTTYPE_START) && (pointAnnotation.pointType != MAPPOINTTYPE_END))
                {
                    UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];  
                    [rightButton addTarget:self  
                                    action:@selector(showSettingRoutPointView:)  //点击右边的按钮之后，显示设置导航点的页面
                          forControlEvents:UIControlEventTouchUpInside];
                    pinView.rightCalloutAccessoryView = rightButton; 
                }
            }
                break;
        }

        //pCurrentlyAnnotation = annotation;
        return pinView;  
    }
    else 
    {
        static NSString* RoutePlanAnnotationIdentifier = @"CarAnnotationIdentifier";  
        BMKPinAnnotationView* pinView = (BMKPinAnnotationView *) [mMapView dequeueReusableAnnotationViewWithIdentifier:RoutePlanAnnotationIdentifier];  
        if (!pinView)  
        {
            // if an existing pin view was not available, create one  
            BMKPinAnnotationView* customPinView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:RoutePlanAnnotationIdentifier];
            pinView = customPinView;
        }
        //UIImage *anoImage = [UIImage imageNamed:@"care1.png"];
        //anoImage 
        //pinView.image = carImage;
        CGPoint offsetPoin = {0.0,0.0};
        pinView.centerOffset = offsetPoin;
        return pinView;
    }
    
    return nil;  
}



- (BMKOverlayView*)mapView:(BMKMapView *)bmkmapview viewForOverlay:(id<BMKOverlay>)overlay
{	
    
	if ([overlay isKindOfClass:[BMKPolyline class]]) 
    {
        BMKPolylineView* polylineView = [ [BMKPolylineView alloc] initWithOverlay:overlay];// autorelease];
        if ([overlay.title isEqualToString:@"traffic"])
        {
            polylineView.fillColor = [[UIColor redColor] colorWithAlphaComponent:1];
            polylineView.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
            polylineView.lineWidth = 7.0;
            polylineView.alpha = 0.9;
            
            //NSLog(@"**************Drawing Traffic Overlay************");
        }
        else if([overlay.title isEqualToString:@"Route"])
        {
            polylineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:1];
            polylineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
            polylineView.lineWidth = 3.0;
            polylineView.alpha = 0.9;
            
            //NSLog(@"**************Drawing Routing Overlay************");
            
        }
        else
        {
            NSLog(@"***Drawing Speed Overlay: %@ ***", overlay.title);
            NSArray *titleCompnArray = [overlay.title componentsSeparatedByString:@"--"];
            if ([[titleCompnArray objectAtIndex:0] isEqualToString:@"Seg4Speed"])
            {
                double speed = [[titleCompnArray objectAtIndex:1] doubleValue];
                double green = 1.0 - ((80.0-speed)/80.0)*0.86; //[255-36] = [1.0-0.14];
                double red = ((80.0 - speed)/80.0)*0.86 ; //[0-220] = [0-0.86]
                double blue = 0.0;//((120.0 - speed)/120.0)*0.12 ; //[0-30] = [0.0 = 0.12]

                polylineView.strokeColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:1.0];
                polylineView.lineWidth = 5.0;
                polylineView.alpha = 0.9;
                
            }
            else
            {
                polylineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:1];
                polylineView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.7];
                polylineView.lineWidth = 2;
                polylineView.alpha = 1;
            }
            
            //NSLog(@"**************Drawing Test Overlay************");
            
        }
        return polylineView;
    }
	return nil;
}


//stepIndex 小于0 则取全路径的范围
- (void) changeMapVisibleRect:(BMKRoute*) route withIndex:(int) stepIndex
{
    int iRoutePointCnt = 0;
    if (stepIndex < 0)
    {
        //int stepCnt = route.pointsCount;
        
        for (int i = 0; i < route.pointsCount; i++) 
        {
            int len = [route getPointsNum:i];
            iRoutePointCnt += len;
        }
        
        if (iRoutePointCnt > 0)
        {
            BMKMapPoint* points = new BMKMapPoint[iRoutePointCnt];
            
            int index = 0; 
            for (int j = 0; j < route.pointsCount; j++) 
            {
                int len = [route getPointsNum:j];
                BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
                memcpy(points + index, pointArray, len * sizeof(BMKMapPoint));
                index += len;
            }
            
            BMKMapRect segRect = [self mapRectMakeFromPoint:&points[0] withPoint:(&points[iRoutePointCnt-1])];    
            UIEdgeInsets edgeFrame={10,10,10,10};
            BMKMapRect fitRect = [mMapView mapRectThatFits:segRect edgePadding:edgeFrame];
            [mMapView setVisibleMapRect:fitRect animated:NO];
            
            delete[] points;
        }
        
    }
    else 
    {
        iRoutePointCnt = [route getPointsNum:stepIndex];
        if (iRoutePointCnt > 0)
        {
            
            BMKMapPoint* points = (BMKMapPoint*)[route getPoints:stepIndex];
            
            BMKMapRect segRect = [self mapRectMakeFromPoint:&points[0] withPoint:(&points[iRoutePointCnt-1])];    
            UIEdgeInsets edgeFrame={10,10,10,10};
            BMKMapRect fitRect = [mMapView mapRectThatFits:segRect edgePadding:edgeFrame];
            [mMapView setVisibleMapRect:fitRect animated:NO];
        }
    }
    
    
}


- (RTTMapPointAnnotation*) addAnnotation2Map:(CLLocationCoordinate2D)coordinate withType:(RTTEN_MAPPOINTTYPE) type
{
    __autoreleasing RTTMapPointAnnotation *pointAnnotation = [[RTTMapPointAnnotation alloc] init];
    pointAnnotation.coordinate = coordinate;
    
    switch (type) {
        case MAPPOINTTYPE_START:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_START;
            pointAnnotation.title = @"起点";
        }
            break;
        case MAPPOINTTYPE_END:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_END;
            pointAnnotation.title = @"终点";
        }
            break;
        case MAPPOINTTYPE_HOME:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_HOME;
            pointAnnotation.title = @"家";
        }
            break;
        default:
        {
            pointAnnotation.pointType = MAPPOINTTYPE_UNDEF;
            pointAnnotation.title = @"点击设置为导航点";
        }
            break;
    }
    
    [mMapView addAnnotation:pointAnnotation];
    
    
//    switch (type) {
//        case MAPPOINTTYPE_START:
//        {
//            pStartPointAnnotation = pointAnnotation;
//        }
//            break;
//        case MAPPOINTTYPE_END:
//        {
//            pEndPointAnnotation = pointAnnotation;
//        }
//            break;
//            
//        default:
//            break;
//    }
    
    
    //因为百度API是异步通过网络返回坐标POI信息，并且没有消息元素区分，所以多个点加入的时间比较短的话有可能会有错误（待处理）
    //pCurrentlyAnnotation = pointAnnotation;
//    
//#warning "导航中路径重规划的时候应该取消查找"?
//    [self getGeoInfofromMAPSVR:coordinate];
//
    return pointAnnotation;
}


//给返回的Annotation点设置地址信息，方便进入地图点类型选择视图的时候显示出来。
-(void) setRoutPlaningViewAddress:(BMKAddrInfo*)addrinfo
{
    //if (addrinfo.addressComponent 
    
    NSString *StrProv = addrinfo.addressComponent.province;
    NSString *StrCity = addrinfo.addressComponent.city;
    NSString *StrDist = addrinfo.addressComponent.district;
    NSString *StrRoad = addrinfo.addressComponent.streetName;
    if (StrRoad == nil) {
        StrRoad = @"未知道路";
    }
    NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"省份:%@\n城市:%@\n地区%@\n街道:%@", StrProv, StrCity,StrDist,StrRoad];

    
//    //FOR TEST，看是否有更加合理的POI地点可用；目前的结论是没有太多价值
//    NSLog(@"------PoiList Cnt==%d", addrinfo.poiList.count);
//    for (int i=0; i<addrinfo.poiList.count; i++)
//    {
//        BMKPoiInfo *poiinfo = [addrinfo.poiList objectAtIndex:i];
//        //NSLog(@"###POIINFO Name=%@ Address=%@", poiinfo.name, poiinfo.address);
//    }
//    
//    if (!pWaitPOIResultAnnotation) 
//    {
//        NSLog(@"Error======pWaitPOIResultAnnotation is NULL!!");
//        return;
//    }
//    else {
//        NSLog(@"pWaitPOIResultAnnotation string=%@", pWaitPOIResultAnnotation.title);
//    }
//    //END
    
    
    //    注意：直接比较坐标的方式不可用，因为百度返回的坐标是存在变化的
    //    这种直接比较的方式是错误的
    //    if((pCurrentlyAnnotation.coordinate.latitude == addrinfo.geoPt.latitude) 
    //        && (pCurrentlyAnnotation.coordinate.longitude == addrinfo.geoPt.longitude) )
    //    {
    //        NSLog(@"坐标匹配");
    //    }
    
    //下面代码是为了避免异步的情况下，把地址信息错误地标识到其他的点
    CLLocationDistance pointDistance = BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(pWaitPOIResultAnnotation.coordinate),
                                                                 BMKMapPointForCoordinate(addrinfo.geoPt));  
    if (pointDistance < 30.0)
    {
        //NSLog(@"坐标匹配");
        pWaitPOIResultAnnotation.addrInfo = addrinfo;
        pWaitPOIResultAnnotation.AddrString = StrFormatedInfo;
    }
    
    
}

#pragma mark -
#pragma mark Process Request to MAP Service

- (BOOL) getPoinameSuggestionfromMAPSVR:(NSString*)searchStr
{
    BOOL callresult = [mBMKSearch suggestionSearch:searchStr];
    return callresult;
}

//获取POI描述信息对应的地理坐标
- (BOOL) getPoiLocationInCityfromMAPSVR:(NSString*)cityName poiName:poiName
{
    return [mBMKSearch poiSearchInCity:cityName withKey:poiName pageIndex:0];
}

//获取地理坐标对应的POI描述信息
- (BOOL) getGeoInfofromMAPSVR:(CLLocationCoordinate2D)coordinate
{
    //因为百度API是异步通过网络返回坐标POI信息，并且没有消息元素区分，所以多个点加入的时间比较短的话有可能会有错误（待处理）

    if (!(self->mBMKSearch))
    {
        self->mBMKSearch = [[BMKSearch alloc]init];
    }
    
    bool result = [self->mBMKSearch reverseGeocode:coordinate];
    if (!result)
    {
        NSLog(@"***设置导航点，获取当前地址错误***");
    }

    //[self showModeIndicator:@"正在获取位置信息" seconds:0];
    
    return result;
}


- (bool) RoutePlanning:(CLLocationCoordinate2D)startpoint end:(CLLocationCoordinate2D)endpoint
{
    NSLog(@"RoutPlaning.....");
    
    //情况前方拥堵的语音播放记录
    [runningDataset.trffTTSPlayRec clear];
    
	if (!mBMKSearch)
    {
        mBMKSearch = [[BMKSearch alloc]init];
        mBMKSearch.delegate = self;
    }
    
	BMKPlanNode* start = [[BMKPlanNode alloc]init];
	BMKPlanNode* end = [[BMKPlanNode alloc]init];
    
    start.pt = startpoint;//(22.559205, 113.963739);
    end.pt = endpoint;//CLLocationCoordinate2DMake(22.575145, 113.907856);
    
    [runningDataset setIsPlaned:NO];
    [runningDataset setCurrentRoadStep:0];
    
    
	bool isSuccPlanCall = [mBMKSearch drivingSearch:@"深圳" startNode:start endCity:@"深圳" endNode:end];
    if (!isSuccPlanCall)
    {
//#if defined (HUAWEIVER)
//        runningDataset.currentlyRoute = ROUTEUNKNOW;
//#endif
        NSLog(@"Call driving search failure");
        runningDataset.isPlaningFailed = YES;
        return false;
    }
//    else 
//    {
//        [self showModeIndicator:@"路径规划中" seconds:10];
//        [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
//    }
    NSLog(@"End of RoutPlaning.....");
    
    return true;
}





#pragma mark -
#pragma mark Process Map Element Data

- (void) getH2ORoute
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"家庭地址未设置");
        return;
    }

    CLLocationCoordinate2D point1 = runningDataset.homeAddrInfo.pt;
    CLLocationCoordinate2D point2 = runningDataset.officeAddrInfo.pt;
    bool ret = [self RoutePlanning:point1 end:point2];
    if (!ret)
    {
        NSLog(@"Route Planing Fail!");
    }
    else 
    {
        [self showModeIndicator:@"路径计算中" seconds:10];
        [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE];
    }

}

- (void) getO2HRoute
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"家庭地址未设置");
        return;
    }
    
    
    CLLocationCoordinate2D point1 = runningDataset.officeAddrInfo.pt;
    CLLocationCoordinate2D point2 = runningDataset.homeAddrInfo.pt;
    bool ret = [self RoutePlanning:point1 end:point2];
    if (!ret)
    {
        NSLog(@"Route Planing Fail!");
    }
    else 
    {
        [self showModeIndicator:@"路径计算中" seconds:10];
        [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE];
    }
}


//从location点作为起始点，重新路径规划
- (void) RePlanRouting:(CLLocationCoordinate2D)location
{
    if (pStartPointAnnotation != nil){
        [mMapView removeAnnotation:pStartPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    
    //pStartPointAnnotation = [self addAnnotation2Map:[mMapView userLocation].coordinate withType:MAPPOINTTYPE_START];
    pStartPointAnnotation = [self addAnnotation2Map:location withType:MAPPOINTTYPE_START];
    
    //获取起点描述信息，因为百度API如果起点在路上，Step信息可能是是没有这条路的路名的；
    pWaitPOIResultAnnotation = pStartPointAnnotation;
    [self getGeoInfofromMAPSVR:location];

    [self CheckPointsSettingCompleted:NO];
}

//过滤路径，进行拟合判断后写入runningDataset.filteredRouteTrafficList
- (BOOL) createTrafficInfo2Dataset:(RTTFormatedTrafficFromTSS*) segTraffic withRttgRoadInfo:(RttGRoadInfo*) roadInfo
{
    int roadPoincnt = [roadInfo.pointlist count];
    
    CLLocationCoordinate2D minRectPoint;
    CLLocationCoordinate2D maxRectPoint;
    
    minRectPoint.longitude = 5000.0;
    minRectPoint.latitude = 50000.0;
    maxRectPoint.longitude = 0.0;
    maxRectPoint.latitude = 0.0;

    for (int i=0; i < roadInfo.pointlist.count; i++)
    {
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].latitude < minRectPoint.latitude)
        {
            minRectPoint.latitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].latitude;
        }
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].longitude < minRectPoint.longitude)
        {
            minRectPoint.longitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].longitude;
        }
        
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].latitude > maxRectPoint.latitude)
        {
            maxRectPoint.latitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].latitude;
        }
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].longitude > maxRectPoint.longitude)
        {
            maxRectPoint.longitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].longitude;
        }
    }
    
//    BMKMapPoint roadPoint1 = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:0] coordinate]);
//    BMKMapPoint roadPoint2 = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:(roadPoincnt-1)] coordinate]);
    BMKMapPoint roadPoint1 = BMKMapPointForCoordinate(minRectPoint);
    BMKMapPoint roadPoint2 = BMKMapPointForCoordinate(maxRectPoint);

    
    BMKMapRect roadRect = [self mapRectMakeFromPoint:&roadPoint1 withPoint:&roadPoint2];
    
    CLLocationCoordinate2D *pPoints = new CLLocationCoordinate2D[2];
    pPoints[0] = segTraffic.startCoord;
    pPoints[1] = segTraffic.endCoord;
//    pPoints[0].latitude = segTraffic.segment.start.lat;
//    pPoints[0].longitude = segTraffic.segment.start.lng;
//    pPoints[1].latitude = segTraffic.segment.end.lat;
//    pPoints[1].longitude = segTraffic.segment.end.lng;
    
    
//#warning FOR TEST        //TEST--YESONGHAI
//    BMKPointAnnotation *pointAnnotation_11 = [[BMKPointAnnotation alloc] init];
//    pointAnnotation_11.coordinate = pPoints[0];
//    NSString *roadst11 =  @"点-1";
//    pointAnnotation_11.title = roadst11;
//    [mMapView addAnnotation:pointAnnotation_11];
//    NSLog(@"拥堵路段: Start=%f, %f", pointAnnotation_11.coordinate.latitude, pointAnnotation_11.coordinate.longitude);
//    
//    BMKPointAnnotation *pointAnnotation_12 = [[BMKPointAnnotation alloc] init];
//    pointAnnotation_12.coordinate = pPoints[1];
//    NSString *roadst12 =  @"点-2";
//    pointAnnotation_12.title = roadst12;
//    [mMapView addAnnotation:pointAnnotation_12];
//    NSLog(@"拥堵路段: End=%f, %f", pointAnnotation_12.coordinate.latitude, pointAnnotation_12.coordinate.longitude);
//    
//    BMKPointAnnotation *pointAnnotation_13 = [[BMKPointAnnotation alloc] init];
//    pointAnnotation_13.coordinate = ([[roadInfo.pointlist objectAtIndex:0] coordinate]);
//    NSString *roadst13 =  @"点-R-1";
//    pointAnnotation_13.title = roadst13;
//    [mMapView addAnnotation:pointAnnotation_13];
//    NSLog(@"Road Point: Start=%f, %f", pointAnnotation_13.coordinate.latitude, pointAnnotation_13.coordinate.longitude);
//    
//    BMKPointAnnotation *pointAnnotation_14 = [[BMKPointAnnotation alloc] init];
//    pointAnnotation_14.coordinate = ([[roadInfo.pointlist objectAtIndex:(roadInfo.pointlist.count-1)] coordinate]);
//    NSString *roadst14 =  @"点-R-2";
//    pointAnnotation_14.title = roadst14;
//    [mMapView addAnnotation:pointAnnotation_14];
//    NSLog(@"Road Point: End=%f, %f", pointAnnotation_14.coordinate.latitude, pointAnnotation_14.coordinate.longitude);

    //ENDTEST
    
    BMKMapPoint SegPoint1 = BMKMapPointForCoordinate(pPoints[0]);
    BMKMapPoint SegPoint2 = BMKMapPointForCoordinate(pPoints[1]);
    BMKMapRect segRect = [self mapRectMakeFromPoint:&SegPoint1 withPoint:&SegPoint2];
    
    BMKMapRect comRect = BMKMapRectIntersection(roadRect, segRect);
    if (BMKMapRectIsNull(comRect) || BMKMapRectIsEmpty(comRect)) //没有交集
    {
        //NSLog(@"没有拟合的矩形");
        return false; 
    }
    else 
    {
        //NSLog(@"拟合矩形");
        BMKMapPoint comPoint1;
        BMKMapPoint comPoint2;
        
        double slope = (pPoints[1].latitude - pPoints[0].latitude)/(pPoints[1].longitude - pPoints[0].longitude);
        
        if (slope < 0.0) //正的斜率，取交集矩形最靠近坐标(0,0)的点和对角点; 地图坐标轴是以左上角为原点; 注意经纬度和直角坐标的区别;
        {
            if (pPoints[1].latitude < pPoints[0].latitude)
            {
                comPoint1 = comRect.origin;
                comPoint2.x = comRect.origin.x + comRect.size.width;
                comPoint2.y = comRect.origin.y + comRect.size.height;
            }
            else 
            {
                comPoint2 = comRect.origin;
                comPoint1.x = comRect.origin.x + comRect.size.width;
                comPoint1.y = comRect.origin.y + comRect.size.height;
            }
            
        }
        else 
        {
            if (pPoints[1].latitude > pPoints[0].latitude)
            {
                comPoint1.x = comRect.origin.x;
                comPoint1.y = comRect.origin.y+comRect.size.height;
                comPoint2.x = comRect.origin.x + comRect.size.width;
                comPoint2.y = comRect.origin.y;
            }
            else 
            {
                comPoint2.x = comRect.origin.x;
                comPoint2.y = comRect.origin.y+comRect.size.height;
                comPoint1.x = comRect.origin.x + comRect.size.width;
                comPoint1.y = comRect.origin.y;
            }
        }
        
        CLLocationDistance cmbRange = BMKMetersBetweenMapPoints(comPoint1, comPoint2);
        if (cmbRange < 50.0) //避免转弯时路口坐标偏差导致的小段拥堵误报
        {
            return false;
        }
        
//#warning FOR TEST        //TEST--YESONGHAI
//        BMKPointAnnotation *pointAnnotation_1 = [[BMKPointAnnotation alloc] init];
//        pointAnnotation_1.coordinate = BMKCoordinateForMapPoint(comPoint1);
//        NSString *roadst1 =  @"C点-1";
//        pointAnnotation_1.title = roadst1;
//        [mMapView addAnnotation:pointAnnotation_1];
//
//        BMKPointAnnotation *pointAnnotation_2 = [[BMKPointAnnotation alloc] init];
//        pointAnnotation_2.coordinate = BMKCoordinateForMapPoint(comPoint2);
//        NSString *roadst2 =  @"C点-2";
//        pointAnnotation_2.title = roadst2;
//        [mMapView addAnnotation:pointAnnotation_2];
//        
//        CLLocationCoordinate2D *testpoints = new CLLocationCoordinate2D[2];
//        testpoints[0].latitude = segTraffic.segment.start.lat;
//        testpoints[0].longitude = segTraffic.segment.start.lng;
//        testpoints[1].latitude = segTraffic.segment.end.lat;
//        testpoints[1].longitude = segTraffic.segment.end.lng;
//        
//        
//        BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:testpoints count:2];
//        polyLine.title = @"test";
//        [mMapView insertOverlay:polyLine atIndex:2];//放在导航线路下面效果会更好
//        delete []testpoints;
//        //ENDTEST
        
        
        //逐段判断路径拟合点并保存
//        BOOL isStartSegPntMached = NO;
//        BOOL isEndSegPntMached = NO;
        RttGTrafficInfo *pTrafficPath = [[RttGTrafficInfo alloc] init];
        pTrafficPath.roadname = roadInfo.roadname;
        pTrafficPath.detail = segTraffic.details;
        pTrafficPath.timeStamp = segTraffic.timestamp;

        
        BMKMapPoint *roadPointList = new BMKMapPoint[roadPoincnt];
        for (int icp = 0; icp < roadPoincnt; icp++)
        {
            roadPointList[icp] = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:icp] coordinate]);
        }
        STPointLineDistInfo stPLDinfoC1;
        CLLocationDistance distCP1 = getNearestDistanceOfRoad(comPoint1, roadPointList, roadPoincnt, &stPLDinfoC1);
        
        STPointLineDistInfo stPLDinfoC2;
        CLLocationDistance distCP2 = getNearestDistanceOfRoad(comPoint2, roadPointList, roadPoincnt, &stPLDinfoC2);
        
        NSLog(@"CP1, IDX=%d, Dist=%f; CP2, IDX=%d, Dist=%f", stPLDinfoC1.pointindex, distCP1, stPLDinfoC2.pointindex, distCP2);
        
        if ((distCP1 >= 0.0 && distCP1 <= 100.0) && (distCP2 >= 0.0 && distCP2 <= 100.0))
        {
            if (stPLDinfoC1.pointindex <= stPLDinfoC2.pointindex)
            {
                //如果拥堵路段比较短，在两个直线的端点之间；则需要判断两个投影点和起始端点的距离，通过这个距离来判断先后顺序（方向）
                if (stPLDinfoC1.pointindex == stPLDinfoC2.pointindex) 
                {
                    BMKMapPoint rdPoint = roadPointList[stPLDinfoC1.pointindex];
                    CLLocationDistance distancM1 = BMKMetersBetweenMapPoints(stPLDinfoC1.projection, rdPoint);
                    CLLocationDistance distancM2 = BMKMetersBetweenMapPoints(stPLDinfoC2.projection, rdPoint);
                    if (distancM1 >= distancM2)
                    {
                        return false;
                    }
                    
                }
                
                RttGMapPoint *mapPoint = [[RttGMapPoint alloc]init];
                mapPoint.mappoint = stPLDinfoC1.projection;
                [pTrafficPath.pointlist addObject:mapPoint];
                //保存拥堵路段起始点在规划路径中的位置，后续用于提示
                pTrafficPath.stepIndex = [[roadInfo.pointlist objectAtIndex:(stPLDinfoC1.pointindex)] stepIndex];
                pTrafficPath.nextPointIndex = [[roadInfo.pointlist objectAtIndex:(stPLDinfoC1.pointindex)] pointIndex];
                
                
                //中间路径
                int iRdPointCnt = (stPLDinfoC2.pointindex - stPLDinfoC1.pointindex);
                for (int iSPI = 0; iSPI < iRdPointCnt; iSPI++)
                {
                    RttGMapPoint *mapPointRd = [[RttGMapPoint alloc]init];
                    int pointIndexOfRoad = stPLDinfoC1.pointindex + iSPI + 1;
                    mapPointRd.mappoint = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:(pointIndexOfRoad)] coordinate]);
                    [pTrafficPath.pointlist addObject:mapPointRd];
                }
                
                //终点
                RttGMapPoint *mapPointE = [[RttGMapPoint alloc]init];
                mapPointE.mappoint = stPLDinfoC2.projection;
                [pTrafficPath.pointlist addObject:mapPointE];
            }
        }
        if (pTrafficPath.pointlist.count > 0)
        {
            [runningDataset.filteredRouteTrafficList addObject: pTrafficPath];//增加到数据集中
            //6.0对讯飞支持不好
            float verValue = deviceVersion.floatValue;
            if (verValue < 6.0)
            {
                NSString *strInfo = [[NSString alloc] initWithFormat:@"最新路况:%@ %@", pTrafficPath.roadname, pTrafficPath.detail];
                [mSynTTS addTrafficStr:strInfo];
            }
        }
        return TRUE;
    }
    
}


- (BOOL) createTrafficPolylineInfo:(LYSegmentTraffic*) segTraffic withRttgRoadInfo:(RttGRoadInfo*) roadInfo
{
    int roadPoincnt = [roadInfo.pointlist count];
    
    CLLocationCoordinate2D minRectPoint;
    CLLocationCoordinate2D maxRectPoint;
    
    minRectPoint.longitude = 5000.0;
    minRectPoint.latitude = 50000.0;
    maxRectPoint.longitude = 0.0;
    maxRectPoint.latitude = 0.0;
    
    for (int i=0; i < roadInfo.pointlist.count; i++)
    {
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].latitude < minRectPoint.latitude)
        {
            minRectPoint.latitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].latitude;
        }
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].longitude < minRectPoint.longitude)
        {
            minRectPoint.longitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].longitude;
        }
        
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].latitude > maxRectPoint.latitude)
        {
            maxRectPoint.latitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].latitude;
        }
        if ([[roadInfo.pointlist objectAtIndex:i] coordinate].longitude > maxRectPoint.longitude)
        {
            maxRectPoint.longitude = [[roadInfo.pointlist objectAtIndex:i] coordinate].longitude;
        }
    }
    
    //    BMKMapPoint roadPoint1 = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:0] coordinate]);
    //    BMKMapPoint roadPoint2 = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:(roadPoincnt-1)] coordinate]);
    BMKMapPoint roadPoint1 = BMKMapPointForCoordinate(minRectPoint);
    BMKMapPoint roadPoint2 = BMKMapPointForCoordinate(maxRectPoint);
    
    
    BMKMapRect roadRect = [self mapRectMakeFromPoint:&roadPoint1 withPoint:&roadPoint2];
    
    CLLocationCoordinate2D *pPoints = new CLLocationCoordinate2D[2];
    pPoints[0].latitude = segTraffic.segment.start.lat;
    pPoints[0].longitude = segTraffic.segment.start.lng;
    pPoints[1].latitude = segTraffic.segment.end.lat;
    pPoints[1].longitude = segTraffic.segment.end.lng;
    
    
    //#warning FOR TEST        //TEST--YESONGHAI
    //    BMKPointAnnotation *pointAnnotation_11 = [[BMKPointAnnotation alloc] init];
    //    pointAnnotation_11.coordinate = pPoints[0];
    //    NSString *roadst11 =  @"点-1";
    //    pointAnnotation_11.title = roadst11;
    //    [mMapView addAnnotation:pointAnnotation_11];
    //    NSLog(@"拥堵路段: Start=%f, %f", pointAnnotation_11.coordinate.latitude, pointAnnotation_11.coordinate.longitude);
    //
    //    BMKPointAnnotation *pointAnnotation_12 = [[BMKPointAnnotation alloc] init];
    //    pointAnnotation_12.coordinate = pPoints[1];
    //    NSString *roadst12 =  @"点-2";
    //    pointAnnotation_12.title = roadst12;
    //    [mMapView addAnnotation:pointAnnotation_12];
    //    NSLog(@"拥堵路段: End=%f, %f", pointAnnotation_12.coordinate.latitude, pointAnnotation_12.coordinate.longitude);
    //
    //    BMKPointAnnotation *pointAnnotation_13 = [[BMKPointAnnotation alloc] init];
    //    pointAnnotation_13.coordinate = ([[roadInfo.pointlist objectAtIndex:0] coordinate]);
    //    NSString *roadst13 =  @"点-R-1";
    //    pointAnnotation_13.title = roadst13;
    //    [mMapView addAnnotation:pointAnnotation_13];
    //    NSLog(@"Road Point: Start=%f, %f", pointAnnotation_13.coordinate.latitude, pointAnnotation_13.coordinate.longitude);
    //
    //    BMKPointAnnotation *pointAnnotation_14 = [[BMKPointAnnotation alloc] init];
    //    pointAnnotation_14.coordinate = ([[roadInfo.pointlist objectAtIndex:(roadInfo.pointlist.count-1)] coordinate]);
    //    NSString *roadst14 =  @"点-R-2";
    //    pointAnnotation_14.title = roadst14;
    //    [mMapView addAnnotation:pointAnnotation_14];
    //    NSLog(@"Road Point: End=%f, %f", pointAnnotation_14.coordinate.latitude, pointAnnotation_14.coordinate.longitude);
    
    //ENDTEST
    
    BMKMapPoint SegPoint1 = BMKMapPointForCoordinate(pPoints[0]);
    BMKMapPoint SegPoint2 = BMKMapPointForCoordinate(pPoints[1]);
    BMKMapRect segRect = [self mapRectMakeFromPoint:&SegPoint1 withPoint:&SegPoint2];
    
    BMKMapRect comRect = BMKMapRectIntersection(roadRect, segRect);
    if (BMKMapRectIsNull(comRect) || BMKMapRectIsEmpty(comRect)) //没有交集
    {
        //NSLog(@"没有拟合的矩形");
        return false;
    }
    else
    {
        //NSLog(@"拟合矩形");
        BMKMapPoint comPoint1;
        BMKMapPoint comPoint2;
        
        double slope = (pPoints[1].latitude - pPoints[0].latitude)/(pPoints[1].longitude - pPoints[0].longitude);
        
        if (slope < 0.0) //正的斜率，取交集矩形最靠近坐标(0,0)的点和对角点; 地图坐标轴是以左上角为原点; 注意经纬度和直角坐标的区别;
        {
            if (pPoints[1].latitude < pPoints[0].latitude)
            {
                comPoint1 = comRect.origin;
                comPoint2.x = comRect.origin.x + comRect.size.width;
                comPoint2.y = comRect.origin.y + comRect.size.height;
            }
            else
            {
                comPoint2 = comRect.origin;
                comPoint1.x = comRect.origin.x + comRect.size.width;
                comPoint1.y = comRect.origin.y + comRect.size.height;
            }
            
        }
        else
        {
            if (pPoints[1].latitude > pPoints[0].latitude)
            {
                comPoint1.x = comRect.origin.x;
                comPoint1.y = comRect.origin.y+comRect.size.height;
                comPoint2.x = comRect.origin.x + comRect.size.width;
                comPoint2.y = comRect.origin.y;
            }
            else
            {
                comPoint2.x = comRect.origin.x;
                comPoint2.y = comRect.origin.y+comRect.size.height;
                comPoint1.x = comRect.origin.x + comRect.size.width;
                comPoint1.y = comRect.origin.y;
            }
        }
        
        CLLocationDistance cmbRange = BMKMetersBetweenMapPoints(comPoint1, comPoint2);
        if (cmbRange < 50.0) //避免转弯时路口坐标偏差导致的小段拥堵误报
        {
            return false;
        }
        
        //#warning FOR TEST        //TEST--YESONGHAI
        //        BMKPointAnnotation *pointAnnotation_1 = [[BMKPointAnnotation alloc] init];
        //        pointAnnotation_1.coordinate = BMKCoordinateForMapPoint(comPoint1);
        //        NSString *roadst1 =  @"C点-1";
        //        pointAnnotation_1.title = roadst1;
        //        [mMapView addAnnotation:pointAnnotation_1];
        //
        //        BMKPointAnnotation *pointAnnotation_2 = [[BMKPointAnnotation alloc] init];
        //        pointAnnotation_2.coordinate = BMKCoordinateForMapPoint(comPoint2);
        //        NSString *roadst2 =  @"C点-2";
        //        pointAnnotation_2.title = roadst2;
        //        [mMapView addAnnotation:pointAnnotation_2];
        //
        //        CLLocationCoordinate2D *testpoints = new CLLocationCoordinate2D[2];
        //        testpoints[0].latitude = segTraffic.segment.start.lat;
        //        testpoints[0].longitude = segTraffic.segment.start.lng;
        //        testpoints[1].latitude = segTraffic.segment.end.lat;
        //        testpoints[1].longitude = segTraffic.segment.end.lng;
        //
        //
        //        BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:testpoints count:2];
        //        polyLine.title = @"test";
        //        [mMapView insertOverlay:polyLine atIndex:2];//放在导航线路下面效果会更好
        //        delete []testpoints;
        //        //ENDTEST
        
        
        //逐段判断路径拟合点并保存
        //        BOOL isStartSegPntMached = NO;
        //        BOOL isEndSegPntMached = NO;
        RttGTrafficInfo *pTrafficPath = [[RttGTrafficInfo alloc] init];
        pTrafficPath.roadname = roadInfo.roadname;
        pTrafficPath.detail = segTraffic.details;
        
        BMKMapPoint *roadPointList = new BMKMapPoint[roadPoincnt];
        for (int icp = 0; icp < roadPoincnt; icp++)
        {
            roadPointList[icp] = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:icp] coordinate]);
        }
        STPointLineDistInfo stPLDinfoC1;
        CLLocationDistance distCP1 = getNearestDistanceOfRoad(comPoint1, roadPointList, roadPoincnt, &stPLDinfoC1);
        
        STPointLineDistInfo stPLDinfoC2;
        CLLocationDistance distCP2 = getNearestDistanceOfRoad(comPoint2, roadPointList, roadPoincnt, &stPLDinfoC2);
        
        NSLog(@"CP1, IDX=%d, Dist=%f; CP2, IDX=%d, Dist=%f", stPLDinfoC1.pointindex, distCP1, stPLDinfoC2.pointindex, distCP2);
        
        if ((distCP1 >= 0.0 && distCP1 <= 100.0) && (distCP2 >= 0.0 && distCP2 <= 100.0))
        {
            if (stPLDinfoC1.pointindex <= stPLDinfoC2.pointindex)
            {
                //如果拥堵路段比较短，在两个直线的端点之间；则需要判断两个投影点和起始端点的距离，通过这个距离来判断先后顺序（方向）
                if (stPLDinfoC1.pointindex == stPLDinfoC2.pointindex)
                {
                    BMKMapPoint rdPoint = roadPointList[stPLDinfoC1.pointindex];
                    CLLocationDistance distancM1 = BMKMetersBetweenMapPoints(stPLDinfoC1.projection, rdPoint);
                    CLLocationDistance distancM2 = BMKMetersBetweenMapPoints(stPLDinfoC2.projection, rdPoint);
                    if (distancM1 >= distancM2)
                    {
                        return false;
                    }
                    
                }
                
                RttGMapPoint *mapPoint = [[RttGMapPoint alloc]init];
                mapPoint.mappoint = stPLDinfoC1.projection;
                [pTrafficPath.pointlist addObject:mapPoint];
                //保存拥堵路段起始点在规划路径中的位置，后续用于提示
                pTrafficPath.stepIndex = [[roadInfo.pointlist objectAtIndex:(stPLDinfoC1.pointindex)] stepIndex];
                pTrafficPath.nextPointIndex = [[roadInfo.pointlist objectAtIndex:(stPLDinfoC1.pointindex)] pointIndex];
                
                
                //中间路径
                int iRdPointCnt = (stPLDinfoC2.pointindex - stPLDinfoC1.pointindex);
                for (int iSPI = 0; iSPI < iRdPointCnt; iSPI++)
                {
                    RttGMapPoint *mapPointRd = [[RttGMapPoint alloc]init];
                    int pointIndexOfRoad = stPLDinfoC1.pointindex + iSPI + 1;
                    mapPointRd.mappoint = BMKMapPointForCoordinate([[roadInfo.pointlist objectAtIndex:(pointIndexOfRoad)] coordinate]);
                    [pTrafficPath.pointlist addObject:mapPointRd];
                }
                
                //终点
                RttGMapPoint *mapPointE = [[RttGMapPoint alloc]init];
                mapPointE.mappoint = stPLDinfoC2.projection;
                [pTrafficPath.pointlist addObject:mapPointE];
            }
        }
        if (pTrafficPath.pointlist.count > 0)
        {
            [runningDataset.filteredRouteTrafficList addObject: pTrafficPath];//增加到数据集中
            //6.0对讯飞支持不好
            float verValue = deviceVersion.floatValue;
            if (verValue < 6.0)
            {
                NSString *strInfo = [[NSString alloc] initWithFormat:@"最新路况:%@ %@", pTrafficPath.roadname, pTrafficPath.detail];
                [mSynTTS addTrafficStr:strInfo];
            }
        }
        return TRUE;
    }
    
}

- (BMKMapRect) mapRectMakeFromPoint:(BMKMapPoint*) point1 withPoint:(BMKMapPoint*) point2
{
    //BMKMapPoint *pointLeftTop = [[BMKMapPoint alloc] init];
    BMKMapPoint pointLeftTop;
    pointLeftTop.x = (point1->x < point2->x)? point1->x:point2->x;
    pointLeftTop.y = (point1->y < point2->y)? point1->y:point2->y;
    double rectwidth = fabs(point1->x - point2->x);
    double rectheight = fabs(point1->y - point2->y);
    
    return BMKMapRectMake(pointLeftTop.x, pointLeftTop.y, rectwidth, rectheight);
}

//获取能够抽取出来的路名列表；返回路名的条数，以及在retArray中的字符串对象
- (int) GetRoadNamesFromBMKRoute:(BMKRoute*) route withRetArray:(NSMutableArray *)retArray
{
    if (!retArray)
    {
        __autoreleasing NSMutableArray *newArray = [[NSMutableArray alloc] init];
        retArray = newArray;
    }
    
    
    //NSString *sRepStr = @"";
    int iStepCnt = route.steps.count;
    
    for (int i = 0; i < iStepCnt; i++)
    {
        BMKStep* step = [route.steps objectAtIndex:i];
        
        //抽取路名，目前是根据“进入.....——xxKM“的规则来抽取
        NSString *cmpFirstStr = @"进入";
        NSString *cmpEndStr = @" - ";
        
        NSString *pKeyPtString =  [[NSString alloc] initWithString:step.content];
        
        NSRange strRange = [pKeyPtString rangeOfString:cmpFirstStr];
        int iStrLocation = strRange.location;
        int iStrLength = strRange.length;
        
        if (iStrLength > 0)
        {
            strRange = [pKeyPtString rangeOfString:cmpEndStr];
            
            if (strRange.length > 0) //存在“进入.........-XXKM”的描述字符，提取路名保存
            {
                iStrLocation = iStrLocation + iStrLength;
                iStrLength = strRange.location - iStrLocation;
                
                NSString *string2 = [pKeyPtString substringWithRange:NSMakeRange(iStrLocation, iStrLength)];
                NSString *strObj = [[NSString alloc] initWithString:string2];
                
                //比较路名是否重复，还没实现路名去重的功能(是否合理待考虑）
                BOOL isRepeated = NO;
                for (int j=0; j < retArray.count; j++)
                {
                    if ( [strObj isEqualToString:((NSString *)[retArray objectAtIndex:j])] )
                    {
                        isRepeated = YES;
                        break;
                    }
                }
                if (!isRepeated)
                {
                    [retArray addObject:strObj];
                }
            }
        }
    }
    
    return retArray.count;
}

- (NSString *) getRoadNameFromStepContent:(NSString *)stepContent
{
    NSString *roadName = @"";
    
    NSString *cmpFirstStr = @"进入";
    NSString *cmpEndStr = @" - ";
    
    NSString *pKeyPtString =  [[NSString alloc] initWithString:stepContent];
    NSRange strRange = [pKeyPtString rangeOfString:cmpFirstStr];
    int iStrLocation = strRange.location;
    int iStrLength = strRange.length;    
    if (iStrLength > 0)
    {
        strRange = [pKeyPtString rangeOfString:cmpEndStr];
        
        if (strRange.length > 0) //存在“进入.........-XXKM”的描述字符，提取路名保存
        {
            iStrLocation = iStrLocation + iStrLength;
            iStrLength = strRange.location - iStrLocation;
            roadName = [pKeyPtString substringWithRange:NSMakeRange(iStrLocation, iStrLength)];
        }
    }
    
    __autoreleasing NSString *strObj = [[NSString alloc] initWithString:roadName];
    return strObj;
}

- (RTTStepInfo *) getStepInfoFromStepContent:(NSString *)stepContent
{

    NSString *cmpSpliteStr = @" - ";
//    NSString *cmpMStr = @"米";
//    NSString *cmpKMStr = @"公里";


    __autoreleasing RTTStepInfo * stepInfo = [[RTTStepInfo alloc] init];
    stepInfo.discriptionStr = @"";
    stepInfo.distanceStr = @"";
    stepInfo.distanceMeter = 0;
    stepInfo.degree = 0;
    
    
    NSArray *listItems = [stepContent componentsSeparatedByString:cmpSpliteStr];

    if (listItems.count > 1)
    {
        stepInfo.discriptionStr = [listItems objectAtIndex:0];
        stepInfo.distanceStr = [listItems objectAtIndex:1];
    }

    return stepInfo;
}


- (void) formateRouteInfoandSave:(BMKRoute*) route
{    
    int iStepCnt = route.steps.count;
    
    RttGRouteInfo *pRouteData = [[RttGRouteInfo alloc] init];
    RttGRoadInfo *pRoaddata = [[RttGRoadInfo alloc] init];
    NSString *prestepRoadName = @"";
    
    for (int i = 0; i < iStepCnt; i++)
    {
        BMKStep* step = [route.steps objectAtIndex:i];
        
        NSString *strObj = [self getRoadNameFromStepContent:step.content];
        
        //增加起始路名的处理，百度API上，如果起始点在路上，并且路径很长，只会有“从起点向东南方出发”类似的提示
        if ((i == 0) && (strObj.length <= 0))
        {
            if (runningDataset.startPointInfo.addressComponent.streetName.length > 0)
            {
                if ( !([runningDataset.startPointInfo.addressComponent.streetName isEqualToString:@"未知道路"]))
                {
                    strObj = runningDataset.startPointInfo.addressComponent.streetName;
                }
            }
        }
        
        if (strObj.length > 0) //有路名
        {
            prestepRoadName = strObj;
            BOOL isInSavedRoad = NO;
            
            //处理在前面的路名重复的情况
            for (int j = 0; j < pRouteData.roadlist.count; j++)
            {
                RttGRoadInfo *savedRoad = [pRouteData.roadlist objectAtIndex:j];
                //如果路名和以前的路名重复，则加入到以前的路名中
#warning        //！还没有处理调头，断续，等等情况
                if ([strObj isEqualToString:savedRoad.roadname])
                {
                    pRoaddata = savedRoad;
                    isInSavedRoad = YES;
                    break;
                }
            }
            
            if (!isInSavedRoad) //如果不重复
            {
                pRoaddata = [[RttGRoadInfo alloc] init];
                pRoaddata.roadname = strObj;
                [pRouteData.roadlist addObject:pRoaddata];
            }
            
            //把路径上的点加入到队列中
            int iPointCnt =  [route getPointsNum:(i+1)]; //百度的数据结构中，点的数据在Step的Index中+1
            BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:(i+1)];
            
            for (int k = 0; k < iPointCnt; k++)
            {
                CLLocationCoordinate2D pPointCoor = BMKCoordinateForMapPoint((BMKMapPoint) *(pointArray+k));
                RttGPoint *point = [[RttGPoint alloc]init];
                point.coordinate = pPointCoor;
                point.stepIndex = i;
                point.pointIndex = k;
                
                [[pRoaddata pointlist]addObject:point]; 
            }
            
        }
        else //只是动作提示，目前认为在上一段路上，路名和上一段路名相同 
        {
            for (int j = 0; j < pRouteData.roadlist.count; j++)
            {
                RttGRoadInfo *savedRoad = [pRouteData.roadlist objectAtIndex:j];
                //取得上一段路名相同的数组
                if ([prestepRoadName isEqualToString:savedRoad.roadname])
                {
                    //把路径上的点加入到队列中
                    int iPointCnt =  [route getPointsNum:(i+1)]; //百度的数据结构中，点的数据在Step的Index中+1
                    BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:(i+1)];
                    
                    for (int k = 0; k < iPointCnt; k++)
                    {
                        CLLocationCoordinate2D pPointCoor = BMKCoordinateForMapPoint((BMKMapPoint) *(pointArray+k));
                        RttGPoint *point = [[RttGPoint alloc]init];
                        point.coordinate = pPointCoor;
                        point.stepIndex = i;
                        point.pointIndex = k;
                        
                        [[savedRoad pointlist]addObject:point]; 
                    }
                    
                    break;
                }
            }
        }
        
    }
    
    [runningDataset setFormatedRouteInfo:pRouteData];
}

- (void) formateHomeOfficeRouteInfoandSave:(BMKRoute*) route direction:(int) direct //0 H2O, 1 O2H
{    
    int iStepCnt = route.steps.count;
    
    RttGRouteInfo *pRouteData = [[RttGRouteInfo alloc] init];
    RttGRoadInfo *pRoaddata = [[RttGRoadInfo alloc] init];
    NSString *prestepRoadName = @"";
    
    for (int i = 0; i < iStepCnt; i++)
    {
        BMKStep* step = [route.steps objectAtIndex:i];
        
        NSString *strObj = [self getRoadNameFromStepContent:step.content];
        
        //增加起始路名的处理，百度API上，如果起始点在路上，并且路径很长，只会有“从起点向东南方出发”类似的提示
        //未处理
        
        
        if (strObj.length > 0) //有路名
        {
            prestepRoadName = strObj;
            BOOL isInSavedRoad = NO;
            
            //处理在前面的路名重复的情况
            for (int j = 0; j < pRouteData.roadlist.count; j++)
            {
                RttGRoadInfo *savedRoad = [pRouteData.roadlist objectAtIndex:j];
                //如果路名和以前的路名重复，则加入到以前的路名中
#warning        //！还没有处理调头，断续，等等情况
                if ([strObj isEqualToString:savedRoad.roadname])
                {
                    pRoaddata = savedRoad;
                    isInSavedRoad = YES;
                    break;
                }
            }
            
            if (!isInSavedRoad) //如果不重复
            {
                pRoaddata = [[RttGRoadInfo alloc] init];
                pRoaddata.roadname = strObj;
                [pRouteData.roadlist addObject:pRoaddata];
            }
            
            //把路径上的点加入到队列中
            int iPointCnt =  [route getPointsNum:(i+1)]; //百度的数据结构中，点的数据在Step的Index中+1
            BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:(i+1)];
            
            for (int k = 0; k < iPointCnt; k++)
            {
                CLLocationCoordinate2D pPointCoor = BMKCoordinateForMapPoint((BMKMapPoint) *(pointArray+k));
                RttGPoint *point = [[RttGPoint alloc]init];
                point.coordinate = pPointCoor;
                point.stepIndex = i;
                point.pointIndex = k;
                
                [[pRoaddata pointlist]addObject:point]; 
            }
            
        }
        else //只是动作提示，目前认为在上一段路上，路名和上一段路名相同 
        {
            for (int j = 0; j < pRouteData.roadlist.count; j++)
            {
                RttGRoadInfo *savedRoad = [pRouteData.roadlist objectAtIndex:j];
                //取得上一段路名相同的数组
                if ([prestepRoadName isEqualToString:savedRoad.roadname])
                {
                    //把路径上的点加入到队列中
                    int iPointCnt =  [route getPointsNum:(i+1)]; //百度的数据结构中，点的数据在Step的Index中+1
                    BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:(i+1)];
                    
                    for (int k = 0; k < iPointCnt; k++)
                    {
                        CLLocationCoordinate2D pPointCoor = BMKCoordinateForMapPoint((BMKMapPoint) *(pointArray+k));
                        RttGPoint *point = [[RttGPoint alloc]init];
                        point.coordinate = pPointCoor;
                        point.stepIndex = i;
                        point.pointIndex = k;
                        
                        [[savedRoad pointlist]addObject:point]; 
                    }
                    
                    break;
                }
            }
        }
        
    }
    
    if (direct == 0)
    {
        [runningDataset setFormatedH2ORouteInfo:pRouteData];
    }
    else {
        [runningDataset setFormatedO2HRouteInfo:pRouteData];
        
    }
}


- (void) CheckPointsSettingCompleted: (BOOL)isFromCurrentLocation 
{
    
    if (pStartPointAnnotation && pEndPointAnnotation)
    {
        CLLocationCoordinate2D point1 = pStartPointAnnotation.coordinate;
        CLLocationCoordinate2D point2 = pEndPointAnnotation.coordinate;
        bool ret = [self RoutePlanning:point1 end:point2];
        if (!ret)
        {
            NSLog(@"Route Planing Fail!");
        }
        else {
            [self showModeIndicator:@"路况获取中" seconds:10];
            [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
        }
    }
    else 
    {
        NSLog(@"Not Start or End point!");
        runningDataset.isPlaned = NO;
    }
    
}


- (BOOL) getPositionFromRoute:(BMKRoute *)route withLocation:(CLLocationCoordinate2D) locat 
              andRetStepIndex:(int *)retStepIndex andretPointsIndex:(int*) retPointsIndex
{
    //关键路径点的数目
    int iStepCnt = runningDataset.drivingRoute.steps.count;
    
    //可变数组，用于保存所有关键路径点的信息
    NSMutableArray *StepIndexs = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < (iStepCnt-1); i++) 
    {
        BMKStep* step_a = [runningDataset.drivingRoute.steps objectAtIndex:i];
        BMKStep* step_b = [runningDataset.drivingRoute.steps objectAtIndex:(i+1)];
        
        //快速判断是否在大的路径上
        bool is_inLine = [self isPointInLine:locat withStepA:step_a andStepB:step_b];
        
        if (is_inLine)
        {
            CandidateSteps *candStep = [[CandidateSteps alloc] init];
            candStep.index = i;
            candStep.StPoint = step_a.pt;
            candStep.EdPoint = step_b.pt;
            [StepIndexs addObject:candStep];
        }
    }
    
    if (0 == StepIndexs.count)
    {
        //NSLog(@"No Mach of Road");
        return NO;
    }
    
    BMKMapPoint locationPoint = BMKMapPointForCoordinate(locat);
    
    int iRetStepIndex = 0;
    int iRetPointIndex = 0;
    STPointLineDistInfo stPLDinfo;
    CLLocationDistance nearestDist = 99999999999999999.0;
    
    for (int i=0; i<StepIndexs.count; i++)
    {
        CandidateSteps *candStep = [StepIndexs objectAtIndex:i];
        int RoutePointIndex = candStep.index+1; //路径点和关键信息提示点在百度地图Routeplan中的Index不一样!
        
        int iPointCnt =  [runningDataset.drivingRoute getPointsNum:RoutePointIndex];
        if (iPointCnt < 1)
        {
            continue;
        }
        
        BMKMapPoint *roadPoints = (BMKMapPoint*)[runningDataset.drivingRoute getPoints:RoutePointIndex];
        CLLocationDistance distOfRoad =  getNearestDistanceOfRoad(locationPoint, roadPoints, iPointCnt, &stPLDinfo);
        
        //BMKStep *pStep = [runningDataset.drivingRoute.steps objectAtIndex:(candStep.index)];
        //NSLog(@"Distance of Road==%@, %f", pStep.content, distOfRoad);
        
        if ((distOfRoad >= 0.0) && (distOfRoad < nearestDist))
        {
            nearestDist = distOfRoad;
            iRetStepIndex = candStep.index;
            iRetPointIndex = stPLDinfo.pointindex;
        }
    }
    
    *retStepIndex = iRetStepIndex;
    *retPointsIndex = iRetPointIndex;
    
    if ((nearestDist >= 0.0) && (nearestDist <= 50.0) ) //小于50M的范围，在路径上
    {
        return YES;
    }
    else 
    {
        return NO;
    }
    
}



//快速判断点是否在线段范围内；使用井形判断，在井的四个角就认为不在线段范围内了
- (bool) isPointInLine:(CLLocationCoordinate2D)location withStepA:(BMKStep*) step_a andStepB:(BMKStep*) step_b
{
    bool is_inLine = false;
    if (step_a.pt.latitude < step_b.pt.latitude)
    {
        if ((location.latitude >= step_a.pt.latitude) 
            && (location.latitude <= step_b.pt.latitude)) 
        {
            is_inLine = true;
        }
    }
    else 
    {
        if ((location.latitude <= step_a.pt.latitude) 
            && (location.latitude >= step_b.pt.latitude)) 
        {
            is_inLine = true;
        } 
    }
    
    if (step_a.pt.longitude < step_b.pt.longitude)
    {
        if ((location.longitude >= step_a.pt.longitude) 
            && (location.longitude <= step_b.pt.longitude)) 
        {
            is_inLine = true;
        }
    }
    else 
    {
        if ((location.longitude <= step_a.pt.longitude) 
            && (location.longitude >= step_b.pt.longitude)) 
        {
            is_inLine = true;
        }
    }
    
    return is_inLine;
}




#pragma mark -
#pragma mark TSS Communication

- (bool) sendDeviceInfo2TSS:(NSData *)deviceToken
{
    UIDevice *dev = [UIDevice currentDevice];
    NSString *deviceUuid = dev.uniqueIdentifier;
    NSString *deviceName = dev.name;
    NSString *deviceModel = dev.model;
    NSString *deviceSystemVersion = dev.systemVersion;
    
    NSLog(@"UUID=%@, Name=%@, Model=%@, Version=%@", deviceUuid, deviceName, deviceModel, deviceSystemVersion);

    LYDeviceReport_Builder *devrptBuilder = [[LYDeviceReport_Builder alloc] init];
    [devrptBuilder setDeviceId:deviceUuid];
    [devrptBuilder setDeviceToken:deviceToken];
    [devrptBuilder setDeviceName:deviceName];
    [devrptBuilder setDeviceModel:deviceModel];
    [devrptBuilder setDeviceOsVersion:deviceSystemVersion];
    
    LYDeviceReport * devrptMsg = [devrptBuilder build];
    
    LYMsgOnAir_Builder *sendPackageBuilder = [[LYMsgOnAir_Builder alloc] init];
    [sendPackageBuilder setVersion:1];
    [sendPackageBuilder setFromParty:LYPartyLyClient];
    [sendPackageBuilder setToParty:LYPartyLyTss];
    //[sendPackageBuilder setMsgDir:TSSMsgDirClient2Tss];
    [sendPackageBuilder setMsgType:LYMsgTypeLyDeviceReport];
    [sendPackageBuilder setMsgId:++mTSSMessageSerialNum];
    
    [sendPackageBuilder setDeviceReport:devrptMsg];
    
    NSDate *now = [NSDate date];
    NSTimeInterval timeStamp = now.timeIntervalSince1970;
    [sendPackageBuilder setTimestamp:timeStamp];
        
    LYMsgOnAir *sendPackage = [sendPackageBuilder build];
    if (sendPackage == nil)
    {
        NSLog(@"*********Failed to build sendPackage");
        return false;
    }
    
    NSData *const request = [sendPackage data];
    NSLog(@"Sending Token------------");
    [mComm4TSS sendData:request withFlags:0]; 
    
    return true;
}

- (bool) sendRouteInfo2TSS:(RttGRouteInfo *)pRouteData type:(RTTEN_ACTIVITYTYPE) routetype
{
    if (!pRouteData)
    {
        return false;
    }
    //构建Protocolbuff结构数据并发送
    //TSS_Point_Builder *tssPointBuild = [[TSS_Point_Builder alloc]init];
    //TSSCoordinate_Builder *tssPointBuild = [[TSSCoordinate_Builder alloc]init];
    LYRoute_Builder *tssRouteBuild = [[LYRoute_Builder alloc] init];
    @autoreleasepool 
    {
        int iRoadCnt = pRouteData.roadlist.count;
        //NSLog(@"Road Cnt %d", iRoadCnt);
        for (int i = 0; i < iRoadCnt; i++)
        {
            RttGRoadInfo *road = [pRouteData.roadlist objectAtIndex:i];
            int iPoincnt = [road.pointlist count];
           
            LYSegment_Builder *tssDrvSegmtBuild = [[LYSegment_Builder alloc]init];
            [tssDrvSegmtBuild setRoad:road.roadname];
            
            LYCoordinate_Builder *startPointBuild = [[LYCoordinate_Builder alloc]init];
            //取开始的点作为路径的起点
            [startPointBuild setLat: [[road.pointlist objectAtIndex:0] coordinate].latitude];
            [startPointBuild setLng: [[road.pointlist objectAtIndex:0] coordinate].longitude];
            LYCoordinate *startPoint = [startPointBuild build];
            
            LYCoordinate_Builder *endPointBuild = [[LYCoordinate_Builder alloc]init];
            //取最后一点作为路径的终点
            Float64 latt = [[road.pointlist objectAtIndex:(iPoincnt-1)] coordinate].latitude;
            Float64 lott = [[road.pointlist objectAtIndex:(iPoincnt-1)] coordinate].longitude;
            [endPointBuild setLat: latt];
            [endPointBuild setLng: lott];
            LYCoordinate *endPoint = [endPointBuild build];
            if (endPoint == nil)
            {
                NSLog(@"*********Failed to build Point");
                return false;
            }
            
            [tssDrvSegmtBuild setStart:startPoint];
            [tssDrvSegmtBuild setEnd:endPoint];
            LYSegment *roadSegment = [tssDrvSegmtBuild build];
            if (roadSegment == nil)
            {
                NSLog(@"*********Failed to build roadSegment");
                return false;
            }
            [tssRouteBuild addSegments:roadSegment];
        }

        switch (routetype) 
        {
            case RTTEN_ACTIVITYTYPE_GETTINGROUTE:
            {[tssRouteBuild setIdentity:1];}
                break;
                
            case RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE:
            {[tssRouteBuild setIdentity:2];}
                break;
                
            case RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE:
            {[tssRouteBuild setIdentity:3];}
                break;
                
            default:
                break;
        }
        
        LYRoute *pDrvRoute = [tssRouteBuild build];
        if (pDrvRoute == nil)
        {
            NSLog(@"*********Failed to build Route");
            return false;
        }
        
        
        LYTrafficSub_Builder *subscMsgBuilder = [[LYTrafficSub_Builder alloc] init];
        [subscMsgBuilder setCity:@"深圳"];
        [subscMsgBuilder setRoute:pDrvRoute];
        [subscMsgBuilder setOprType:LYTrafficSub_LYOprTypeLySubUpdate];
        
        if (routetype == RTTEN_ACTIVITYTYPE_GETTINGROUTE)
        {
            [subscMsgBuilder setPubType:LYTrafficSub_LYPubTypeLyPubEvent];
            [subscMsgBuilder setExpires:120];
        }
        else {
            [subscMsgBuilder  setPubType:LYTrafficSub_LYPubTypeLyPubCron];
            [subscMsgBuilder setExpires:0];
        }
        
        LYTrafficSub *subscriberMsg = [subscMsgBuilder build];
        if (subscriberMsg == nil)
        {
            NSLog(@"*********Failed to build subscriberMsg");
            return false;
        }
        
        
        LYMsgOnAir_Builder *sendPackageBuilder = [[LYMsgOnAir_Builder alloc] init];
        [sendPackageBuilder setVersion:1];
        [sendPackageBuilder setFromParty:LYPartyLyClient];
        [sendPackageBuilder setToParty:LYPartyLyTss];

        [sendPackageBuilder setMsgType:LYMsgTypeLyTrafficSub];
        [sendPackageBuilder setTrafficSub:subscriberMsg];
        [sendPackageBuilder setMsgId:++mTSSMessageSerialNum];

        NSDate *now = [NSDate date];
        NSTimeInterval timeStamp = now.timeIntervalSince1970;
        [sendPackageBuilder setTimestamp:timeStamp];

        //[sendPackageBuilder setRoute:pDrvRoute];
        
        LYMsgOnAir *sendPackage = [sendPackageBuilder build];
        if (sendPackage == nil)
        {
            NSLog(@"*********Failed to build sendPackage");
            return false;
        }
        
        NSData *const request = [sendPackage data];
        NSLog(@"Sending request------------");
#warning FOR TEST 和TSS通信
        [mComm4TSS sendData:request withFlags:0];
    }
    
    return true;
}

- (void) OnRceivePacket:(NSData*) rcvdata
{
    NSLog(@"*********RECEIVED DATA******************");
    if (rcvdata == nil)
    {
        NSLog(@"invalid data");
        return;
    }
    
    LYMsgOnAir *recvPackage = [LYMsgOnAir parseFromData:rcvdata];
    if (recvPackage == nil)
    {
        NSLog(@"Error when parse receive TSS package data");
        return;
    }

    //当前版本，必须通过编译宏动态定义
    if (recvPackage.version < 1)
    {
        NSLog(@"Error Server Version");
        return;
    }
    
    
    if (recvPackage.toParty != LYPartyLyClient)
    {
        NSLog(@"Error Direction in Package");
        return;
    }
    

    int iSeconds = recvPackage.timestamp;
    NSString *recodedTime = [[NSString alloc]initWithUTF8String:(asctime(localtime((time_t*)&iSeconds )))];
    NSLog(@"Package TimeStamp: %@", recodedTime);
    
    NSDate *packetDate = [NSDate dateWithTimeIntervalSince1970:recvPackage.timestamp];
    NSTimeInterval secondsBetweenNow =  [packetDate timeIntervalSinceNow];
    //NSLog(@"Packet Time between = %f", secondsBetweenNow);
    if (secondsBetweenNow <= -600.0) //间隔超过10分钟就直接丢弃
    {
        NSLog(@"===EEE===packet timestamp too early to abumdent");
        return;
    }
        
    
    switch (recvPackage.msgType) {
        case LYMsgTypeLyTrafficPub:
        {
            
            if (recvPackage.hasTrafficPub)
            {
                [self didReceiveTrafficPackage:recvPackage.trafficPub];
            }
            else 
            {
                NSLog(@"Received a CityTraffic package but have not Content");
            }
        }
            break;
            
        default:
            break;
    }
        
}


- (void) didReceiveTrafficPackage:(LYTrafficPub*) trafficPubPackage
{
    
    LYCityTraffic *pTrafficInfo = trafficPubPackage.cityTraffic;
    
#warning FOR TEST 在接受到的拥堵信息上增加测试数据TRAFFIC
    
    //    TSS_CityTraffic* pTestTSSTraffic = [self ConstructTSSData];//:(BMKRoute*) routeinfo
    //    TSS_CityTraffic_Builder *pCityTrafficBuild = [[TSS_CityTraffic_Builder alloc] init];
    //    [pCityTrafficBuild setCity:@"深圳"];
    //    [pCityTrafficBuild setRecorded:pTrafficInfo.recorded];
    //    
    //    int iTSSSegRdCnt = pTrafficInfo.roadtrafficList.count;
    //    TSS_RoadTraffic *pAddRdTrc;
    //    for (int i=0; i<iTSSSegRdCnt; i++)
    //    {
    //        pAddRdTrc = [pTrafficInfo.roadtrafficList objectAtIndex:i];
    //        [pCityTrafficBuild addRoadtraffic:pAddRdTrc];
    //    }
    //    
    //    int iTestSegRdCnt = pTestTSSTraffic.roadtrafficList.count;
    //    for (int j=0; j<iTestSegRdCnt; j++)
    //    {
    //        pAddRdTrc = [pTestTSSTraffic.roadtrafficList objectAtIndex:j];
    //        [pCityTrafficBuild addRoadtraffic:pAddRdTrc];
    //    }
    //    
    //    TSS_CityTraffic *pComTrafficInfo = [pCityTrafficBuild build];
    //    pTrafficInfo = pComTrafficInfo;
    //    //END TEST
    
    
    
    //citytraffic4me = pTrafficInfo;
    //[runningDataset setCityTraffic4Me:pTrafficInfo];
    
#warning 编码调试中...............
    //[self AddTrafficOverlay:pTrafficInfo];
    [self formatAndSaveTrafficData:pTrafficInfo];
    
    [self CheckAndUpdateTrafficListView];

    
#warning LOG-TRAFFIC
//#if defined (DEBUG)
    NSLog(@"---------------Received TrafficInfo--------------");
    NSLog(@"City Name: %@", pTrafficInfo.city);
    NSLog(@"RoadCount: %d", pTrafficInfo.roadTrafficsList.count);
    //localtime((time_t*)(pTrafficInfo.recorded));
    //NSLog(@"Recorded=%lld", pTrafficInfo.timestamp);


    
    int iSegRdCnt = pTrafficInfo.roadTrafficsList.count;
    LYRoadTraffic *pRdTrc;
    for (int i=0; i<iSegRdCnt; i++)
    {
        pRdTrc = [pTrafficInfo.roadTrafficsList objectAtIndex:i];
        NSLog(@"RoadName: %@", pRdTrc.road);
        NSLog(@"Description:%@", pRdTrc.desc);
        int iSegCnt = pRdTrc.segmentTrafficsList.count;
        
        for (int j=0; j<iSegCnt; j++)
        {
            LYSegmentTraffic *pSegTrf = [pRdTrc.segmentTrafficsList objectAtIndex:j];
            NSLog(@"Direction: %d", pSegTrf.direction);
            NSLog(@"Speed: %d", pSegTrf.speed);
            NSLog(@"Details: %@", pSegTrf.details);
            NSLog(@"StartPoint: %f, %f",  pSegTrf.segment.start.lng, pSegTrf.segment.start.lat);
            NSLog(@"EndPoint: %f, %f", pSegTrf.segment.end.lng, pSegTrf.segment.end.lat);
            int iSeconds = pSegTrf.timestamp;
            NSString *recodedTime = [[NSString alloc]initWithUTF8String:(asctime(localtime((time_t*)&iSeconds )))];
            NSLog(@"TimeStamp formated: %@", recodedTime);
        }
    }
//#endif
    
}


- (void) CheckAndUpdateTrafficListView
{
    NSLog(@"Test CheckAndUpdateTrafficListView");
    int ctrlCnt = [self.navigationController.viewControllers count];
    for (int i = 0; i < ctrlCnt; i++)
    {
        UIViewController *pCtrlinQue = [self.navigationController.viewControllers objectAtIndex:i];
        if ([pCtrlinQue isKindOfClass:[RTTTrafficListViewController class]])
        {
            RTTTrafficListViewController *pTrafficCtrl = (RTTTrafficListViewController*)pCtrlinQue;
            [pTrafficCtrl.trafficListTBL reloadData];
            NSLog(@"UpdateTrafficListView.........");
        }
    }
}

#pragma mark -
#pragma mark TEST Self

- (void) addTestData
{
    [self createTestPath];
    
    //iTestLocIndex = 0;
    //locUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(timeLocUpdate) userInfo:nil repeats:YES]; 
    
    //testLocationList = [[NSMutableArray alloc] init];
    
    //[self createTestLocations];
    //pTestCareAnnotation = nil;
    //carImage = [UIImage imageNamed:@"carred2.png"];    
}

- (void) TestRoadNameAndPoints
{
    int iRoadCnt = runningDataset.formatedRouteInfo.roadlist.count;
    NSLog(@"Road Cnt %d", iRoadCnt);
    for (int i = 0; i < iRoadCnt; i++)
    {
        //RttGRoadInfo *road = [formatedrouteinfo.roadlist objectAtIndex:i];
        RttGRoadInfo *road = [runningDataset.formatedRouteInfo.roadlist objectAtIndex:i];
        int iPoincnt = [road.pointlist count];
        NSLog(@"Road Index: %d, Name: %@, PoinCnt %d", i, road.roadname, iPoincnt);
        
        CLLocationCoordinate2D pPoints[2];
        
        //pPoints[0].latitude = [[road.pointlist objectAtIndex:0] lat];
        //pPoints[0].longitude = [[road.pointlist objectAtIndex:0] lon];        
        //pPoints[1].latitude = [[road.pointlist objectAtIndex:(iPoincnt-1)] lat];
        //pPoints[1].longitude = [[road.pointlist objectAtIndex:(iPoincnt-1)] lon];     
        pPoints[0] = [[road.pointlist objectAtIndex:0] coordinate];
        pPoints[1] = [[road.pointlist objectAtIndex:(iPoincnt-1)] coordinate];
        
        BMKPointAnnotation *pointAnnotation_1 = [[BMKPointAnnotation alloc] init];
        pointAnnotation_1.coordinate = pPoints[0];
        NSString *roadst = [[NSString alloc]initWithFormat:@"%@-%@",road.roadname, @"起点"];
        pointAnnotation_1.title = roadst;
        [mMapView addAnnotation:pointAnnotation_1];
        
        BMKPointAnnotation *pointAnnotation_2 = [[BMKPointAnnotation alloc] init];
        pointAnnotation_2.coordinate = pPoints[1];
        NSString *roaded = [[NSString alloc]initWithFormat:@"%@-%@",road.roadname, @"终点"];
        pointAnnotation_2.title = roaded;
        [mMapView addAnnotation:pointAnnotation_2];
    } 
}

- (LYCityTraffic*) ConstructTSSData//:(BMKRoute*) routeinfo
{
    
    
    //深南大道/南山大道(路口)    坐标：113.929296,22.545851
    LYCoordinate_Builder *pPoint_shennan_1_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_shennan_1_p1 setLng:(113.929296)];
    [pPoint_shennan_1_p1 setLat:(22.545851)];
    //南新路/深南大道(路口)    坐标：113.926909,22.546228
    LYCoordinate_Builder *pPoint_shennan_1_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_shennan_1_p2 setLng:(113.926909)];
    [pPoint_shennan_1_p2 setLat:(22.546228)];
    LYSegment_Builder *pLineBuild_shennan_1 = [[LYSegment_Builder alloc] init];
    [pLineBuild_shennan_1 setStartBuilder:pPoint_shennan_1_p1];
    [pLineBuild_shennan_1 setEndBuilder:pPoint_shennan_1_p2];
    LYSegmentTraffic_Builder *pSegBuild_shennan_1 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_shennan_1 setSpeed:10];
    [pSegBuild_shennan_1 setDetails:@"前方拥堵：南山大道路口到南新路路口 方向：西向"];
    [pSegBuild_shennan_1 setDirection:LYDirectionLyWest];
    [pSegBuild_shennan_1 setSegmentBuilder:pLineBuild_shennan_1];
    LYSegmentTraffic *pSeg_shennan_1 = [pSegBuild_shennan_1 build];
    
    //深南大道/南海大道(路口)    坐标：113.938478,22.545289
    LYCoordinate_Builder *pPoint_shennan_2_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_shennan_2_p1 setLng:(113.938478)];
    [pPoint_shennan_2_p1 setLat:(22.545289)];
    //深南大道/南山大道(路口)    坐标：113.929296,22.545851
    LYCoordinate_Builder *pPoint_shennan_2_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_shennan_2_p2 setLng:(113.929296)];
    [pPoint_shennan_2_p2 setLat:(22.545851)];
    LYSegment_Builder *pLineBuild_shennan_2 = [[LYSegment_Builder alloc] init];
    [pLineBuild_shennan_2 setStartBuilder:pPoint_shennan_2_p1];
    [pLineBuild_shennan_2 setEndBuilder:pPoint_shennan_2_p2];
    LYSegmentTraffic_Builder *pSegBuild_shennan_2 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_shennan_2 setSpeed:10];
    [pSegBuild_shennan_2 setDetails:@"前方拥堵：南海大道路口到南山大道路口 方向：西向"];
    [pSegBuild_shennan_2 setDirection:LYDirectionLyWest];
    [pSegBuild_shennan_2 setSegmentBuilder:pLineBuild_shennan_2];
    LYSegmentTraffic *pSeg_shennan_2 = [pSegBuild_shennan_2 build];
    
    LYRoadTraffic_Builder *pRoadBuild_shennan = [[LYRoadTraffic_Builder alloc] init];
    [pRoadBuild_shennan setRoad:@"深南大道"];
    [pRoadBuild_shennan addSegmentTraffics:pSeg_shennan_1];
    [pRoadBuild_shennan addSegmentTraffics:pSeg_shennan_2];
    [pRoadBuild_shennan setDesc:@"shenan"];
    LYRoadTraffic *pRoad_shennan = [pRoadBuild_shennan build];
    
    
    //北环大道/南海大道(路口)    坐标：113.940385,22.56035
    LYCoordinate_Builder *pPoint_nanhai_1_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_nanhai_1_p1 setLng:(113.940385)];
    [pPoint_nanhai_1_p1 setLat:(22.56035)];
    //龙岗路/南海大道(路口)  坐标：113.935013,22.525017
    LYCoordinate_Builder *pPoint_nanhai_1_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_nanhai_1_p2 setLng:(113.935013)];
    [pPoint_nanhai_1_p2 setLat:(22.525017)];
    LYSegment_Builder *pLineBuild_nanhai_1 = [[LYSegment_Builder alloc] init];
    [pLineBuild_nanhai_1 setStartBuilder:pPoint_nanhai_1_p2];
    [pLineBuild_nanhai_1 setEndBuilder:pPoint_nanhai_1_p1];
    LYSegmentTraffic_Builder *pSegBuild_nanhai_1 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_nanhai_1 setSpeed:10];
    [pSegBuild_nanhai_1 setDetails:@"前方拥堵：龙岗路路口到北环大道路口 方向：北向"];
    [pSegBuild_nanhai_1 setDirection:LYDirectionLyWest];
    [pSegBuild_nanhai_1 setSegmentBuilder:pLineBuild_nanhai_1];
    LYSegmentTraffic *pSeg_nanhai_1 = [pSegBuild_nanhai_1 build];
    
    //南海大道/创业路(路口)    坐标：113.933132,22.520743
    LYCoordinate_Builder *pPoint_nanhai_2_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_nanhai_2_p1 setLng:(113.933132)];
    [pPoint_nanhai_2_p1 setLat:(22.520743)];
    //南海大道/东滨路(路口)  坐标：113.930127,22.510216
    LYCoordinate_Builder *pPoint_nanhai_2_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_nanhai_2_p2 setLng:(113.930127)];
    [pPoint_nanhai_2_p2 setLat:(22.510216)];
    LYSegment_Builder *pLineBuild_nanhai_2 = [[LYSegment_Builder alloc] init];
    [pLineBuild_nanhai_2 setStartBuilder:pPoint_nanhai_2_p2];
    [pLineBuild_nanhai_2 setEndBuilder:pPoint_nanhai_2_p1];
    LYSegmentTraffic_Builder *pSegBuild_nanhai_2 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_nanhai_2 setSpeed:10];
    [pSegBuild_nanhai_2 setDetails:@"前方拥堵：东滨路路口到创业路路口 方向：北向"];
    [pSegBuild_nanhai_2 setDirection:LYDirectionLyWest];
    [pSegBuild_nanhai_2 setSegmentBuilder:pLineBuild_nanhai_2];
    LYSegmentTraffic *pSeg_nanhai_2 = [pSegBuild_nanhai_2 build];
    
    LYRoadTraffic_Builder *pRoadBuild_nanhai = [[LYRoadTraffic_Builder alloc] init];
    [pRoadBuild_nanhai setRoad:@"南海大道"];
    [pRoadBuild_nanhai addSegmentTraffics:pSeg_nanhai_1];
    [pRoadBuild_nanhai addSegmentTraffics:pSeg_nanhai_2];
    [pRoadBuild_nanhai setDesc:@"南海大道"];
    LYRoadTraffic *pRoad_nanhai = [pRoadBuild_nanhai build];
    
    //--红荔路
    //华强北路口    坐标：22.560482, 114.092727
    LYCoordinate_Builder *pPoint_hongli_1_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_hongli_1_p1 setLng:(114.092727)];
    [pPoint_hongli_1_p1 setLat:(22.560482)];
    //上步中路口    坐标：22.555224, 114.102595
    LYCoordinate_Builder *pPoint_hongli_1_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_hongli_1_p2 setLng:(114.102595)];
    [pPoint_hongli_1_p2 setLat:(22.555224)];
    LYSegment_Builder *pLineBuild_hongli_1 = [[LYSegment_Builder alloc] init];
    [pLineBuild_hongli_1 setStartBuilder:pPoint_hongli_1_p1];
    [pLineBuild_hongli_1 setEndBuilder:pPoint_hongli_1_p2];
    LYSegmentTraffic_Builder *pSegBuild_hongli_1 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_hongli_1 setSpeed:10];
    [pSegBuild_hongli_1 setDetails:@"N1-Detail"];
    [pSegBuild_hongli_1 setDirection:LYDirectionLyWest];
    [pSegBuild_hongli_1 setSegmentBuilder:pLineBuild_hongli_1];
    LYSegmentTraffic *pSeg_hongli_1 = [pSegBuild_hongli_1 build];
    
    LYRoadTraffic_Builder *pRoadBuild_hongli = [[LYRoadTraffic_Builder alloc] init];
    [pRoadBuild_hongli setRoad:@"红荔路"];
    [pRoadBuild_hongli addSegmentTraffics:pSeg_hongli_1];
    //[pRoadBuild_hongli addSegmenttraffic:pSeg_hongli_2];
    [pRoadBuild_hongli setDesc:@"shenan"];
    LYRoadTraffic *pRoad_hongli = [pRoadBuild_hongli build];
    //--END-红荔路
    
    //--隆平路
    //五和大道路口    坐标：114.065571,22.651841
    LYCoordinate_Builder *pPoint_longping_1_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_longping_1_p1 setLng:(114.065571)];
    [pPoint_longping_1_p1 setLat:(22.651841)];
    //坂雪岗大道路口    坐标：114.07265,22.651991
    LYCoordinate_Builder *pPoint_longping_1_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_longping_1_p2 setLng:(114.07265)];
    [pPoint_longping_1_p2 setLat:(22.651991)];
    LYSegment_Builder *pLineBuild_longping_1 = [[LYSegment_Builder alloc] init];
    [pLineBuild_longping_1 setStartBuilder:pPoint_longping_1_p1];
    [pLineBuild_longping_1 setEndBuilder:pPoint_longping_1_p2];
    LYSegmentTraffic_Builder *pSegBuild_longping_1 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_longping_1 setSpeed:10];
    [pSegBuild_longping_1 setDetails:@"东向 五和大道路口-坂雪岗大道路口"];
    [pSegBuild_longping_1 setDirection:LYDirectionLyWest];
    [pSegBuild_longping_1 setSegmentBuilder:pLineBuild_longping_1];
    LYSegmentTraffic *pSeg_longping_1 = [pSegBuild_longping_1 build];
    
    LYRoadTraffic_Builder *pRoadBuild_longping = [[LYRoadTraffic_Builder alloc] init];
    [pRoadBuild_longping setRoad:@"隆平路"];
    [pRoadBuild_longping addSegmentTraffics:pSeg_longping_1];
    //[pRoadBuild_longping addSegmenttraffic:pSeg_longping_2];
    [pRoadBuild_longping setDesc:@"shenan"];
    LYRoadTraffic *pRoad_longping = [pRoadBuild_longping build];
    //--END-隆平路
    
    //--冲之大道
    //稼先路口    坐标：114.067817,22.656944
    LYCoordinate_Builder *pPoint_chongzhi_1_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_chongzhi_1_p1 setLng:(114.067817)];
    [pPoint_chongzhi_1_p1 setLat:(22.656944)];
    //隆平路口    坐标：114.068053,22.654608
    LYCoordinate_Builder *pPoint_chongzhi_1_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_chongzhi_1_p2 setLng:(114.068053)];
    [pPoint_chongzhi_1_p2 setLat:(22.654608)];
    LYSegment_Builder *pLineBuild_chongzhi_1 = [[LYSegment_Builder alloc] init];
    [pLineBuild_chongzhi_1 setStartBuilder:pPoint_chongzhi_1_p1];
    [pLineBuild_chongzhi_1 setEndBuilder:pPoint_chongzhi_1_p2];
    LYSegmentTraffic_Builder *pSegBuild_chongzhi_1 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_chongzhi_1 setSpeed:10];
    [pSegBuild_chongzhi_1 setDetails:@"南向 稼先路路口-隆平路之间TEST"];
    [pSegBuild_chongzhi_1 setDirection:LYDirectionLyWest];
    [pSegBuild_chongzhi_1 setSegmentBuilder:pLineBuild_chongzhi_1];
    LYSegmentTraffic *pSeg_chongzhi_1 = [pSegBuild_chongzhi_1 build];
    
    LYRoadTraffic_Builder *pRoadBuild_chongzhi = [[LYRoadTraffic_Builder alloc] init];
    [pRoadBuild_chongzhi setRoad:@"冲之大道"];
    [pRoadBuild_chongzhi addSegmentTraffics:pSeg_chongzhi_1];
    //[pRoadBuild_chongzhi addSegmenttraffic:pSeg_chongzhi_2];
    [pRoadBuild_chongzhi setDesc:@"shenan"];
    LYRoadTraffic *pRoad_chongzhi = [pRoadBuild_chongzhi build];
    //--END-冲之大道
    
    
//    //--沙河西路(X256)
//    //大冲    坐标：113.964597,22.555065
//    TSSCoordinate_Builder *pPoint_shahexi_1_p1 = [[TSSCoordinate_Builder alloc]init];
//    [pPoint_shahexi_1_p1 setLng:(113.964597)];
//    [pPoint_shahexi_1_p1 setLat:(22.555065)];
//    //深南大道    坐标：113.965442,22.547856
//    TSSCoordinate_Builder *pPoint_shahexi_1_p2 = [[TSSCoordinate_Builder alloc]init];
//    [pPoint_shahexi_1_p2 setLng:(113.965442)];
//    [pPoint_shahexi_1_p2 setLat:(22.547856)];
//    TSSSegment_Builder *pLineBuild_shahexi_1 = [[TSSSegment_Builder alloc] init];
//    [pLineBuild_shahexi_1 setStartBuilder:pPoint_shahexi_1_p1];
//    [pLineBuild_shahexi_1 setEndBuilder:pPoint_shahexi_1_p2];
//    TSSSegmentTraffic_Builder *pSegBuild_shahexi_1 = [[TSSSegmentTraffic_Builder alloc] init];
//    [pSegBuild_shahexi_1 setSpeed:10];
//    [pSegBuild_shahexi_1 setDetails:@"南向 大冲路口-深南立交"];
//    [pSegBuild_shahexi_1 setDirection:TSSDirectionWest];
//    [pSegBuild_shahexi_1 setSegmentBuilder:pLineBuild_shahexi_1];
//    TSSSegmentTraffic *pSeg_shahexi_1 = [pSegBuild_shahexi_1 build];
//    
//    TSSRoadTraffic_Builder *pRoadBuild_shahexi = [[TSSRoadTraffic_Builder alloc] init];
//    [pRoadBuild_shahexi setRoad:@"X256"];
//    [pRoadBuild_shahexi addSegmentTraffics:pSeg_shahexi_1];
//    //[pRoadBuild_shahexi addSegmenttraffic:pSeg_shahexi_2];
//    [pRoadBuild_shahexi setDesc:@"shenan"];
//    TSSRoadTraffic *pRoad_shahexi = [pRoadBuild_shahexi build];
//    //--END-沙河西路(X256)
    
//    //--北环大道
//    //南海立交    坐标：113.943294,22.557569
//    TSSCoordinate_Builder *pPoint_shahexi_1_p1 = [[TSSCoordinate_Builder alloc]init];
//    [pPoint_shahexi_1_p1 setLng:(113.943294)];
//    [pPoint_shahexi_1_p1 setLat:(22.557569)];
//    //龙珠立交    坐标：113.994246,22.561307
//    TSSCoordinate_Builder *pPoint_shahexi_1_p2 = [[TSSCoordinate_Builder alloc]init];
//    [pPoint_shahexi_1_p2 setLng:(113.994246)];
//    [pPoint_shahexi_1_p2 setLat:(22.561307)];
//    TSSSegment_Builder *pLineBuild_shahexi_1 = [[TSSSegment_Builder alloc] init];
//    [pLineBuild_shahexi_1 setStartBuilder:pPoint_shahexi_1_p1];
//    [pLineBuild_shahexi_1 setEndBuilder:pPoint_shahexi_1_p2];
//    TSSSegmentTraffic_Builder *pSegBuild_shahexi_1 = [[TSSSegmentTraffic_Builder alloc] init];
//    [pSegBuild_shahexi_1 setSpeed:10];
//    [pSegBuild_shahexi_1 setDetails:@"前方拥堵：南海立交到龙珠立交，东向"];
//    [pSegBuild_shahexi_1 setDirection:TSSDirectionWest];
//    [pSegBuild_shahexi_1 setSegmentBuilder:pLineBuild_shahexi_1];
//    TSSSegmentTraffic *pSeg_shahexi_1 = [pSegBuild_shahexi_1 build];
//    
//    TSSRoadTraffic_Builder *pRoadBuild_shahexi = [[TSSRoadTraffic_Builder alloc] init];
//    [pRoadBuild_shahexi setRoad:@"北环大道"];
//    [pRoadBuild_shahexi addSegmentTraffics:pSeg_shahexi_1];
//    //[pRoadBuild_shahexi addSegmenttraffic:pSeg_shahexi_2];
//    [pRoadBuild_shahexi setDesc:@"北环大道"];
//    TSSRoadTraffic *pRoad_shahexi = [pRoadBuild_shahexi build];
//    //--END-北环大道
    
    //--南山大道
    //桃园路    坐标：113.931375, 22.538141
    LYCoordinate_Builder *pPoint_shahexi_1_p1 = [[LYCoordinate_Builder alloc]init];
    [pPoint_shahexi_1_p1 setLng:(113.931375)];
    [pPoint_shahexi_1_p1 setLat:(22.538141)];
    //桂庙路    坐标：113.930125, 22.529976
    LYCoordinate_Builder *pPoint_shahexi_1_p2 = [[LYCoordinate_Builder alloc]init];
    [pPoint_shahexi_1_p2 setLng:(113.930125)];
    [pPoint_shahexi_1_p2 setLat:(22.529976)];
    LYSegment_Builder *pLineBuild_shahexi_1 = [[LYSegment_Builder alloc] init];
    [pLineBuild_shahexi_1 setStartBuilder:pPoint_shahexi_1_p1];
    [pLineBuild_shahexi_1 setEndBuilder:pPoint_shahexi_1_p2];
    LYSegmentTraffic_Builder *pSegBuild_shahexi_1 = [[LYSegmentTraffic_Builder alloc] init];
    [pSegBuild_shahexi_1 setSpeed:10];
    [pSegBuild_shahexi_1 setDetails:@"前方拥堵：从桃园路到桂庙路，蛇口方向"];
    [pSegBuild_shahexi_1 setDirection:LYDirectionLyWest];
    [pSegBuild_shahexi_1 setSegmentBuilder:pLineBuild_shahexi_1];
    LYSegmentTraffic *pSeg_shahexi_1 = [pSegBuild_shahexi_1 build];
    
    LYRoadTraffic_Builder *pRoadBuild_shahexi = [[LYRoadTraffic_Builder alloc] init];
    [pRoadBuild_shahexi setRoad:@"南山大道"];
    [pRoadBuild_shahexi addSegmentTraffics:pSeg_shahexi_1];
    //[pRoadBuild_shahexi addSegmenttraffic:pSeg_shahexi_2];
    [pRoadBuild_shahexi setDesc:@"南山大道"];
    LYRoadTraffic *pRoad_shahexi = [pRoadBuild_shahexi build];
    //--END-南山大道
    
    LYCityTraffic_Builder *pCityTrafficBuild = [[LYCityTraffic_Builder alloc] init];
    [pCityTrafficBuild setCity:@"深圳"];
    [pCityTrafficBuild setTimestamp:0];
    [pCityTrafficBuild addRoadTraffics:pRoad_shennan];
    [pCityTrafficBuild addRoadTraffics:pRoad_nanhai];
    [pCityTrafficBuild addRoadTraffics:pRoad_hongli];
    [pCityTrafficBuild addRoadTraffics:pRoad_longping];
    [pCityTrafficBuild addRoadTraffics:pRoad_chongzhi];
    [pCityTrafficBuild addRoadTraffics:pRoad_shahexi];
    
    
    __autoreleasing LYCityTraffic *pTrafficInfo = [pCityTrafficBuild build];
    
    
    return pTrafficInfo;
}


- (void) createTestPath
{
    BMKAddrInfo *startAddr = [[BMKAddrInfo alloc]init];
    startAddr.addressComponent.streetName = @"文心二路";
    CLLocationCoordinate2D startLoc;
    startLoc.latitude = 22.5256;
    startLoc.longitude = 113.937464;
    startAddr.geoPt = startLoc;
    startAddr.strAddr = @"";
    
    BMKAddrInfo *endAddr = [[BMKAddrInfo alloc]init];
    endAddr.addressComponent.streetName = @"办公室";
    CLLocationCoordinate2D endLoc;
    endLoc.latitude = 22.575232;
    endLoc.longitude = 113.907802;
    endAddr.geoPt = endLoc;
    endAddr.strAddr = @"";
    
    RttGHistoryPathInfo *pathInfo = [[RttGHistoryPathInfo alloc] init];
    pathInfo.startPointInfo = startAddr;
    pathInfo.endPointInfo = endAddr;
    pathInfo.pathName = @"路线1:文心二路-华丰时代广场";
    
    [runningDataset.historyPathInfoList addObject:pathInfo];
    
    RttGHistoryPathInfo *pathInfo2 = [[RttGHistoryPathInfo alloc] init];
    pathInfo2.startPointInfo = endAddr;
    pathInfo2.endPointInfo = startAddr;
    pathInfo2.pathName = @"路线2:华丰时代广场-文心二路";
    
    
    [runningDataset.historyPathInfoList addObject:pathInfo2];
    
    BMKAddrInfo *startAddr3 = [[BMKAddrInfo alloc]init];
    startAddr3.addressComponent.streetName = @"五和大道";
    CLLocationCoordinate2D startLoc3;
    startLoc3.latitude = 22.660177;
    startLoc3.longitude = 114.063939;
    startAddr3.geoPt = startLoc3;
    startAddr3.strAddr = @"";
    
    BMKAddrInfo *endAddr3 = [[BMKAddrInfo alloc]init];
    endAddr3.addressComponent.streetName = @"万科城";
    CLLocationCoordinate2D endLoc3;
    endLoc3.latitude = 22.651723;
    endLoc3.longitude = 114.073568;
    endAddr3.geoPt = endLoc3;
    endAddr3.strAddr = @"";
    
    RttGHistoryPathInfo *pathInfo3 = [[RttGHistoryPathInfo alloc] init];
    pathInfo3.startPointInfo = startAddr3;
    pathInfo3.endPointInfo = endAddr3;
    pathInfo3.pathName = @"路线3:华电门口-万科城";
    
    [runningDataset.historyPathInfoList addObject:pathInfo3];
    
    
    BMKAddrInfo *startAddr4 = [[BMKAddrInfo alloc]init];
    startAddr4.addressComponent.streetName = @"松坪街";
    CLLocationCoordinate2D startLoc4;
    startLoc4.latitude = 22.561224;
    startLoc4.longitude = 113.962787;
    startAddr4.geoPt = startLoc4;
    startAddr4.strAddr = @"";
    
    BMKAddrInfo *endAddr4 = [[BMKAddrInfo alloc]init];
    endAddr4.addressComponent.streetName = @"世界之窗";
    CLLocationCoordinate2D endLoc4;
    endLoc4.latitude = 22.54297;
    endLoc4.longitude = 113.9807;
    endAddr4.geoPt = endLoc4;
    endAddr4.strAddr = @"";
    
    RttGHistoryPathInfo *pathInfo4 = [[RttGHistoryPathInfo alloc] init];
    pathInfo4.startPointInfo = startAddr4;
    pathInfo4.endPointInfo = endAddr4;
    pathInfo4.pathName = @"路线4:松坪街-世界之窗";
    
    [runningDataset.historyPathInfoList addObject:pathInfo4];
    
}



#pragma mark -
#pragma mark smart detecter

//上班 0; 下班 1
- (NSInteger) detectPath
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"家庭地址未设置");
        return -1;
    }
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | 
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    NSDate *now = [NSDate date];
    comps = [calendar components:unitFlags fromDate:now];
    NSInteger hour = [comps hour];
    
    //上班时间段
    if (hour >= 2 && hour < 12)
    {
        if (runningDataset.currentlyRoute != GOTOOFFICE)
        {
            //re-planing
            NSLog(@"Replaning to Office");
            [self routePlantoOffice];
            runningDataset.currentlyRoute = GOTOOFFICE;
        }
        else {
            if (runningDataset.isPlaned)
            {
                //update_traffic
                [self sendRouteInfo2TSS:runningDataset.formatedRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
            }
            else {
                [self routePlantoOffice];
                runningDataset.currentlyRoute = GOTOOFFICE;
            }
        }
    }
    else //下班
    {
        if (runningDataset.currentlyRoute != GOHOME)
        {
            //re-planing
            [self routePlantoHome];
            runningDataset.currentlyRoute = GOHOME;
        }
        else {
            if (runningDataset.isPlaned)
            {
            //update_traffic
            [self sendRouteInfo2TSS:runningDataset.formatedRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
            }
            else {
                //re-planing
                [self routePlantoHome];
                runningDataset.currentlyRoute = GOHOME;
            }
        }
    }
    
    
    return -1;
}


- (void) routePlantoOffice
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"家庭地址未设置");
        return;
    }
    
    if (pStartPointAnnotation != nil){
        [mMapView removeAnnotation:pStartPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    if (pEndPointAnnotation != nil){
        [mMapView removeAnnotation:pEndPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    
    pStartPointAnnotation = [self addAnnotation2Map:runningDataset.homeAddrInfo.pt withType:MAPPOINTTYPE_START];
    pEndPointAnnotation = [self addAnnotation2Map:runningDataset.officeAddrInfo.pt withType:MAPPOINTTYPE_END];
    
    [self CheckPointsSettingCompleted:NO];

}

- (void) routePlantoHome
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"家庭地址未设置");
        return;
    }
    
    if (pStartPointAnnotation != nil){
        [mMapView removeAnnotation:pStartPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    if (pEndPointAnnotation != nil){
        [mMapView removeAnnotation:pEndPointAnnotation]; //地图上只保留一个起始点或者终点
    }
    
    pStartPointAnnotation = [self addAnnotation2Map:runningDataset.officeAddrInfo.pt withType:MAPPOINTTYPE_START];
    pEndPointAnnotation = [self addAnnotation2Map:runningDataset.homeAddrInfo.pt withType:MAPPOINTTYPE_END];
    
    [self CheckPointsSettingCompleted:NO];
    
}




@end
