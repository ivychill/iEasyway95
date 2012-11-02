//
//  RTTPrefSettingViewController.h
//  Easyway95
//
//  Created by Sean.Yie on 12-10-27.
//
//

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"

@interface RTTPrefSettingViewController : UIViewController
@property id <RTTVCDelegate> delegate;

@property (strong, nonatomic) IBOutlet UILabel *uiAddrInfoLBL;
@property (strong, nonatomic) IBOutlet UISwitch *uiTTSSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *uiAutoDetectSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *uiAutoScaleSwitch;

- (IBAction)didTTSFlagSwitch:(id)sender;
- (IBAction)didAutoDetectSwitch:(id)sender;
- (IBAction)didAutoScaleMapSwitch:(id)sender;


@property NSString *addrInfoTxt;
@property BOOL TTSSwitchStat;
@property BOOL autoDetectSwitchStat;
@property BOOL autoScaleSwitchStat;


@end
