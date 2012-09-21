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
    //[self.navigationItem setTitle:@"拥堵路段列表"];
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
        iTrfSegCnt = runtimeDataset.trafficInfoList.count;
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
    
    int iSegCnt = 0;//runtimeDataset.trafficInfoList.count;
    
    if (!mIsShowAllTraffic)
    {
        iSegCnt = runtimeDataset.trafficInfoList.count;
        if (indexPath.row < iSegCnt)
        {
            
            RttGTrafficInfo *ptrfInfo = [runtimeDataset.trafficInfoList objectAtIndex:indexPath.row];
            if (ptrfInfo)
            {
                NSString *cellString = ptrfInfo.roadname;
                [[cell textLabel] setText:cellString];
                [[cell detailTextLabel] setText:ptrfInfo.detail];
                //[[cell detailTextLabel] sizeToFit];
            }
        }
    }
    else 
    {
        NSString *mainTitle = [[trafficArray objectAtIndex:indexPath.row] roadName];
        NSString *detailTxt = [[trafficArray objectAtIndex:indexPath.row] trafficDetail];

        [[cell textLabel] setText:mainTitle];
        [[cell detailTextLabel] setText:detailTxt];
        
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
    trafficArray = [[NSMutableArray alloc] initWithCapacity:10];
    
    TSSCityTraffic *pTrafficInfo = self.runtimeDataset.cityTraffic4Me;
    TSSRoadTraffic *pRdTrc;
    int roaddCnt = pTrafficInfo.roadTrafficsList.count;
    
    
    for (int i = 0; i < roaddCnt; i++)
    {
        pRdTrc = [pTrafficInfo.roadTrafficsList objectAtIndex:i];
        int segCnt= pRdTrc.segmentTrafficsList.count;
        
        if (segCnt > 0)
        {
            for (int j = 0; j < segCnt; j++)
            {
                TSSSegmentTraffic *pSegTrf = [pRdTrc.segmentTrafficsList objectAtIndex:j];

                RoadTrafficInfo *trafficInfoItem = [[RoadTrafficInfo alloc] init];
                trafficInfoItem.roadName = pRdTrc.road;
                trafficInfoItem.trafficDetail = pSegTrf.details;
                
                [trafficArray addObject:trafficInfoItem];
            }
        }
        else 
        {
            RoadTrafficInfo *trafficInfoItem = [[RoadTrafficInfo alloc] init];
            trafficInfoItem.roadName = pRdTrc.road;
            if ((pRdTrc.desc == nil) || (pRdTrc.desc == @""))
            {
                trafficInfoItem.trafficDetail = @"目前无拥堵信息";
            }
            else {
                trafficInfoItem.trafficDetail = pRdTrc.desc;
            }
            
            [trafficArray addObject:trafficInfoItem];
        }
    }

}




@end


