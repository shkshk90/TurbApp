//
//  ExperimentParametersViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "ExperimentParametersViewController.h"
#import "../Views/ExperimentParametersView.h"
#import "../Views/ExperimentParameters_common.h"
#import "../common.h"

#pragma mark - Interface
@interface FHGExperimentParametersViewController () <UITextFieldDelegate>

@end

#pragma mark - Implementation & members
@implementation FHGExperimentParametersViewController {

@private FHGExperimentParametersView   *_contentView;

@private BOOL                           _distanceIsBad;
@private BOOL                           _apertureIsBad;
@private BOOL                           _lengthIsBad;
    
@private BOOL                           _lengthIsHeight;

@private BOOL                           _hideStatusBar;
@private BOOL                           _dataIsAvailable;
    
@private CGFloat                        _distanceInMeters;
@private CGFloat                        _apertureInMillimeters;
@private CGFloat                        _lengthInMeters;
@private CGFloat                        _samplesCountOverTen;

@private NSInteger                      _blockInPixels;


}

#pragma mark - View methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _distanceIsBad          = YES;
    _apertureIsBad          = YES;
    _lengthIsBad            = YES;
    
    _lengthIsHeight         = NO;
    
    _hideStatusBar          = YES;
    _dataIsAvailable        = NO;

    
    _distanceInMeters       = 0.;
    _apertureInMillimeters  = 0.;
    _lengthInMeters         = 0.;
    
    _samplesCountOverTen    = 3.;
    
    _blockInPixels          = 32;
    
    
    _contentView = [[FHGExperimentParametersView alloc] initWithContentView:self.view];
    
    [_contentView setButtonsTarget:self withSelector:@selector(segmentedControlValueChanged:)];
    [_contentView setTextFieldDelegateAndTarget:self withSelector:@selector(checkTextField:)];
    [_contentView setSliderTarget:self withSelector:@selector(sliderMoved:)];

    [self configureNavigation];
    [self registerForKeyboardNotifications];
    
//    [self.view addSubview:_contentView];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _hideStatusBar = NO;
    
    [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionPreferredFramesPerSecondDefault
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     } completion:nil];
}

- (void)updateViewWithData
{
    [_contentView fillTextField:FHGTagEPVTextFieldDistance      withData:_distanceInMeters];
    [_contentView fillTextField:FHGTagEPVTextFieldAperture      withData:_apertureInMillimeters];
    [_contentView fillTextField:FHGTagEPVTextFieldLength        withData:_lengthInMeters];
    [_contentView fillTextField:FHGTagEPVTextFieldSamplesCount  withData:_samplesCountOverTen];
    
    [_contentView updateSegmentedControl:FHGTagEPVSegControlLength    withValue:_lengthIsHeight];
    [_contentView updateSegmentedControl:FHGTagEPVSegControlBlockSize withValue:_lengthIsHeight];
    
    
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

#pragma mark - Dict
- (void)updateDataWithDict:(NSDictionary *)dict
{
    const NSNumber *distanceValue = (NSNumber *)[dict objectForKey:@"Distance"];
    const NSNumber *apertureValue = (NSNumber *)[dict objectForKey:@"Aperture"];
    
    const NSNumber *typeValue   = (NSNumber *)[dict objectForKey:@"Type"];
    const NSNumber *lengthValue   = (NSNumber *)[dict objectForKey:@"Length"];
    
    const NSNumber *blockValue    = (NSNumber *)[dict objectForKey:@"Block"];
    
    _distanceInMeters       = (CGFloat)[distanceValue doubleValue];
    _apertureInMillimeters  = (CGFloat)[apertureValue doubleValue];
    _lengthInMeters         = (CGFloat)[lengthValue   doubleValue];
    
    _lengthIsHeight         = [typeValue boolValue];
    _blockInPixels          = [blockValue  integerValue];
    
    _dataIsAvailable        = YES;
}

- (NSDictionary *)generateDataDict
{
    NSDictionary *const dictionary = @{
                                       @"Distance"     : [NSNumber numberWithDouble:_distanceInMeters],
                                       @"Aperture"     : [NSNumber numberWithDouble:_apertureInMillimeters],
                                       
                                       @"Type"         : [NSNumber numberWithBool:_lengthIsHeight],
                                       @"Length"       : [NSNumber numberWithDouble:_lengthInMeters],
                                       
                                       @"Block"        : [NSNumber numberWithInteger:_blockInPixels],
                                       };
    
    return dictionary;
}

#pragma mark - Navigatian methods
- (void)configureNavigation
{
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    [self.navigationItem setTitle:@"Parameters"];
    [self.navigationItem setRightBarButtonItem:
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel)]];
    [self.navigationItem setLeftBarButtonItem:
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(done)]];
    
    NSLog(@"Navi: %d", self.navigationController == nil);
}

