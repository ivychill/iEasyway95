//
//  RTTRoutePreviewViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTRoutePreviewViewController.h"
#import "RTTRunningDataSet.h"
#import "BMapKit.h"
#import "RTTMapView.h"


@interface RTTRoutePreviewViewController ()

@end

@implementation RTTRoutePreviewViewController
@synthesize stepListTBL;
@synthesize pathMapView;
@synthesize pCurrentlyPolyLine;
@synthesize runtimeDataset;


#pragma mark -
#pragma mark init and process view
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    pathMapView.delegate = self;

    [[self.navigationItem rightBarButtonItem] setEnabled:YES];
    [self.navigationItem setTitle:@"路线预览"];
    UIBarButtonItem *bookmarkButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"增加到书签" 
                                   style:UIBarButtonItemStylePlain 
                                   target:self
                                   action:@selector(didAdd2Bookmark:)];
    self.navigationItem.rightBarButtonItem = bookmarkButton;

    [self AddDrivingRouteOverlay:runtimeDataset.drivingRoute];
}

- (void)viewDidUnload
{
    [self setStepListTBL:nil];
    [self setPathMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)viewWillDisappear:(BOOL)animated
{
    [pathMapView removeFromSuperview];
    pathMapView = nil;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //int historyPathCnt = runtimeDataset.historyPathInfoList.count;
    int stepCnt = runtimeDataset.drivingRoute.steps.count;
    
    return stepCnt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        //cell.accessoryType=UITableViewCellAccessoryDetailDisclosureButton;
        
    }
    
    int stepCnt = runtimeDataset.drivingRoute.steps.count;
    
    if (indexPath.row <= stepCnt)
    {
        BMKStep *stepInfo = [runtimeDataset.drivingRoute.steps objectAtIndex:(indexPath.row)];
        
        [[cell textLabel] setText:stepInfo.content];
    }
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int stepCnt = runtimeDataset.drivingRoute.steps.count;
    
    if (indexPath.row < stepCnt)
    {
        //BMKStep *stepInfo = [runtimeDataset.drivingRoute.steps objectAtIndex:(indexPath.row)];
        [self AddDrivingRouteOverlay:runtimeDataset.drivingRoute withIndex:indexPath.row+1];
    }
    
}

#pragma mark -
#pragma mark Add to Bookmark
- (IBAction)didAdd2Bookmark:(id)sender 
{
    
    //    NSString *StrProv1 = runningDataset.startPointInfo.addressComponent.province;
    //    NSString *StrCity1 = runningDataset.startPointInfo.addressComponent.city;
    //    NSString *StrDist1 = runningDataset.startPointInfo.addressComponent.district;
    NSString *StrRoad1 = runtimeDataset.startPointInfo.addressComponent.streetName;
    if (StrRoad1 == nil) {
        StrRoad1 = @"未知道路";
    }
    NSString * plusAddr1 = [[NSString alloc] init];
    if (runtimeDataset.startPointInfo.poiList.count > 0)
    {
        BMKPoiInfo * poiInfo = [runtimeDataset.startPointInfo.poiList objectAtIndex:0];
        plusAddr1 = poiInfo.address;
    }
    
    
    //    NSString *StrProv2 = runningDataset.endPointInfo.addressComponent.province;
    //    NSString *StrCity2 = runningDataset.endPointInfo.addressComponent.city;
    //    NSString *StrDist2 = runningDataset.endPointInfo.addressComponent.district;
    NSString *StrRoad2 = runtimeDataset.endPointInfo.addressComponent.streetName;
    if (StrRoad2 == nil) {
        StrRoad2 = @"未知道路";
    }
    NSString * plusAddr2 = [[NSString alloc] init];
    if (runtimeDataset.endPointInfo.poiList.count > 0)
    {
        BMKPoiInfo * poiInfo = [runtimeDataset.endPointInfo.poiList objectAtIndex:0];
        plusAddr2 = poiInfo.address;
    }
    
    //    NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"%@%@%@%@%@-%@%@%@%@%@", 
    //                                 StrProv1, StrCity1,StrDist1,StrRoad1,plusAddr1,
    //                                 StrProv2, StrCity2,StrDist2,StrRoad2,plusAddr2];
    //NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"%@%@-%@%@", StrRoad1,plusAddr1, StrRoad2,plusAddr2];
    NSString *StrFormatedInfo = [[NSString alloc] initWithFormat:@"%@-%@", StrRoad1, StrRoad2];
    NSLog(@"---------Path Saved: %@", StrFormatedInfo);
    
    
    RttGHistoryPathInfo *pathInfo = [[RttGHistoryPathInfo alloc] init];
    pathInfo.startPointInfo = runtimeDataset.startPointInfo;
    pathInfo.endPointInfo = runtimeDataset.endPointInfo;
    pathInfo.pathName = StrFormatedInfo;
    
    [runtimeDataset.historyPathInfoList addObject:pathInfo];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    //self.navigationItem.rightBarButtonItem = nil; 
}

