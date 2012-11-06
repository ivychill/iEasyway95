//
//  RTTAppDelegate.m
//  Easyway
//
//  Created by Ye Sean on 12-8-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTAppDelegate.h"

#import "RTTViewController.h"

@implementation RTTAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
//    self.viewController = [[RTTViewController alloc] initWithNibName:@"RTTViewController" bundle:nil];
//    self.window.rootViewController = self.viewController;
    
    


    
    //百度地图初始化代码
    // 要使用百度地图,请先启动 BaiduMapManager
    _mapManager = [[BMKMapManager alloc]init];
    
    // 如果要关注网络及授权验证事件,请设定 generalDelegate 参数
    BOOL ret = [_mapManager start:@"513CBE299AB953DDFAEBC4A608F1F6557C30D685" generalDelegate:nil];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
//    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"输入为空，请输入要查找的地址"
//                                                      delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
//    [alertView show];
//
//    return NO;
    
    //    // Add the navigation controller's view to the window and display.
    //    [self.window addSubview:navigationController.view]; 
    //    [self.window makeKeyAndVisible]; 
    //End of 百度地图初始化代码
    
    RTTViewController *rootView = [[RTTViewController alloc] initWithNibName:@"RTTViewController" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:rootView]; 
    [self.window addSubview:navigationController.view];
    self.navigationController.delegate = self;
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];//UIBarStyleBlackTranslucent];
    self.viewController = rootView;
    //self.window.rootViewController = self.viewController;
    
    //设置屏幕常亮
    [ [ UIApplication sharedApplication] setIdleTimerDisabled:YES ] ;
    
    //ANPS注册和设置
    //启动后目前把图标上的数字先去掉
    application.applicationIconBadgeNumber = 0;
    
    //Load if successed registerted to APS tag Info
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
#warning 目前没有应答，暂时使用SendedDevice2TSS来判断是否重复获取Token并在返回函数中发送；
    //NSString *tagStr = [saveDefaults objectForKey:@"IsSuccessRegAPS"];
    NSString *tagStr = [saveDefaults objectForKey:@"SendedDevice2TSS"];
    if ([tagStr isEqualToString:@"YES"])
    {
        NSLog(@"Have success saved registered device ID");
        
    }
    else 
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge
                                                                               | UIRemoteNotificationTypeSound 
                                                                               | UIRemoteNotificationTypeAlert)];     
    }
    
    
    [self.window makeKeyAndVisible];
    
    
//    //如果是点击Push消息启动的，直接进入路况显示界面
//    UILocalNotification *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//    if (remoteNotif)
//    {
//        NSLog(@"have remote options---");
//        [self.viewController didShowTraffic:nil];
//    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"applicationWillResignActive....................................");

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground....................................");

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground....................................");
    

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"Active....................................");

    [self.viewController detectPath];
    if (application.applicationIconBadgeNumber > 0)
    {
        application.applicationIconBadgeNumber = 0;
        //[self.viewController didShowTraffic:nil];
    }
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)navigationController:(UINavigationController *)pnavigationController willShowViewController:(UIViewController *)pviewController animated:(BOOL)animated {  
    if ( pviewController ==  self.viewController) {  
        [pnavigationController setNavigationBarHidden:YES animated:animated];  
    } else if ( [pnavigationController isNavigationBarHidden] ) {  
        [pnavigationController setNavigationBarHidden:NO animated:animated];  
    }  
}  


//注册ANPS的回调方法
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken 
{   
    NSLog(@"deviceToken: %@", deviceToken);
    NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
    [saveDefaults setObject:@"YES" forKey:@"IsSuccessRegAPS"];
    [saveDefaults setObject:deviceToken forKey:@"DeviceToken"];
    [saveDefaults synchronize];
    
    if ([self.viewController sendDeviceInfo2TSS:deviceToken])
    {
        NSLog(@"Success call send device token to TSS");
#warning 目前暂时屏蔽发送成功记录
        //[saveDefaults setObject:@"YES" forKey:@"SendedDevice2TSS"];
    }
}

//注册失败
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error 
{       
    NSLog(@"Error in registration. Error: %@", error);   
}   



//收到通知消息
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo   
{
    
    application.applicationIconBadgeNumber = 0;

    //如果是点击Push消息启动的，直接进入路况显示界面
    if (application.applicationState == UIApplicationStateInactive)
    {
        NSLog(@"have remote notification --- inactive");
        [self.viewController didShowTraffic:nil];
    }
    else
    {
        NSLog(@"have remote notification --- active");
    }
    
//    NSLog(@" 收到推送消息 ： %@",[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]);
//    if ([[userInfo objectForKey:@"aps"] objectForKey:@"alert"]!=NULL) 
//    {   
//        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"推送通知"   
//                                                        message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]   
//                                                       delegate:self   
//                                              cancelButtonTitle:@" 关闭"   
//                                              otherButtonTitles:@" 更新状态",nil];   
//        [alert show];   
//    }   
}


-(void) alertNotice:(NSString *)title withMSG:(NSString *)msg cancleButtonTitle:(NSString *)cancleTitle otherButtonTitle:(NSString *)otherTitle{
    UIAlertView *alert;
    if([otherTitle isEqualToString:@""])
        alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancleTitle otherButtonTitles:nil,nil];
    else
        alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancleTitle otherButtonTitles:otherTitle,nil];
    [alert show];
    
}



@end
