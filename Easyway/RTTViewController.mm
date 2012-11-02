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
//#import "RTTRoutePreviewViewController.h"
//#import "RTTRouteBookmarkViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RTTGuideBoardView.h"
#import "RTTSuggestionListViewController.h"
//#import "RTTTopBarView.h"
#import "RTTHomeAddrViewController.h"
#import "RTTTrafficListViewController.h"
#import "RTTIntroPageViewController.h"
#import "RTTAccountViewController.h"
#import "RTTTrafficBoardView.h"
#import "RTTModeActivityIndicatorView.h"
#import "RTTComm4TSS.h"
#import "RTTSynthesizeTTS.h"

#import "RTTSearchBarView.h"
#import "RTTPrefSettingViewController.h"



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
    
    //初始化合成语音模块
    [self initTTS];
    
    //增加测试数据
    [self addTestData];
    
    
    [self initLoadData];

    [self processIntroPage];
    
    [self detectPath];
    
}

- (void)viewDidUnload
{
    mCenterView = nil;
    [self setBack2locBTN:nil];
    [self setShowTrafficViewBTN:nil];
    [self setShowSearchBarBTN:nil];
    [self setUiDestinationLBL:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) initTimer
{
    mModeIndicatorTimer = nil;
    mActivityTimer = nil;
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
    [mMapView setCenterOfMapView:centerlocation];
    
    //百度地图API，允许获取和显示用户当前位置
    [mMapView setShowsUserLocation:YES];
    // 地图比例尺级别，在手机上当前可使用的级别为3-18级
    [mMapView setZoomLevel:15];
    
    [mCenterView addSubview:mMapView];
    //mCenterView = mMapView;
    
//    CALayer *overlayCover = [[CALayer alloc] init];
//    overlayCover.backgroundColor = [[[UIColor brownColor] colorWithAlphaComponent:0.8] CGColor];
//    [mMapView.layer addSublayer:overlayCover];
    
    //[mMapView setCenterCoordinate:([self getCurLocation])];
    [mMapView setCenterOfMapView:([mMapView getCurLocation])];
    
    if (!mBMKSearch)
    {
        mBMKSearch = [[BMKSearch alloc] init];
        mBMKSearch.delegate = self;
    }
}

- (void) initMainViewUnit
{
    //初始化各种窗口部件
    
    //设置guide board
    [self initGuideBoard];
    [self hideGuideBoard];
    
    //设置Traffic board
    [self initTrafficBoard];
    [self hideTrafficBoard];
    
    [self initModeIndicator];
    [self closeModeIndicator];
    
    //设置顶部的自定义搜索条
    [self initTopSearchBar];
    
    //设置搜索建议结果列表框
    [self initSuggestionListView];
    [self.view addSubview:mSuggestionListVC.view];
    
    [self initButtomBar];
    //[self initTopBar];
    
    //地图上的小按钮
    //设置阴影
    back2locBTN.layer.shadowColor = [[UIColor blackColor] CGColor];
    back2locBTN.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    back2locBTN.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    back2locBTN.layer.shadowRadius = 10.0f; // 阴影发散的程度
    
    [self initDestinationLBL];
}

- (void) initRunningParam
{

    runningDataset = [[RTTRunningDataSet alloc] init];//运行时所有的数据集都在这个大类里头, datamodel
    
    mRunningActivity = RTTEN_ACTIVITYTYPE_IDLE;
    mActivityTimer = nil;
    
    mSpeedIndex = 0;
    mSpeedSedList = [[NSMutableArray alloc] initWithCapacity:1000];
    
    mIsOutofRange = NO;
    
    
    runningDataset.thisDev = [UIDevice currentDevice];
    runningDataset.deviceVersion = runningDataset.thisDev.systemVersion;
    runningDataset.deviceUuid = runningDataset.thisDev.uniqueIdentifier;
}

- (void) initCommUnit
{
    //初始化和启动通信模块
    mTSSMessageSerialNum = 0; //消息序列号
    
    mComm4TSS = [[RTTComm4TSS alloc] initWithEndpoint:@"tcp://roadclouding.com:7001" uuID:runningDataset.deviceUuid delegate:self];
}

- (void) initTTS
{
    float verValue = runningDataset.deviceVersion.floatValue;
    if (verValue < 6.0)
    {
        mSynTTS = [[RTTSynthesizeTTS alloc] init:10];
    }
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
    NSArray *loadHomeInfoArray = [saveDefaults objectForKey:@"HomeAddrSaveKey"];
    if (loadHomeInfoArray.count < 3)
    {
        //return;
    }
    else
    {
        NSString *loadHomeAddr = [loadHomeInfoArray objectAtIndex:0];
        NSString *loadHomeLat = [loadHomeInfoArray objectAtIndex:1];
        NSString *loadHomeLon = [loadHomeInfoArray objectAtIndex:2];
        if (!loadHomeAddr || !loadHomeLat || !loadHomeLon)
        {
            NSLog(@"无法加载家庭地址");
            NSLog(@"str:%@, %@, %@",loadHomeAddr, loadHomeLat, loadHomeLon);

        }
        else
        {
            NSLog(@"加载家庭地址str:%@, %@, %@",loadHomeAddr, loadHomeLat, loadHomeLon);
            
            __autoreleasing BMKPoiInfo *homePoi = [[BMKPoiInfo alloc] init];
            homePoi.address = loadHomeAddr;
            CLLocationCoordinate2D loadHomeLoc;
            loadHomeLoc.latitude = [loadHomeLat floatValue];
            loadHomeLoc.longitude = [loadHomeLon floatValue];
            homePoi.pt = loadHomeLoc;
            runningDataset.homeAddrInfo = homePoi;
        }
    }
    
    NSArray *loadOfficeInfoArray = [saveDefaults objectForKey:@"OfficeAddrSaveKey"];
    if (loadOfficeInfoArray.count < 3)
    {
        //return;
    }
    else
    {
        NSString *loadOfficeAddr = [loadOfficeInfoArray objectAtIndex:0];
        NSString *loadOfficeLat = [loadOfficeInfoArray objectAtIndex:1];
        NSString *loadOfficeLon = [loadOfficeInfoArray objectAtIndex:2];
        if (!loadOfficeAddr || !loadOfficeLat || !loadOfficeLon)
        {
            //return;
        }
        else
        {
            NSLog(@"str:%@, %@, %@",loadOfficeAddr, loadOfficeLat, loadOfficeLon);
            
            __autoreleasing BMKPoiInfo *officePoi = [[BMKPoiInfo alloc] init];
            officePoi.address = loadOfficeAddr;
            CLLocationCoordinate2D loadOfficeLoc;
            loadOfficeLoc.latitude = [loadOfficeLat floatValue];
            loadOfficeLoc.longitude = [loadOfficeLon floatValue];
            officePoi.pt = loadOfficeLoc;
            runningDataset.officeAddrInfo = officePoi;
        }
    }
    
    
    NSString *isIntroReaded = [saveDefaults objectForKey:@"isReadedIntroPage"];
    if ([isIntroReaded isEqualToString: @"YES"])
    {
        runningDataset.isReadedIntroPage = YES;
    }
    
    
    NSString *switchStat = [saveDefaults objectForKey:@"TSSSwitchOnOffSaveKey"];
    if (switchStat && [switchStat isEqualToString: @"NO"])
    {
        self.TTSSwitchOnOff = NO;
    }
    else
    {
        self.TTSSwitchOnOff = YES;  //缺省是ON
    }

    
    switchStat = [saveDefaults objectForKey:@"AutoDetectOnOffSaveKey"];
    if (switchStat && [switchStat isEqualToString: @"NO"])
    {
        self.autoDetectOnOff = NO;
    }
    else
    {
        self.autoDetectOnOff = YES; //缺省是ON
    }

    
    switchStat = [saveDefaults objectForKey:@"AutoScaleOnOffSaveKey"];
    if (switchStat && [switchStat isEqualToString: @"YES"])
    {
        self.autoScaleOnOff = YES;
    }
    else
    {
        self.autoScaleOnOff = NO;  //缺省不缩放
    }

}

- (void) processIntroPage
{
    //if (runningDataset.homeAddrInfo)
    if (runningDataset.isReadedIntroPage)
    {
        return;
    }
    
    RTTIntroPageViewController *introPageVW = [[RTTIntroPageViewController alloc] init];
    introPageVW.delegate = self;
    [self.navigationController pushViewController:introPageVW animated:NO];

    
}

#pragma mark -
#pragma mark Timer process

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

- (void)didTTSSwitchOnOff:(BOOL)isOn
{
    self.TTSSwitchOnOff = isOn;
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    if (isOn)
    {
        [saveDefaults setObject:@"YES" forKey:@"TSSSwitchOnOffSaveKey"];
    }
    else
    {
        [saveDefaults setObject:@"NO" forKey:@"TSSSwitchOnOffSaveKey"];
    }
    [saveDefaults synchronize];

}

- (void)didAutoDetectSwitchOnOff:(BOOL)isOn
{
    self.autoDetectOnOff = isOn;
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    if (isOn)
    {
        [saveDefaults setObject:@"YES" forKey:@"AutoDetectOnOffSaveKey"];
    }
    else
    {
        [saveDefaults setObject:@"NO" forKey:@"AutoDetectOnOffSaveKey"];
    }
    [saveDefaults synchronize];

    
}

- (void)didAutoScaleMapSwitchOnOff:(BOOL)isOn
{
    self.autoScaleOnOff = isOn;
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    if (isOn)
    {
        [saveDefaults setObject:@"YES" forKey:@"AutoScaleOnOffSaveKey"];
    }
    else
    {
        [saveDefaults setObject:@"NO" forKey:@"AutoScaleOnOffSaveKey"];
    }
    [saveDefaults synchronize];

}

- (IBAction)didSaveSpeedSegs:(id)sender
{
    //路况1
    //6.0对讯飞支持不好
    float verValue = runningDataset.deviceVersion.floatValue;
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

- (IBAction)didShowPrefSettingView:(id)sender
{
    RTTPrefSettingViewController *prefSettingVC = [[RTTPrefSettingViewController alloc] init];
    NSString *addrHome = @"未设置";
    NSString *addrOffice = @"未设置";

    if (runningDataset.homeAddrInfo && runningDataset.homeAddrInfo.address)
    {
        addrHome = runningDataset.homeAddrInfo.address;
    }
    if (runningDataset.officeAddrInfo && runningDataset.officeAddrInfo.address)
    {
        addrOffice = runningDataset.officeAddrInfo.address;
    }
    
    NSString *strAddrInfo = [[NSString alloc] initWithFormat:@"家庭地址:\n%@\n\n公司地址:\n%@", addrHome, addrOffice];
    [prefSettingVC setAddrInfoTxt:strAddrInfo];
    
    [prefSettingVC setTTSSwitchStat:self.TTSSwitchOnOff];
    [prefSettingVC setAutoDetectSwitchStat:self.autoDetectOnOff];
    [prefSettingVC setAutoScaleSwitchStat:self.autoScaleOnOff];
    
    [prefSettingVC setDelegate:self];
    
    //prefSettingVC.view.layer.backgroundColor = [[UIColor clearColor] CGColor];;
    //prefSettingVC.view.layer. = 0.5f;
    //self.modalPresentationStyle = UIModalPresentationCurrentContext;

//    prefSettingVC.view.backgroundColor = [UIColor blackColor];
//    prefSettingVC.view.alpha = 0.5f;
//    self.modalPresentationStyle = UIModalPresentationCurrentContext;

    //[self presentModalViewController:prefSettingVC animated:YES];
//    self.navigationController.view.backgroundColor = [UIColor clearColor];
//    self.navigationController.view.alpha = 0.1f;
    //self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;


    [self.navigationController pushViewController:prefSettingVC animated:NO];
    
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


- (IBAction)didPanOnMap:(id)sender
{
    //NSLog(@"Pan=============================");

}


//- (void) didHomeAddrReset:(id)sender
//{
//    [self toHomeSettingView];
//}

- (void) didToolbarHomeSettingBTN:(id)sender
{
    [mSwipeBar toggle:NO];

    [self didShowPrefSettingView:sender];
}

//- (void) toHomeAddrReview
//{
//    RTTHomeAddrViewController *homeAddrPreviewVC = [[RTTHomeAddrViewController alloc] init];
//    //homeAddrPreviewVC.mHomeAddrLBL.text = mHomeAddrInfo.address;
//    NSString *addrStr;
//    if (runningDataset.homeAddrInfo.name != nil)
//    {
//        addrStr = [[NSString alloc] initWithFormat:@"%@\n%@", runningDataset.homeAddrInfo.name, runningDataset.homeAddrInfo.address];
//    }
//    else {
//        addrStr =  runningDataset.homeAddrInfo.address;
//    }
//    
//    homeAddrPreviewVC.addrTxt = addrStr;
//    homeAddrPreviewVC.addrLocation = runningDataset.homeAddrInfo.pt;
//    
//    [homeAddrPreviewVC setDelegate:self];  
//    
//    [mSwipeBar toggle:NO];
//    [self.navigationController pushViewController:homeAddrPreviewVC animated:YES];
//    
//}


- (void) didToolbarAccountBTN:(id)sender
{
    [mSwipeBar toggle:NO];

    RTTAccountViewController *accountVM = [[RTTAccountViewController alloc] init];
    //[accountVM setWebpageStr:@"http://www.baidu.com"];
    [self.navigationController pushViewController:accountVM animated:YES];
}

- (void)didToolbarGoHomeBTN:(id)sender
{
    if (runningDataset.homeAddrInfo == nil)
    {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"家庭地址未设置\n请通过搜索或者长按地图上对应的地址进行设置"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        return;
    }
    
    [self routePlanCurLoctoHome];
}

- (void)didToolbarGoOfficeBTN:(id)sender
{
    if (runningDataset.officeAddrInfo == nil)
    {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"公司地址未设置\n请通过搜索或者长按地图上对应的地址进行设置"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        return;
    }
    
    [self routePlanCurLoctoOffice];
}



- (IBAction)didBack2UserLocation:(id)sender 
{
    //[mMapView setCenterCoordinate:[mMapView userLocation].coordinate animated:0];
    [mMapView setCenterOfMapView:([mMapView getCurLocation])];

}

- (IBAction)didShowSearchbar:(id)sender
{
    [self showTopSearchBar];
    //[mTopSearchBar setHidden:NO];
    [self hideDestinationLBL];
}

- (void)didHideAddrSearchBar:(id)sender
{
    [self hideTopSearchBar];
    [self showDestinationLBL];
}

-(void) showSettingRoutPointView:(int) pointtype
{

    RTTMapPointSettingViewController *mapPointVC = [[RTTMapPointSettingViewController alloc] init];
    mapPointVC.delegate = self;
    mapPointVC.addrTxt =  mMapView.currentlySelectedAnnotation.addrString;
    
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
        }
            break;
            
        case RTTSETMAPPOIN_END:
        {
        }
            break;
            
        case RTTSETMAPPOIN_ROUTETO:
        {
            CLLocationCoordinate2D endLoc = mMapView.currentlySelectedAnnotation.coordinate;
            runningDataset.currentlyRoute = ROUTECODETEMPROUTE;
            
            
            //获取路名
            NSString *pKeyPtString =  [[NSString alloc] initWithString:mMapView.currentlySelectedAnnotation.addrString];
            NSArray *strArray = [pKeyPtString componentsSeparatedByString:@"\n"];
            NSInteger strCnt = strArray.count;
            NSString *strRdName = @"未知道路";
            if (strCnt > 1)
            {
                if ([[strArray objectAtIndex:(strCnt-1)] length] != 0)
                {
                    strRdName = [strArray objectAtIndex:(strCnt-1)];
                }
            }
            self.currentlyRouteEndAddr = [[NSString  alloc] initWithFormat:@"到%@路况", strRdName];
            
            [self routePlanCurLoctoTemp:endLoc];

        }
            break;
            
        case RTTSETMAPPOIN_DELETE:
        {
            [mMapView removeAnnotation:mMapView.currentlySelectedAnnotation];
        }
            break;
            
            
        case RTTSETMAPPOIN_OFFICE:
        {
            
            BMKPoiInfo *officePoi = [[BMKPoiInfo alloc] init];
            if (mMapView.currentlySelectedAnnotation.addrString != nil)
            {
                officePoi.address = mMapView.currentlySelectedAnnotation.addrString;
            }
            else
            {
                officePoi.address = @"未知道路";
            }

            officePoi.pt = mMapView.currentlySelectedAnnotation.coordinate;
            runningDataset.officeAddrInfo = officePoi;
            [self saveOfficeData];
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"公司地址设置成功！\r\n您下次可以直接使用上班按钮获取上班路况"
                                                              delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
            [alertView show];
            
            
            runningDataset.currentlyRoute = ROUTECODEGOTOOFFICE;//
            [self routePlanCurLoctoOffice];
        }
            break;
            
        case RTTSETMAPPOIN_HOME:
        {
            BMKPoiInfo *homePoi = [[BMKPoiInfo alloc] init];
            if (mMapView.currentlySelectedAnnotation.addrString != nil)
            {
                homePoi.address = mMapView.currentlySelectedAnnotation.addrString;
            }
            else
            {
                homePoi.address = @"未知道路";
            }

            homePoi.pt = mMapView.currentlySelectedAnnotation.coordinate;
            runningDataset.homeAddrInfo = homePoi;
            [self saveHomeData];
            
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"家庭地址设置成功！\r\n您下次可以直接使用回家按钮获取回家路况"
                                                              delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
            [alertView show];
            
            
            
            runningDataset.currentlyRoute = ROUTECODEGOHOME;//
            [self routePlanCurLoctoHome];
        }
            break;
            
            
            
            
        default:
            break;
    }
    
    //因为只能有一个Undefine的点，所以设置了具体类型后，这个点就不是Undef了。
    //mMapView.pUndefAnnotation = nil;
    
    //[self CheckPointsSettingCompleted:0];
    
    
}


#pragma mark -
#pragma mark Searchbar delegate

- (void)didAddrSearchWasPressed:(NSString*)inputStr
{
    NSString *strPOIName = inputStr;
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
        [self hideTopSearchBar];

        [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGGEO];
        [self showModeIndicator:@"获取地理坐标信息" seconds:10];
    }
    
}
- (void)didAddrSearchInputWasChanged:(NSString*)inputStr
{
    if ([inputStr length] != 0)
    {
        BOOL callresult = [self getPoinameSuggestionfromMAPSVR:inputStr];
        if (!callresult)
        {
            NSLog(@"######Call sugession Error");
        }
        
        mSuggestionListVC.searchText = inputStr;
        [mSuggestionListVC updateData];
        [self setSearchListHidden:NO];
    }
    else
    {
        [self setSearchListHidden:YES];
    }

}
- (void)didAddrSearchBegin:(id)sender
{
    [mSuggestionListVC clearData];
    
    if (runningDataset.searchHistoryArray.count > 0)
    {
        for (NSString *searchHisTxt in runningDataset.searchHistoryArray)
        {
            NSLog(@"**********Input TXT=%@************", searchHisTxt);
            [mSuggestionListVC.resultList addObject:searchHisTxt];
        }
        [mSuggestionListVC updateData];
        [self setSearchListHidden:NO];
    }
    
}