//- (BOOL)navigationBar:(UINavigationBar *)navigationBar
//        shouldPopItem:(UINavigationItem *)item{
//    //在此处添加点击back按钮之后的操作代码 
//    return FALSE;
//}

#pragma mark -
#pragma mark - process Map View
- (void) AddDrivingRouteOverlay:(BMKRoute*) route withIndex:(int) stepIndex;
{
    
    
    int iRoutePointCnt = [route getPointsNum:stepIndex];
    NSLog(@"Points Cnt in Steps: %d", iRoutePointCnt);
    if (iRoutePointCnt <= 0)
    {
        return;
    }
    
    //DrivingRoute = route;//[plan.routes objectAtIndex:i];
    BMKMapPoint* points = new BMKMapPoint[iRoutePointCnt];
    
    BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:stepIndex];
    memcpy(points, pointArray, iRoutePointCnt * sizeof(BMKMapPoint));
    
    if (pCurrentlyPolyLine)
    {
        [pathMapView removeOverlay:pCurrentlyPolyLine];
        pCurrentlyPolyLine = nil;
    }
    //在地图上画出规划的路线
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:iRoutePointCnt];
    polyLine.title = @"GuideLine";
    [pathMapView addOverlay:polyLine];
    
    pCurrentlyPolyLine = polyLine; 
    
    [pathMapView setCenterCoordinate:(BMKCoordinateForMapPoint(points[0]))];
    
    
    BMKMapRect segRect = [self mapRectMakeFromPoint:&points[0] withPoint:(&points[iRoutePointCnt-1])]; 
    UIEdgeInsets edgeFrame={10,10,10,10};
    BMKMapRect fitRect = [pathMapView mapRectThatFits:segRect edgePadding:(edgeFrame)];
    [pathMapView setVisibleMapRect:fitRect animated:NO];
    
    delete []points;
    
}

- (void) AddDrivingRouteOverlay:(BMKRoute*) route
{
    int iRoutePointCnt = 0; //路径上所有坐标点的个数

    for (int j = 0; j < route.pointsCount; j++) 
    {
        int len = [route getPointsNum:j];
        iRoutePointCnt += len;
    }
    if (iRoutePointCnt <= 0)
    {
        return;
    }
    
    
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
        [pathMapView removeOverlay:pCurrentlyPolyLine];
        pCurrentlyPolyLine = nil;
    }
    //在地图上画出规划的路线
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:iRoutePointCnt];
    polyLine.title = @"Route";
    [pathMapView addOverlay:polyLine];
    
    //pCurrentlyPolyLine = polyLine; 
    [pathMapView setCenterCoordinate:(BMKCoordinateForMapPoint(points[0]))];
    
    
    BMKMapRect segRect = [self mapRectMakeFromPoint:&points[0] withPoint:(&points[iRoutePointCnt-1])];  
    UIEdgeInsets edgeFrame={10,10,10,10};
    BMKMapRect fitRect = [pathMapView mapRectThatFits:segRect edgePadding:edgeFrame];
    [pathMapView setVisibleMapRect:fitRect animated:YES];
    
    delete []points;
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


- (BMKOverlayView*)mapView:(BMKMapView *)bmkmapview viewForOverlay:(id<BMKOverlay>)overlay
{	
    
	if ([overlay isKindOfClass:[BMKPolyline class]]) 
    {
        BMKPolylineView* polylineView = [ [BMKPolylineView alloc] initWithOverlay:overlay];// autorelease];
        if ([overlay.title isEqualToString:@"GuideLine"])
        {
            polylineView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:1];
            polylineView.strokeColor = [[UIColor redColor] colorWithAlphaComponent:1.0];
            polylineView.lineWidth = 5.0;
            polylineView.alpha = 1.0;
            
            //NSLog(@"**************Drawing Traffic Overlay************");
        }
        else if([overlay.title isEqualToString:@"Route"])
        {
            polylineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:1];
            polylineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
            polylineView.lineWidth = 5.0;
            polylineView.alpha = 0.8;
            
            //NSLog(@"**************Drawing Routing Overlay************");
            
        }
        else 
        {
            polylineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:1];
            polylineView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.7];
            polylineView.lineWidth = 2;
            polylineView.alpha = 1;
            
            //NSLog(@"**************Drawing Test Overlay************");
            
        }
        return polylineView;
    }
	return nil;
}



@end
