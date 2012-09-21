//
//  RttGSettingRoutePointViewController.h
//  RTTGUIDE
//
//  Created by Ye Sean on 12-7-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RttGDLTViewControler.h"
#import <QuartzCore/QuartzCore.h>
//#import "PassValueDelegate.h"


@implementation RttGDLTViewControler

@synthesize _searchText, _selectedText, _resultList, _delegate;


- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	self.tableView.layer.borderWidth = 1;
	self.tableView.layer.borderColor = [[UIColor blackColor] CGColor];

	_searchText = nil;
	_selectedText = nil;
	_resultList = [[NSMutableArray alloc] initWithCapacity:5];
	
}

- (void)updateData 
{
//	[_resultList removeAllObjects];
//	[_resultList addObject:_searchText];
//	for (int i = 1; i<10; i++) 
//    {
//		[_resultList addObject:[NSString stringWithFormat:@"%@%d",_searchText,i]];
//	}
	[self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
    return [_resultList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
	NSUInteger row = [indexPath row];
	cell.textLabel.text = [_resultList objectAtIndex:row];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 30;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selectedText = [_resultList objectAtIndex:[indexPath row]];
	[_delegate didResultlistSelected:_selectedText];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


@end

