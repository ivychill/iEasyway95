//
//  RTTRouteBookmarkViewController.m
//  Easyway
//
//  Created by Ye Sean on 12-8-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RTTRouteBookmarkViewController.h"
#import "RTTRunningDataSet.h"

@interface RTTRouteBookmarkViewController ()

@end

@implementation RTTRouteBookmarkViewController

@synthesize runtimeDataset;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
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
    int historyPathCnt = runtimeDataset.historyPathInfoList.count;
    return historyPathCnt;
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
    
    int iPathCnt = runtimeDataset.historyPathInfoList.count;
    
    if (indexPath.row < iPathCnt)
    {
        RttGHistoryPathInfo *pathInfo = [runtimeDataset.historyPathInfoList objectAtIndex:(indexPath.row)];
        
        NSString * plusAddr1 = [[NSString alloc] init];
        if (pathInfo.startPointInfo.poiList.count > 0)
        {
            BMKPoiInfo * poiInfo = [pathInfo.startPointInfo.poiList objectAtIndex:0];
            plusAddr1 = poiInfo.name;
        }
        
        NSString * plusAddr2 = [[NSString alloc] init];
        if (pathInfo.endPointInfo.poiList.count > 0)
        {
            BMKPoiInfo * poiInfo = [pathInfo.endPointInfo.poiList objectAtIndex:0];
            plusAddr2 = poiInfo.name;
        }
        
        NSString *detailAddr = [[NSString alloc] initWithFormat:@"%@-%@",plusAddr1, plusAddr2];
        [[cell textLabel] setText:pathInfo.pathName];
        [[cell detailTextLabel] setText:detailAddr];
    }
    

    return cell;
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
    int iPathCnt = runtimeDataset.historyPathInfoList.count;
    
    if (indexPath.row < iPathCnt)
    {
        __autoreleasing RttGHistoryPathInfo *pathInfo = [runtimeDataset.historyPathInfoList objectAtIndex:(indexPath.row)];
        if (self.delegate != nil)
        {
            [self.delegate performSelector:@selector(didBookmarkPathSelected:) withObject:pathInfo];
        }
        [self.navigationController popViewControllerAnimated:YES];
        
        //[delegate didHistoryPathSelected:pathInfo];
    }
}

@end
