//
//  RTTTrafficListViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTTrafficListViewController.h"
#import "RTTRunningDataSet.h"

#pragma mark -
#pragma mark - Road Traffic Info Stuct
@interface RoadTrafficInfo()

@end
@implementation RoadTrafficInfo

@synthesize roadName;
@synthesize trafficDetail;
@synthesize timestamp;

@end


#pragma mark -
#pragma mark - View Controler and Data Source
@interface RTTTrafficListViewController ()

@end

@implementation RTTTrafficListViewController
@synthesize trafficListTBL;
@synthesize runtimeDataset;
@synthesize isShowAllTraffic;
@synthesize setmentCTRL;

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
    mIsShowAllTraffic = isShowAllTraffic;
    if (isShowAllTraffic)
    {
        [setmentCTRL setSelectedSegmentIndex:1];
    }
    [self getDatasourceFromRunningDataSet];
    [self.navigationItem setTitle:@"拥堵路段列表"];
}

- (void)viewDidUnload
{
    [self setTrafficListTBL:nil];
    [self setSetmentCTRL:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    int iTrfSegCnt = 0;
    if (!mIsShowAllTraffic)
    {
        iTrfSegCnt = runtimeDataset.trafficContainer.filteredRouteTrafficList.count;
    }
    else 
    {
//        TSS_CityTraffic *pTrafficInfo = self.runtimeDataset.cityTraffic4Me;
//        iTrfSegCnt = pTrafficInfo.roadtrafficList.count;
        
        iTrfSegCnt = trafficArray.count;

    }
    return iTrfSegCnt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TrafficRoadSeg";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell)
    {
        //cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];//
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    
    [[cell detailTextLabel] setNumberOfLines:2];
    [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
    
    int iSegCnt = 0;//runtimeDataset.filteredRouteTrafficList.count;
    
    if (!mIsShowAllTraffic)
    {
        iSegCnt = runtimeDataset.trafficContainer.filteredRouteTrafficList.count;
        if (indexPath.row < iSegCnt)
        {
            
            RttGMatchedTrafficInfo *ptrfInfo = [runtimeDataset.trafficContainer.filteredRouteTrafficList objectAtIndex:indexPath.row];
            if (ptrfInfo)
            {
                //NSString *cellString = ptrfInfo.roadname;
                
                NSString *strSpeed;
                if (ptrfInfo.speedKMPH < 5)
                {
                    strSpeed = @"严重拥堵";
                }
                else
                {
                    if (ptrfInfo.speedKMPH < 15)
                    {
                        strSpeed = @"中度拥堵";
                    }
                    else
                    {
                        strSpeed = @"轻度拥堵";
                    }
                }

                NSString *cellString = [[NSString alloc] initWithFormat:@"%@-%@ (%@)", ptrfInfo.roadname, strSpeed, [self getTimeInterner:ptrfInfo.timeStamp]];

                [[cell textLabel] setText:cellString];
                [[cell detailTextLabel] setText:ptrfInfo.detail];
                //[[cell detailTextLabel] sizeToFit];
            }
        }
    }
    else 
    {
//        NSString *mainTitle = [[NSString alloc] initWithFormat:@"%@——%@", [[trafficArray objectAtIndex:indexPath.row] roadName], [self getTimeInterner:[[trafficArray objectAtIndex:indexPath.row] timeStamp]]];

        if (indexPath.row < trafficArray.count)
        {
            NSString *roadName = [[trafficArray objectAtIndex:indexPath.row] roadName];
            NSString *timeInter = [self getTimeInterner:([(RoadTrafficInfo*)[trafficArray objectAtIndex:indexPath.row] timestamp])];
            
            NSString *mainTitle = [[NSString alloc] initWithFormat:@"%@ (%@)", roadName, timeInter];
            
            //NSString *mainTitle = [[trafficArray objectAtIndex:indexPath.row] roadName];
            NSString *detailTxt = [[trafficArray objectAtIndex:indexPath.row] trafficDetail];
            
            [[cell textLabel] setText:mainTitle];
            [[cell detailTextLabel] setText:detailTxt];
        }
        else
        {
            //NSLog(@"####Out of trafficArray.count; TrafficList####");
        }
        
    }
        
    return cell;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)didSegmentChange:(id)sender 
{
    UISegmentedControl* control = (UISegmentedControl*)sender;  
    switch (control.selectedSegmentIndex) 
    {  
        case 0:  
        {
            mIsShowAllTraffic = NO;
        }; 
            break;
        case 1:  
        {
            mIsShowAllTraffic = YES;
            [self reloadInputViews];
        }; 
            break;  
        default:  
            break;  
    }  
    [trafficListTBL reloadData];


}


- (void) getDatasourceFromRunningDataSet
{
    if (trafficArray == nil)
    {
        trafficArray = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    [trafficArray removeAllObjects];
    
    
    for (RTTFormatedTrafficFromTSS *trafficList in self.runtimeDataset.trafficContainer.routeTrafficFromTSS)
    {
        RoadTrafficInfo *trafficInfoItem = [[RoadTrafficInfo alloc] init];
        //trafficInfoItem.roadName = trafficList.roadName;
        NSString *strSpeed;
        if (trafficList.speedKMPH < 5)
        {
            strSpeed = @"严重拥堵";
        }
        else
        {
            if (trafficList.speedKMPH < 15)
            {
                strSpeed = @"中度拥堵";
            }
            else
            {
                strSpeed = @"轻度拥堵";
            }
        }
        
        trafficInfoItem.roadName = [[NSString alloc] initWithFormat:@"%@-%@", trafficList.roadName, strSpeed];

        trafficInfoItem.trafficDetail = trafficList.details;
        trafficInfoItem.timestamp = trafficList.timestamp;
        
        [trafficArray addObject:trafficInfoItem];
    }
    

    for (RTTFormatedTrafficFromTSS *trafficList in self.runtimeDataset.trafficContainer.hotTrafficFromTSS)
    {
        RoadTrafficInfo *trafficInfoItem = [[RoadTrafficInfo alloc] init];
        
        NSString *strSpeed;
        if (trafficList.speedKMPH < 5)
        {
            strSpeed = @"严重拥堵";
        }
        else
        {
            if (trafficList.speedKMPH < 15)
            {
                strSpeed = @"中度拥堵";
            }
            else
            {
                strSpeed = @"轻度拥堵";
            }
        }
        
        trafficInfoItem.roadName = [[NSString alloc] initWithFormat:@"%@-%@", trafficList.roadName, strSpeed];

        trafficInfoItem.trafficDetail = trafficList.details;
        trafficInfoItem.timestamp = trafficList.timestamp;
        
        [trafficArray addObject:trafficInfoItem];
    }
}

- (NSString*) getTimeInterner:(TimeValue64) timestamp
{
    NSDate *segDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSTimeInterval secondsBetweenNow =  [segDate timeIntervalSinceNow];
    __autoreleasing NSString *strTimeInterner;
    if (secondsBetweenNow <= -3600.0) //超过一个小时
    {
        strTimeInterner = [[NSString alloc] initWithFormat:@"%.1f小时前", fabs((double)secondsBetweenNow/3600.0)];
    }
    else if (secondsBetweenNow <= 0.0)
    {
        strTimeInterner = [[NSString alloc] initWithFormat:@"%d分钟前", abs((int)(secondsBetweenNow/60))];
    }
    
    return strTimeInterner;
}




@end