#pragma mark -
#pragma mark UserLogin and Token and Profile

- (void) gotUserLoginToken:(NSString*) token
{
    [runningDataset setUserToken:token];
    //[self sendUserProfile2Server:token];
    NSLog(@"Will Send Profile to Server");
}



- (void)didResultlistSelected:(NSString *)poiName
{
	if (poiName) 
    {
        [self didAddrSearchWasPressed:poiName];
        [runningDataset saveSearchHistory:poiName];
	}
    [self setSearchListHidden:YES];
    
    [self hideTopSearchBar];
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
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        //坐标转换
        CGPoint touchPoint = [sender locationInView:mMapView];
        CLLocationCoordinate2D touchMapCoordinate = [mMapView addUndefAnnotationWithTouchPoint:touchPoint];
        
        //CLLocationCoordinate2D touchMapCoordinate = [mMapView convertPoint:touchPoint toCoordinateFromView:mMapView];
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
        //[mSuggestionListVC updateData];
    }
    [mSuggestionListVC updateData];
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
            
            BMKPoiInfo *firstPoi = [result.poiInfoList objectAtIndex:0];
            NSString *pointAddr = firstPoi.address;
            NSString *pointName = firstPoi.name;
            NSString *addrTxt = [[NSString alloc] initWithFormat:@"%@\r\n%@", pointAddr, pointName ];
            
            [mMapView removeAllUndefAnnotation];
            [mMapView addAnnotation2Map:poi.pt withType:MAPPOINTTYPE_UNDEF addr:addrTxt];
            
            [mMapView setCenterOfMapView:poi.pt];
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
        return;
    }
    
    [mMapView setWaitingPOIAnnotationAddress:result];
    
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
    
    if (runningDataset.currentlyRoute == ROUTECODEGOTOOFFICE)
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
    if (runningDataset.currentlyRoute == ROUTECODEGOHOME)
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
    else
    {
        iRouteCnt = 1; //目前百度只提供一个route，为了防止后续多个，这里暂时固定为1
    }
    
    for (int i = 0; i < iRouteCnt; i++)
    {
        [runningDataset setDrivingRoute:[plan.routes objectAtIndex:i]];
        runningDataset.drivingRoute.startPt = result.startNode.pt;
        runningDataset.drivingRoute.endPt = result.endNode.pt;

        [mMapView AddDrivingRouteOverlay:runningDataset.drivingRoute];
        [self formateRouteInfoandSave:runningDataset.drivingRoute];
        [self sendRouteInfo2TSS:runningDataset.formatedRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
    }
    
    if (self.autoScaleOnOff)
    {
        [mMapView changeMapVisibleRect:runningDataset.drivingRoute withIndex:-1];
    }
    
    [runningDataset setIsPlaned:YES];
    
    //清理地图和路况数据
    [mMapView removeAllTrafficPolylines];

    [runningDataset.trafficContainer removeAllRouteTraffic];
    [runningDataset.trafficContainer clearOutofDateTrafficData4Hot];
    [runningDataset.trafficContainer removeAllFilteredTraffic];
    
    [runningDataset.trafficContainer reFilteTrafficWithRoadList:runningDataset.formatedRouteInfo.roadlist];

    
    [mSwipeBar toggle:NO];
    [self start2Go];    
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
        [mMapView setCenterOfMapView:temp_userLocation];
    }
        
    BMKMapPoint LocationPoint = BMKMapPointForCoordinate(temp_userLocation);
    int stepIndex, pointIndex;
    
    //NSLog(@"stepIndex.count= %d", StepIndexs.count);
    bool isOnPlan = false; //是否在路径上
    
    isOnPlan = [RTTMapKit getPositionFromRoute:runningDataset.drivingRoute withLocation:temp_userLocation
                          andRetStepIndex:&stepIndex andretPointsIndex:&pointIndex];
    
    
    //如果在规划路径内，则显示路名，或者提示关键动作
    if (isOnPlan)
    {
        //首先先关闭所有的提示窗口
        [self hideGuideBoard];
        [self hideTrafficBoard];
        

//#if !defined (HUAWEIVER)
        //if (runningDataset.isRouteGuideON)
        if (self.autoScaleOnOff == YES)
        {
            //切换视图
            if (runningDataset.currentRoadStep !=  stepIndex)
            {
                [mMapView changeMapVisibleRect:runningDataset.drivingRoute withIndex:stepIndex+1];
                [mMapView setCenterOfMapView:temp_userLocation];
            }
        }
//#endif
        //保存当前在Step的哪一步了
        runningDataset.currentRoadStep = stepIndex;
        runningDataset.nextRoadPointIndex = pointIndex;
        isOnPlan = true;
        
        
        //路名和提示
        if (runningDataset.isRouteGuideON)
        {
            if (stepIndex < ([runningDataset.drivingRoute.steps count]-1)) //如果是最后一段了，不提示？
            {
                BMKStep* step = [runningDataset.drivingRoute.steps objectAtIndex:stepIndex];
                BMKStep* pNextStep = [runningDataset.drivingRoute.steps objectAtIndex:stepIndex+1];
                
                CLLocationDistance nextPointDistance = BMKMetersBetweenMapPoints(LocationPoint,
                                                                                 BMKMapPointForCoordinate(pNextStep.pt));
                
                if (nextPointDistance < 300.0) //和下一点距离小于300米就提示关键信息
                {
                    if (runningDataset.isRouteGuideON)
                    {
                        [self setGuideBoardContent:pNextStep.content];
                    }
                }
                else //否则提示路名
                {
                    //NSString *stepInfo = [[NSString alloc] initWithString:step.content];
                    //抽取路名，目前是根据“进入.....——xxKM“的规则来抽取
                    NSString *roadName = [RTTMapKit getRoadNameFromStepContent:step.content];
                    
                    if (roadName.length > 0)
                    {
                        [self hideGuideBoard];
                    }
                }
            }
        }
        
        //判断拥堵提示
        RttGMatchedTrafficInfo *nearestTrffSeg =
            [runningDataset.trafficContainer getNearestTrafficSeg:runningDataset.currentRoadStep pointIndex:runningDataset.nextRoadPointIndex];
        
        if (nearestTrffSeg != nil)
        {
            RttGMapPoint *trafficpoint = [nearestTrffSeg.pointlist objectAtIndex:0];

            CLLocationDistance nextTrafficDistance = BMKMetersBetweenMapPoints(LocationPoint,
                                                                               trafficpoint.mappoint);
            
            if (nextTrafficDistance < 2000.0) //和下一个拥堵点距离小于2000米就提示关键信息
            {
                NSString *trafficInfoText = [[NSString alloc] initWithFormat:@"%@", nearestTrffSeg.roadname];
                
                [self setTrafficBoardContent:nearestTrffSeg.roadname distance:nextTrafficDistance detail:nearestTrffSeg.detail];
                [self showTrafficBoard];
                
                NSLog(@"%@", trafficInfoText);
                
                //播放语音，每隔500M
                if (![runningDataset.trffTTSPlayRec ifRecorded:nextTrafficDistance stepIndex:nearestTrffSeg.stepIndex pointIndex:nearestTrffSeg.nextPointIndex])
                {
                    [runningDataset.trffTTSPlayRec record:nextTrafficDistance stepIndex:nearestTrffSeg.stepIndex pointIndex:nearestTrffSeg.nextPointIndex];
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
                    //float verValue = runningDataset.deviceVersion.floatValue;
                    //if (verValue < 6.0)
                    if (self.TTSSwitchOnOff == YES)
                    {
                        NSString *strInfo = [[NSString alloc] initWithFormat:@"路况提示：前方约%@，%@，%@", distanceStr, nearestTrffSeg.roadname, nearestTrffSeg.detail];
                        [mSynTTS addGuideStr:strInfo];
                    }
                }
                
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
        
        //保存最后判断的在规划路径上的点坐标，用于判断偏离距离
        mLastOnPlanLocation = temp_userLocation;

//        int trafficSegCnt = runningDataset.trafficContainer.filteredRouteTrafficList.count;
//        for (int trfindex = 0; trfindex < trafficSegCnt; trfindex++)
//        {
//            RttGMatchedTrafficInfo *trfinfo = [runningDataset.trafficContainer.filteredRouteTrafficList objectAtIndex:trfindex];
//            
//            //如果当前点的Step位置和拥堵点相同，并且路径点中下一点小于拥堵点在路径点中相关位置（意味着还没到）
//            //或者当前点的Step位置比拥堵点小
//            if ((runningDataset.currentRoadStep == trfinfo.stepIndex && runningDataset.nextRoadPointIndex <= trfinfo.nextPointIndex)
//                || (runningDataset.currentRoadStep < trfinfo.stepIndex))
//            {
//                RttGMapPoint *trafficpoint = [trfinfo.pointlist objectAtIndex:0];
//                CLLocationDistance nextTrafficDistance = BMKMetersBetweenMapPoints(LocationPoint,
//                                                                                   trafficpoint.mappoint);    
//                
//                if (nextTrafficDistance < 2000.0) //和下一个拥堵点距离小于2000米就提示关键信息
//                {
//                    NSString *trafficInfoText = [[NSString alloc] initWithFormat:@"%@",   trfinfo.roadname];                            
//
//                    [self setTrafficBoardContent:trfinfo.roadname distance:nextTrafficDistance detail:trfinfo.detail];
//                    [self showTrafficBoard];
//
//                    NSLog(@"%@", trafficInfoText);
//                    
//                    //播放语音，每隔500M
//                    if (![runningDataset.trffTTSPlayRec ifRecorded:nextTrafficDistance stepIndex:trfinfo.stepIndex pointIndex:trfinfo.nextPointIndex])
//                    {
//                        [runningDataset.trffTTSPlayRec record:nextTrafficDistance stepIndex:trfinfo.stepIndex pointIndex:trfinfo.nextPointIndex];
//                        NSString *distanceStr;
//                        if (nextTrafficDistance > 1000.0)
//                        {
//                            distanceStr = [[NSString alloc] initWithFormat:@"%.1f公里", nextTrafficDistance/1000.0];
//                        }
//                        else
//                        {
//                            distanceStr  = [[NSString alloc] initWithFormat:@"%d米", (int)nextTrafficDistance];
//                        }
//                        
//                        //6.0对讯飞支持不好
//                        float verValue = runningDataset.deviceVersion.floatValue;
//                        if (verValue < 6.0)
//                        {
//                            NSString *strInfo = [[NSString alloc] initWithFormat:@"路况提示：前方约%@，%@，%@", distanceStr, trfinfo.roadname, trfinfo.detail];
//                            [mSynTTS addGuideStr:strInfo];
//                        }
//                    }
//                    
//                    //if (nextTrafficDistance)
//                }
//                else 
//                {
//                    [self hideTrafficBoard];
//                }
//            }
//            else 
//            {
//                [self hideTrafficBoard];
//            }
//        }
        
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
                
                //后续把播放语音挪到RePlanRouting中，和提示框一起
                //6.0对讯飞支持不好
                //float verValue = runningDataset.deviceVersion.floatValue;
                //if (verValue < 6.0)
                if (self.TTSSwitchOnOff == YES)
                {
                    [mSynTTS addEmegencyStr:@"您已经偏移路径，正在重新获取路况"];
                }
            }

        }
    }
    
}



