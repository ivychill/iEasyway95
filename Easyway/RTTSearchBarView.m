//
//  RTTSearchBarView.m
//  Easyway95
//
//  Created by Sean.Yie on 12-10-26.
//
//

#import "RTTSearchBarView.h"

@implementation RTTSearchBarView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self.uiInputTxtField setDelegate:self];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)didSearching:(id)sender
{
    [self callSearchDelegate:self.uiInputTxtField.text];
}

- (IBAction)didCloseCustSearchBar:(id)sender
{
//    [self.uiInputTxtField resignFirstResponder];
//    [self setHidden:YES];
    [self.delegate didHideAddrSearchBar:self];
}

- (void) callSearchDelegate:(NSString*) strInput
{
    if ([strInput isEqualToString:@""])
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"输入为空，请输入要查找的地址"
                                                          delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
        [alertView show];
        
    }
    else
    {
        [self.uiInputTxtField resignFirstResponder];
        [self.delegate didAddrSearchWasPressed:strInput];
    }

}

- (void) addAccessoryInputView
{
    //增加“隐藏键盘”的辅助View
    __autoreleasing UIToolbar *inputAccessToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    inputAccessToolbar.barStyle = UIBarStyleBlackTranslucent;//UIBarStyleBlackOpaque;//UIBarStyleDefault;//UIBarStyleBlackTranslucent;
    UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *hiddenButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"隐藏键盘" style:UIBarStyleBlackOpaque target:self action:@selector(dismissKeyboard)];
    NSArray *array = [NSArray arrayWithObjects: spaceButtonItem, hiddenButtonItem, nil];
    [inputAccessToolbar setItems:array];
    
    //UITextField *searchBarField = nil;
    [self.uiInputTxtField setInputAccessoryView:inputAccessToolbar];
    [self.uiInputTxtField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    
    UIColor *bgColor = [[UIColor alloc] initWithRed:0.3 green:0.3 blue:0.3 alpha:0.4];
    self.backgroundColor = bgColor;//[bgColor CGColor];//[[UIColor lightGrayColor] CGColor];
    

//    for (UIView *subView in topSeachBar.subviews) {
//        if ([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
//            searchBarField = (UITextField *)subView;
//            searchBarField.inputAccessoryView = inputAccessToolbar;
//            searchBarField.keyboardAppearance = UIKeyboardAppearanceAlert;
//            break;
//        }
//    }
    //End 增加“隐藏键盘”的辅助View

}
- (void) setInputDelegate
{
    [self.uiInputTxtField setDelegate:self];
    [self addAccessoryInputView];
}

- (void) dismissKeyboard
{
    [self.uiInputTxtField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField        // return NO to disallow editing.
{
    [self.delegate didAddrSearchBegin:self];
}
//- (void)textFieldDidBeginEditing:(UITextField *)textField;           // became first responder
//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
//- (void)textFieldDidEndEditing:(UITextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.delegate didAddrSearchInputWasChanged:newString];
    return YES;
}

//- (BOOL)textFieldShouldClear:(UITextField *)textField;               // called when clear button pressed. return NO to ignore (no notifications)
- (BOOL)textFieldShouldReturn:(UITextField *)textField              // called when 'return' key pressed. return NO to ignore.
{
    [self callSearchDelegate:self.uiInputTxtField.text];
    
    //[self setHidden:YES];
    return YES;
}

@end
