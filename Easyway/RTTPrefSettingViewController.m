//
//  RTTPrefSettingViewController.m
//  Easyway95
//
//  Created by Sean.Yie on 12-10-27.
//
//

#import "RTTPrefSettingViewController.h"

@interface RTTPrefSettingViewController ()

@end

@implementation RTTPrefSettingViewController

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
    self.uiAddrInfoLBL.text = self.addrInfoTxt;
    
    [self.uiTTSSwitch setOn:self.TTSSwitchStat];
    [self.uiAutoDetectSwitch setOn:self.autoDetectSwitchStat];
    [self.uiAutoScaleSwitch setOn:self.autoScaleSwitchStat];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setUiAddrInfoLBL:nil];
    [self setUiTTSSwitch:nil];
    [self setUiAutoDetectSwitch:nil];
    [self setUiAutoScaleSwitch:nil];
    [super viewDidUnload];
}
- (IBAction)didTTSFlagSwitch:(id)sender {
    if ([sender isKindOfClass:([UISwitch class])])
    {
        [self.delegate didTTSSwitchOnOff:[((UISwitch*)sender) isOn]];
    }
}

- (IBAction)didAutoDetectSwitch:(id)sender {
    if ([sender isKindOfClass:([UISwitch class])])
    {
        [self.delegate didAutoDetectSwitchOnOff:[((UISwitch*)sender) isOn]];
    }
}

- (IBAction)didAutoScaleMapSwitch:(id)sender {
    if ([sender isKindOfClass:([UISwitch class])])
    {
        [self.delegate didAutoScaleMapSwitchOnOff:[((UISwitch*)sender) isOn]];
    }
}
@end