-(void) mapView: (BMKMapView*)mapView didSelectAnnotationView:(BMKAnnotationView*) view
{
    mMapView.currentlySelectedAnnotation = view.annotation;
}

-(void) mapView: (BMKMapView*) mapView didDeselectAnnotationView: (BMKAnnotationView*) view
{
    mMapView.currentlySelectedAnnotation = nil;
    //NSLog(@"UnTouched Annotation****************");
}

-(void) mapView: (BMKMapView*) mapView annotationViewForBubble: (BMKAnnotationView*) view
{
    //NSLog(@"Bubble Selected");
    mMapView.currentlySelectedAnnotation = view.annotation;
}

#pragma mark -
#pragma mark - process View for Window

- (void) hideTopSearchBar
{
    [mTopSearchBar dismissKeyboard];
    [mTopSearchBar setHidden:YES];
    
    [self setSearchListHidden:YES];

    [self.showSearchBarBTN setHidden:NO];
}

- (void) showTopSearchBar
{
    [mTopSearchBar.uiInputTxtField setText:@""];
    [mTopSearchBar setHidden:NO];
    
    [self.showSearchBarBTN setHidden:YES];
}


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

//- (void) HomeSettingSuccuess
//{
//    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"家庭地址设置成功！" 
//                                                      delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
//    [alertView show];
//    [self didQuiteHomeSetting];
//    [self toHomeAddrReview];
//    [mSwipeBar toggle:NO];
//    
//    [self saveHomeData];
//    [mMapView removeAnnotation:pHomePointAnnotation];
//    
//    [self showButtonsOnMap];
//    
//    //获取上班路线；这个将触发-获取上班路线-获取下班路线-判断当前合适的路径等一系列动作
//    [self getH2ORoute];
//    //[self detectPath];
//}


