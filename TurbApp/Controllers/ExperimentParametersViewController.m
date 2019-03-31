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
#import "UIViewController+UIViewController_FHGViewAddition.h"

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
    
@private CGFloat                        _distanceInMeters;
@private CGFloat                        _apertureInMillimeters;
@private CGFloat                        _lengthInMeters;
@private CGFloat                        _samplesCountOverTen;

@private NSUInteger                     _blockInPixels;
@private NSUInteger                     _upScale;

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

    
    _distanceInMeters       = 0.;
    _apertureInMillimeters  = 0.;
    _lengthInMeters         = 0.;
    
    _samplesCountOverTen    = 3.;
    
    _blockInPixels          = 32;
    _upScale                = 4;
    
    _contentView = [[FHGExperimentParametersView alloc] init];
    [self fhg_addMainSubView:_contentView];
    
    [_contentView setButtonsTarget:self withSelector:@selector(segmentedControlValueChanged:)];
    [_contentView setTextFieldDelegateAndTarget:self withSelector:@selector(checkTextField:)];
    [_contentView setSliderTarget:self withSelector:@selector(sliderMoved:)];

    [self configureNavigation];
    [self registerForKeyboardNotifications];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    if ([self retrieveDataFromDelegate])
        [self updateViewWithData];
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
    [_contentView updateSegmentedControl:FHGTagEPVSegControlBlockSize withValue:_blockInPixels];
    [_contentView updateSegmentedControl:FHGTagEPVSegControlUpscale   withValue:_upScale];
    
    
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

#pragma mark - Data Save and Retrieval
- (BOOL)retrieveDataFromDelegate
{
    NSDictionary *const dict = _delegate.experimentDataDict;
    
    if ((dict == nil) || ([dict count] == 0))
        return NO;
    
    /*
     #define FHGK_EXP_PARAM_DISTANCE_TO_TARGET       @"Distance To Target"
     #define FHGK_EXP_PARAM_APERTURE_SIZE            @"Aperture"
     #define FHGK_EXP_PARAM_LENGTH_OF_SCENE          @"Scene Length"
     #define FHGK_EXP_PARAM_BLOCK_SIZE               @"Block Size"
     #define FHGK_EXP_PARAM_NUMBER_OF_SAMPLES        @"Samples Count"
     #define FHGK_EXP_PARAM_TYPE_OF_LENGTH           @"Length Type"
     */
    
    NSNumber *const distanceValue = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_DISTANCE_TO_TARGET];
    NSNumber *const apertureValue = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_APERTURE_SIZE];
    
    NSNumber *const pixelsValue   = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_PIXELS_IN_SCENE];
    NSNumber *const lengthValue   = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_LENGTH_OF_SCENE];
    
    NSNumber *const blockValue    = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_BLOCK_SIZE];
    NSNumber *const samplesValue  = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_NUMBER_OF_SAMPLES];
    
    NSNumber *const upscaleValue  = (NSNumber *)[dict objectForKey:FHGK_EXP_PARAM_SUBPIXEL_UPSCALE];
    
    
    _distanceInMeters       = (CGFloat)[distanceValue doubleValue];
    _apertureInMillimeters  = (CGFloat)[apertureValue doubleValue];
    _lengthInMeters         = (CGFloat)[lengthValue   doubleValue];
    
    _lengthIsHeight         = fabs([pixelsValue  doubleValue] - _delegate.videoSize.height) < DBL_EPSILON ;
    _blockInPixels          = [blockValue        unsignedIntegerValue];
    _samplesCountOverTen    = [samplesValue      doubleValue];
    _upScale                = [upscaleValue      unsignedIntegerValue];
    
    FHG_NS_LOG(@"Data retrieved: %@", dict);
    
    return YES;
}

- (NSDictionary *const)generateDictWithExperimentData
{
    /*
     #define FHGK_EXP_PARAM_DISTANCE_TO_TARGET       @"Distance To Target"
     #define FHGK_EXP_PARAM_APERTURE_SIZE            @"Aperture"
     #define FHGK_EXP_PARAM_LENGTH_OF_SCENE          @"Scene Length"
     #define FHGK_EXP_PARAM_BLOCK_SIZE               @"Block Size"
     #define FHGK_EXP_PARAM_NUMBER_OF_SAMPLES        @"Samples Count"
     #define FHGK_EXP_PARAM_TYPE_OF_LENGTH           @"Length Type"
     */
    
    NSDictionary *const dictionary = @{
       FHGK_EXP_PARAM_DISTANCE_TO_TARGET : [NSNumber numberWithDouble:_distanceInMeters],
       FHGK_EXP_PARAM_APERTURE_SIZE      : [NSNumber numberWithDouble:_apertureInMillimeters],
       
       FHGK_EXP_PARAM_PIXELS_IN_SCENE    : [NSNumber numberWithDouble:(_lengthIsHeight) ? _delegate.videoSize.height : _delegate.videoSize.width],
       FHGK_EXP_PARAM_LENGTH_OF_SCENE    : [NSNumber numberWithDouble:_lengthInMeters],
       
       FHGK_EXP_PARAM_BLOCK_SIZE         : [NSNumber numberWithUnsignedInteger:_blockInPixels],
       FHGK_EXP_PARAM_NUMBER_OF_SAMPLES  : [NSNumber numberWithDouble:_samplesCountOverTen],
       
       FHGK_EXP_PARAM_SUBPIXEL_UPSCALE   : [NSNumber numberWithUnsignedInteger:_upScale],
    };
    
    FHG_NS_LOG(@"Data Saved: %@", dictionary);
    
    return dictionary;
}

#pragma mark - Navigatian methods
- (void)configureNavigation
{
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    [self.navigationItem setTitle:@"Parameters"];
    [self.navigationItem setLeftBarButtonItem:
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]];
    [self.navigationItem setRightBarButtonItem:
     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)]];
}

- (IBAction)cancel
{
    [self dismissKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done
{
    [_delegate setExperimentDataDict:[self generateDictWithExperimentData]];
    
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
            
            _blockInPixels = 1 << (4 + (NSUInteger)index);
            break;
            
        case FHGTagEPVSegControlUpscale:
            
            _upScale       = 1 << (NSUInteger)index;
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
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
