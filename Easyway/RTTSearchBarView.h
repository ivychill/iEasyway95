//
//  RTTSearchBarView.h
//  Easyway95
//
//  Created by Sean.Yie on 12-10-26.
//
//

#import <UIKit/UIKit.h>
#import "RTTVCDelegate.h"

@interface RTTSearchBarView : UIView <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *uiInputTxtField;
- (IBAction)didSearching:(id)sender;
- (IBAction)didCloseCustSearchBar:(id)sender;

- (void) setInputDelegate;
- (void) dismissKeyboard;

@property id <RTTVCDelegate> delegate;

@end