- (void) saveSpeed:(CLLocationSpeed)speed startPoint:(CLLocationCoordinate2D) startpoint endPoint:(CLLocationCoordinate2D) endpoint
{
    NSString *strSpeed = [[NSString alloc] initWithFormat:@"%.2f", speed];
    NSString *stpt = [[NSString alloc] initWithFormat:@"%f, %f", startpoint.longitude, startpoint.latitude];
    NSString *edpt = [[NSString alloc] initWithFormat:@"%f, %f", endpoint.longitude, endpoint.latitude];

    NSArray *writearray = [NSArray arrayWithObjects: strSpeed, stpt, edpt, nil];

    [mSpeedSedList addObject:writearray];
}

- (void) saveHomeData
{
    NSString *strAddr = runningDataset.homeAddrInfo.address;
    NSString *HomeLat = [[NSString alloc] initWithFormat:@"%f",runningDataset.homeAddrInfo.pt.latitude];
    NSString *HomeLon = [[NSString alloc] initWithFormat:@"%f",runningDataset.homeAddrInfo.pt.longitude];
    
    NSArray *array = [NSArray arrayWithObjects:strAddr, HomeLat, HomeLon, nil];
    //Save
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    [saveDefaults setObject:array forKey:@"HomeAddrSaveKey"];
    [saveDefaults synchronize];
}