- (IBAction)cancel
{
    [self dismissKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done
{
//    [self.delegate setExperimentDataWithDict:[self generateDataDict]];
    [self dismissKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TextFields methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];   //  Hide keyboard
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    return;
}
- (void)checkTextField:(UITextField *)field
{
    const CGFloat fieldValue = (CGFloat)[field.text doubleValue];
    const BOOL valueIsValid  = (fieldValue == 0.0 ||
                                fieldValue >= CGFLOAT_MAX ||
                                fieldValue <= CGFLOAT_MIN);
    
    switch ((FHGTagExperimentParametersTextField)field.tag) {
        case  FHGTagEPVTextFieldDistance:
            _distanceInMeters = fieldValue;
            _distanceIsBad    = valueIsValid;
            break;
            
        case FHGTagEPVTextFieldAperture :
            _apertureInMillimeters = fieldValue;
            _apertureIsBad         = valueIsValid;
            break;
            
        case FHGTagEPVTextFieldLength :
            _lengthInMeters = fieldValue;
            _lengthIsBad    = valueIsValid;
            break;
        default:
            return;
    }
    
    [self.navigationItem.rightBarButtonItem setEnabled:!(_distanceIsBad || _apertureIsBad || _lengthIsBad)];
}

#pragma mark - IBAction methods
- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender
{
    const NSInteger index = sender.selectedSegmentIndex;
    
    switch ((FHGTagExperimentParametersSegmentedControl)sender.tag) {
        case FHGTagEPVSegControlLength :
            
            [_contentView changeLengthViewsToWidth:FHGTagEPVSceneWidth + index];
            _lengthIsHeight = (BOOL)index;
            
            break;
            
        case FHGTagEPVSegControlBlockSize :
            
            _blockInPixels = 1 << (4 + index);
            break;
    }
}

- (IBAction)sliderMoved:(UISlider *)sender
{
    _samplesCountOverTen = roundf(sender.value);

    [((UILabel *)[_contentView viewWithTag:FHGTagEPVTextFieldSamplesCount]) setText: [NSString stringWithFormat:@"%.f", _samplesCountOverTen * 10.]];
}
//- (IBAction)updateLengthData:(UISegmentedControl *)sender
//{
//    const NSInteger index = sender.selectedSegmentIndex;
//
//    [_contentView updateSegmentedControl:FHGTagEPVSegControlLength withValue:FHGTagEPVSceneWidth + index];
//    _lengthIsHeight = (BOOL)index;
//}
//
//- (IBAction)updateBlockSize:(UISegmentedControl *)sender
//{
//    _blockInPixels = 1 << (4 + (sender.selectedSegmentIndex)); //BLK_SIZE(sender.selectedSegmentIndex);
//}

#pragma mark - Keyboard
- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *const info            = [notification userInfo];
    const CGFloat keboardHeight         = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    const UIEdgeInsets contentInsets    = UIEdgeInsetsMake(0.0, 0., keboardHeight * 1.5, 0.0);
    
    UIScrollView *const mainScrollView  = (UIScrollView *)[_contentView viewWithTag:FHGTagEPVViewMainScrollView];
    
    [mainScrollView setContentInset:contentInsets];
    [mainScrollView setScrollIndicatorInsets:contentInsets];
    
    CGRect newRect = self.view.frame;
    newRect.size.height -= keboardHeight;
    
    if (!CGRectContainsPoint(newRect, [_contentView viewWithTag:FHGTagEPVTextFieldLength].frame.origin) ) {
        const CGPoint scrollPoint = CGPointMake(0.0, 100.); // _lengthTextField.frame.origin.y - keboardHeight * 5.);
        [mainScrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIScrollView *const mainScrollView  = (UIScrollView *)[_contentView viewWithTag:FHGTagEPVViewMainScrollView];
    const UIEdgeInsets contentInsets    = UIEdgeInsetsZero;
    
    [mainScrollView setContentInset:contentInsets];
    [mainScrollView setScrollIndicatorInsets:contentInsets];
}

#pragma mark - Status bar methods
- (BOOL)prefersStatusBarHidden
{
    return _hideStatusBar;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