- (void) saveOfficeData
{
    NSString *strAddr = runningDataset.officeAddrInfo.address;
    NSString *addrLat = [[NSString alloc] initWithFormat:@"%f",runningDataset.officeAddrInfo.pt.latitude];
    NSString *addrLon = [[NSString alloc] initWithFormat:@"%f",runningDataset.officeAddrInfo.pt.longitude];
    
    NSArray *array = [NSArray arrayWithObjects:strAddr, addrLat, addrLon, nil];
    //Save
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    [saveDefaults setObject:array forKey:@"OfficeAddrSaveKey"];
    [saveDefaults synchronize];
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
	NSInteger height = hidden ? 0 : 125; //180
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];
	//[mSuggestionListVC.view setFrame:CGRectMake(mSuggestionListVC.view.frame.origin.x, mSuggestionListVC.view.frame.origin.y, 210, height)];
    [mSuggestionListVC.view setFrame:CGRectMake(mSuggestionListVC.view.frame.origin.x, mSuggestionListVC.view.frame.origin.y, 310, height)];
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
    mSuggestionListVC = [[RTTSuggestionListViewController alloc] initWithStyle:UITableViewStylePlain];
    mSuggestionListVC.delegate = self;
    [mSuggestionListVC.view setFrame:CGRectMake(5, 42, 0, 0)];
}



- (void) start2Go
{
    if(runningDataset && runningDataset.isPlaned)
    {
        runningDataset.isDriving = YES;
    }

    if (runningDataset.isRouteGuideON)
    {
        [self showGuideBoard];
    }
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
    RTTStepInfo *stepInfo = [RTTMapKit getStepInfoFromStepContent:content];
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

    [mModeIndicatorView.backgroundBoardVW setCenter:CGPointMake(160.0, 80.0)];
    
    //设置圆角
    [mModeIndicatorView.backgroundBoardVW.layer setCornerRadius:12.0f];
    
    //设置阴影
    mModeIndicatorView.backgroundBoardVW.layer.shadowColor = [[UIColor blackColor] CGColor];
    mModeIndicatorView.backgroundBoardVW.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    mModeIndicatorView.backgroundBoardVW.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    mModeIndicatorView.backgroundBoardVW.layer.shadowRadius = 10.0f; // 阴影发散的程度
    
    mActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [mModeIndicatorView addSubview: mActivityIndicatorView];

    [mActivityIndicatorView setCenter: CGPointMake(160, 92)] ;
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


-(void) initTopSearchBar
{
    
    mTopSearchBar = [[[NSBundle mainBundle] loadNibNamed:@"RTTSearchBar" owner:self options:nil] lastObject];
    [mTopSearchBar setCenter:CGPointMake(160.0, 20.0)];
    [mTopSearchBar setInputDelegate];
    [mTopSearchBar setDelegate:self];
    
    [[self view] addSubview:mTopSearchBar];
    
    //设置圆角
    //[mTrafficInfoBoard.layer setCornerRadius:12.0f];
    
    //设置阴影
    mTopSearchBar.layer.shadowColor = [[UIColor blackColor] CGColor];
    mTopSearchBar.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    mTopSearchBar.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    mTopSearchBar.layer.shadowRadius = 10.0f; // 阴影发散的程度
    
    [mTopSearchBar setHidden:YES];
}


- (void) initDestinationLBL
{
    UIColor *bgColor = [[UIColor alloc] initWithRed:0.4 green:0.4 blue:0.4 alpha:0.4];
    self.uiDestinationLBL.layer.backgroundColor = [bgColor CGColor];
    
    [self.uiDestinationLBL.layer setCornerRadius:4.0f];

    self.uiDestinationLBL.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.uiDestinationLBL.layer.shadowOffset = CGSizeMake(3.0f, 3.0f); // [水平偏移，垂直偏移]
    self.uiDestinationLBL.layer.shadowOpacity = 0.5f; // 0.0 ~ 1.0的值
    self.uiDestinationLBL.layer.shadowRadius = 5.0f; // 阴影发散的程度
    
}

- (void) hideDestinationLBL
{
    [self.uiDestinationLBL setHidden:YES];
    
}

- (void) showDestinationLBL
{
    [self.uiDestinationLBL setHidden:NO];
    
}


- (void) setDestinationTrafficSegCnt:(int) segCount
{
    if (runningDataset.isPlaned == NO)
    {
        [self.uiDestinationLBL setText:@"无路线/路线的路况信息"];
        return;
    }
    
    if (segCount > 0)
    {
    NSString *strLable = [[NSString alloc] initWithFormat:@"%@ 拥堵路段: %d",  self.currentlyRouteEndAddr , segCount ];
    [self.uiDestinationLBL setText:strLable];
    }
    else
    {
        NSString *strLable = [[NSString alloc] initWithFormat:@"%@ 全线无拥堵",  self.currentlyRouteEndAddr];
        [self.uiDestinationLBL setText:strLable];
    }
}

#pragma mark -
#pragma mark Process Receive Traffic

- (void) formatAndSaveTrafficData4Route:(LYCityTraffic*) trafficinfo
{
    [runningDataset.trafficContainer clearOutofDateTrafficData4Route];//先清理超时的路况信息
    
    for (LYRoadTraffic *pRdTrc in trafficinfo.roadTrafficsList)
    {
        for (LYSegmentTraffic *pSegTrf in pRdTrc.segmentTrafficsList)
        {
                        
            //[self addTSSTraffic2RunningDataset4Route:pRdTrc.road segment:pSegTrf];
          NSMutableArray *retMatchedTrfList =
            [runningDataset.trafficContainer addTSSTraffic2RunningDataset4Route:pRdTrc.road segment:pSegTrf roadList:runningDataset.formatedRouteInfo.roadlist];
            
            if (self.TTSSwitchOnOff == YES)
            {
                for (RttGMatchedTrafficInfo *trfSeg in retMatchedTrfList)
                {
                    NSString *strSpeed;
                    if (trfSeg.speedKMPH < 5)
                    {
                        strSpeed = @"严重拥堵";
                    }
                    else
                    {
                        if (trfSeg.speedKMPH < 15)
                        {
                            strSpeed = @"中度拥堵";
                        }
                        else
                        {
                            strSpeed = @"轻度拥堵";
                        }
                    }
                    
                    NSString *strInfo = [[NSString alloc] initWithFormat:@"最新路况：%@，%@，%@", trfSeg.roadname, trfSeg.detail, strSpeed];
                    [mSynTTS addTrafficStr:strInfo];
                }
            }

        }
    }
    
    [mMapView DrawTrafficPolyline:runningDataset.trafficContainer.filteredRouteTrafficList];
}


- (void) formatAndSaveTrafficData4Hot:(LYCityTraffic*) trafficinfo
{
    [runningDataset.trafficContainer clearOutofDateTrafficData4Hot];//先清理超时的路况信息
    
    for (LYRoadTraffic *pRdTrc in trafficinfo.roadTrafficsList)
    {
        for (LYSegmentTraffic *pSegTrf in pRdTrc.segmentTrafficsList)
        {
            [runningDataset.trafficContainer addTSSTraffic2RunningDataset4Hot:pRdTrc.road segment:pSegTrf];
        }
    }
    
    //[mMapView DrawTrafficPolyline:runningDataset.trafficContainer.filteredRouteTrafficList];
}





#pragma mark -
#pragma mark Process View Delegate for Map

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
                    [pinView setSelected:YES];
                    mMapView.currentlySelectedAnnotation = pointAnnotation;
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


- (bool) RouteSearch:(CLLocationCoordinate2D)startpoint end:(CLLocationCoordinate2D)endpoint
{
    NSLog(@"RoutPlaning.....");
    
    self.currentlyRouteEndPoint = endpoint;
    
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
//        runningDataset.currentlyRoute = ROUTECODEUNKNOW;
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
    bool ret = [self RouteSearch:point1 end:point2];
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
    bool ret = [self RouteSearch:point1 end:point2];
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
#warning 暂时去掉
//    //获取起点描述信息，因为百度API如果起点在路上，Step信息可能是是没有这条路的路名的；
//    mMapView.pWaitPOIResultAnnotation = mMapView.pStartPointAnnotation;
//    [self getGeoInfofromMAPSVR:location];

    [self doRoutePlaning:location end:self.currentlyRouteEndPoint];
    //[self CheckPointsSettingCompleted:NO];
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
        
        NSString *strObj = [RTTMapKit getRoadNameFromStepContent:step.content];
        
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
        
        NSString *strObj = [RTTMapKit getRoadNameFromStepContent:step.content];
        
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




- (void) doRoutePlaning:(CLLocationCoordinate2D)startpoint end:(CLLocationCoordinate2D)endpoint
{
        bool ret = [self RouteSearch:startpoint end:endpoint];
        if (!ret)
        {
            NSLog(@"Route Planing Fail!");
        }
        else {
            [self showModeIndicator:@"路况获取中" seconds:10];
            [self setRunningActivityTimer:10 activity:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
        }
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
            {[tssRouteBuild setIdentity:ROUTECODETEMPROUTE];}
                break;
                
            case RTTEN_ACTIVITYTYPE_GETTINGH2OROUTE:
            {[tssRouteBuild setIdentity:ROUTECODEGOTOOFFICE];}
                break;
                
            case RTTEN_ACTIVITYTYPE_GETTINGO2HROUTE:
            {[tssRouteBuild setIdentity:ROUTECODEGOHOME];}
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
        NSLog(@"Sending request 2 TSS------------");
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
                NSLog(@"***************Route ID=%d", recvPackage.trafficPub.routeId);
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
    
#warning 编码调试中...............
    switch (trafficPubPackage.routeId)
    {
        case TRAFFICTYPEHOT:
        {
            [self formatAndSaveTrafficData4Hot:pTrafficInfo];
        }
            break;
            
        case TRAFFICTYPEOFFICE:
        {
            //[self formatAndSaveTrafficData4Route:pTrafficInfo];

        }
            break;

        case TRAFFICTYPEHOME:
        {
            //[self formatAndSaveTrafficData4Route:pTrafficInfo];

        }
            break;

        case TRAFFICTYPETEMP:
        {
            [self formatAndSaveTrafficData4Route:pTrafficInfo];
        }
            break;
            
        default:
        {
            //
        }
            break;
    }
    
    [self CheckAndUpdateTrafficListView];
    [self setDestinationTrafficSegCnt:runningDataset.trafficContainer.filteredRouteTrafficList.count];

    
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
            [pTrafficCtrl getDatasourceFromRunningDataSet];
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
        if (runningDataset.currentlyRoute != ROUTECODEGOTOOFFICE)
        {
            //re-planing
            NSLog(@"Replaning to Office");
            [self routePlanCurLoctoOffice];
            runningDataset.currentlyRoute = ROUTECODEGOTOOFFICE;
        }
        else {
            if (runningDataset.isPlaned)
            {
                //update_traffic
                [self sendRouteInfo2TSS:runningDataset.formatedRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
            }
            else {
                [self routePlanCurLoctoOffice];
                runningDataset.currentlyRoute = ROUTECODEGOTOOFFICE;
            }
        }
    }
    else //下班
    {
        if (runningDataset.currentlyRoute != ROUTECODEGOHOME)
        {
            //re-planing
            [self routePlanCurLoctoHome];
            runningDataset.currentlyRoute = ROUTECODEGOHOME;
        }
        else {
            if (runningDataset.isPlaned)
            {
            //update_traffic
            [self sendRouteInfo2TSS:runningDataset.formatedRouteInfo type:RTTEN_ACTIVITYTYPE_GETTINGROUTE];
            }
            else {
                //re-planing
                [self routePlanCurLoctoHome];
                runningDataset.currentlyRoute = ROUTECODEGOHOME;
            }
        }
    }
    
    
    return -1;
}


- (void) routePlantoOffice
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"公司地址未设置");
        return;
    }
    
    [self doRoutePlaning:runningDataset.homeAddrInfo.pt  end:runningDataset.officeAddrInfo.pt];

}

- (void) routePlantoHome
{
    if (runningDataset.homeAddrInfo == nil)
    {
        NSLog(@"家庭地址未设置");
        return;
    }
    
    [self doRoutePlaning:runningDataset.officeAddrInfo.pt  end:runningDataset.homeAddrInfo.pt];
}

- (void) routePlanCurLoctoHome
{    
    if (runningDataset.homeAddrInfo == nil)
    {
        //NSLog(@"家庭地址未设置\n请通过搜索或者长按地图上对应的地址进行设置");
        return;
    }
    [mSwipeBar toggle:NO];

    
    self.currentlyRouteEndAddr = @"回家路况";
    CLLocationCoordinate2D curLoc =  [mMapView getCurLocation];
    [self doRoutePlaning:curLoc  end:runningDataset.homeAddrInfo.pt];

    
}

- (void) routePlanCurLoctoOffice
{
    if (runningDataset.officeAddrInfo == nil)
    {
        //NSLog(@"办公室地址未设置\n请通过搜索或者长按地图上对应的地址进行设置");
        return;
    }
    [mSwipeBar toggle:NO];
    
    self.currentlyRouteEndAddr = @"上班路况";
    CLLocationCoordinate2D curLoc =  [mMapView getCurLocation];
    [self doRoutePlaning:curLoc  end:runningDataset.officeAddrInfo.pt];
}

- (void) routePlanCurLoctoTemp:(CLLocationCoordinate2D) endLoc
{
    CLLocationCoordinate2D curLoc =  [mMapView getCurLocation];
    [self doRoutePlaning:curLoc  end:endLoc];
}

@end
