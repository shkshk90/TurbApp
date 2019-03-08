//
//  CameraMeasurementViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "CameraMeasurementViewController.h"
#import "ExperimentParametersViewController.h"
#import "RoiGestureHandler.h"

#import "../common.h"
#import "../Views/CameraMeasurementView.h"
#import "../Views/CameraMeasurement_common.h"
#import "UIViewController+UIViewController_FHGViewAddition.h"


@import AVFoundation;
@import CoreText;

#define CMVC_QUEUE_NAME "Camera Measurement Queue"

@interface FHGCameraMeasurementViewController () <FHGProtocolExperimentParametersDelegate>

@end

@implementation FHGCameraMeasurementViewController {
@private dispatch_queue_t            _queue;
@private BOOL                        _hideStatusBar;
    
@private FHGCameraMeasurementView   *_contentView;

@private AVCaptureSession           *_captureSession;
@private AVCaptureDevice            *_cameraDevice;
@private AVCaptureDeviceInput       *_cameraDeviceInput;
@private AVCaptureVideoDataOutput   *_videoDataOutput;
    
@private FHGRoiGestureHandler       *_gesturesHandler;
    
}

@synthesize experimentDataDict = _experimentDataDict;

#pragma mark - View methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//    _contentView     = [[FHGCameraMeasurementView alloc] initWithContentView:self.view];
    _contentView     = [[FHGCameraMeasurementView alloc] init];
    [self fhg_addMainSubView:_contentView];
    
    _gesturesHandler = [[FHGRoiGestureHandler alloc] initWithView:[_contentView viewWithTag:FHGTagCMVCameraView]
                                                           forROI:[_contentView roiLayer]];

    _hideStatusBar = NO;
    _queue  = dispatch_queue_create(CMVC_QUEUE_NAME, DISPATCH_QUEUE_SERIAL);

    
    [self configureNavigation:self.navigationController];

    [self authorizeAndConfigureCameraDevice];

    [self configureCaptureSessionInput];
    [self configureCaptureSessionOutput];

    [_contentView setupCameraViewWithCaptureSession:_captureSession];
    [_contentView setButtonsTarget:self withSelector:@selector(buttonsAction:)];
    
    [_gesturesHandler enableAllGestures];
    [[_contentView roiLayer] setHidden:YES];
    
    _experimentDataDict = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(_queue, ^{
        [self->_captureSession startRunning];
    });
    
    _hideStatusBar = YES;
    [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionPreferredFramesPerSecondDefault
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     } completion:nil];
    
    [[_contentView roiLayer] setHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async(_queue, ^{
        [self->_captureSession stopRunning];
    });
    
    [super viewDidDisappear:animated];
}

#pragma mark - Buttons methods
-(IBAction)buttonsAction:(UIButton *)sender
{
    UIViewController *nextController;
    UIModalTransitionStyle transitionStyle = UIModalTransitionStyleCoverVertical;
    
    switch (sender.tag) {
        case FHGTagCMVCaptureButton :
            if (_experimentDataDict == nil)
                [self disabledCaptureAction];
            else
                [self enabledCaptureAction];
            
            NSLog(@"Capture clicked");
            
            return;
            break;
            
        case FHGTagCMVSettingsButton :
            nextController  = [[FHGExperimentParametersViewController alloc] init];
            transitionStyle = UIModalTransitionStyleCoverVertical;
            
            [((FHGExperimentParametersViewController *)nextController) setDelegate:self];
            
            NSLog(@"Settings");
            break;
            
        case FHGTagCMVExitButton :
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
            
        default :
            FHG_TAG_NOT_HANDLED;
    }
    
    UINavigationController *const navigationController = [[UINavigationController alloc] initWithRootViewController:nextController];
    
    [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
    [navigationController setModalTransitionStyle:transitionStyle];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)enabledCaptureAction
{
    NSLog(@"Hello again");
    //    For Testing
    //    const CGFloat mainHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    //    const CGFloat mainWidth  = CGRectGetWidth([UIScreen mainScreen].bounds);
    //
    //    const CGFloat vidHeight  = [(NSNumber *)videoDataOutput.videoSettings[@"Height"] doubleValue];
    //    const CGFloat vidWidth   = [(NSNumber *)videoDataOutput.videoSettings[@"Width"]  doubleValue];
    //    NSLog(@"H: %f, %f --> %f", mainHeight, vidWidth, vidHeight   / mainWidth);
    //    NSLog(@"W: %f, %f --> %f", mainWidth,  vidHeight,  vidWidth  / mainHeight);
    
    // NOTE Video's width IS Screen's height
//    const CGFloat ratio = [(NSNumber *)videoDataOutput.videoSettings[@"Height"] doubleValue] /
//    CGRectGetWidth([UIScreen mainScreen].bounds);
//
//    const CGRect    roiFrame    = roiLayer.frame;
//    const NSInteger frameSide   = (NSInteger)lround(roiFrame.size.width * ratio);   // Actual size in video pixels
//
//    CGFloat roundedFrameSide;
//
//    if (frameSide <= 128)
//        roundedFrameSide = 128.;
//    else {
//        const NSInteger rem = frameSide % 128;
//        const NSInteger apx = frameSide - rem;
//
//        roundedFrameSide = (CGFloat)((rem >= 64) ? apx + 128 : apx);  // Determine whether to floor or ceil
//    }
//
//    const CGRect roiVideoFrame = CGRectMake(roiFrame.origin.x    * ratio,
//                                            roiFrame.origin.y    * ratio,
//                                            roundedFrameSide,    roundedFrameSide);
//
//    NSLog(@"%f, %f, %f, %f", roiFrame.origin.x, roiFrame.origin.y, roiFrame.size.width, roiFrame.size.height);
//    NSLog(@"%f, %f, %f, %f", roiFrame.origin.x * ratio, roiFrame.origin.y * ratio,
//          roiFrame.size.width * ratio, roiFrame.size.height * ratio);
//    NSLog(@"%f, %f, %f, %f", roiVideoFrame.origin.x, roiVideoFrame.origin.y, roiVideoFrame.size.width, roiVideoFrame.size.height);
    
    ///////////////// TODOOOOOOOooOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
}

- (void)disabledCaptureAction
{
    CATextLayer *const instructionsLayer = [_contentView instructionsLayer];
    
    if (instructionsLayer.hidden) {
        [instructionsLayer setHidden:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [instructionsLayer setHidden:YES];
        });
    }
}

#pragma mark - Capture device methods
- (void)authorizeAndConfigureCameraDevice
{
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized: // The user has previously granted access to the camera.
            break;
            
        case AVAuthorizationStatusNotDetermined: // The user has not yet been asked for camera access.
        {
            dispatch_suspend(_queue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
                dispatch_resume(self->_queue);
            }];
            break;
        }
            
        case AVAuthorizationStatusDenied: // The user has previously denied access.
        case AVAuthorizationStatusRestricted:
            return;
    }
    
    dispatch_async(_queue, ^{
        [self configureCaptureDevice];
    });
}

- (void)configureCaptureDevice
{
    _cameraDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    if (!_cameraDevice)
        // If a rear dual camera is not available, default to the rear wide angle camera.
        _cameraDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo   position:AVCaptureDevicePositionBack];
}

#pragma mark - Capture session methods
- (void)configureCaptureSessionInput //:(AVCaptureSession *)session withDevice:(AVCaptureDevice *)device andInput:(AVCaptureDeviceInput *)deviceInput
{
    _captureSession = [[AVCaptureSession alloc] init];
    
    dispatch_async(_queue, ^{
        NSError *err = nil;
        
        [self->_captureSession beginConfiguration];
        
        [self authorizeAndConfigureCameraDevice];
        
        self->_cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self->_cameraDevice error:&err];
        
        if (!self->_cameraDeviceInput)
            [[NSException exceptionWithName:@"CameraNotAvailableException" reason:[NSString stringWithFormat:@"Couldn't open camera:\n%@", [err userInfo]] userInfo:nil] raise];
        
        if ([self->_captureSession canAddInput:self->_cameraDeviceInput])
            [self->_captureSession addInput:self->_cameraDeviceInput];
        else
            [[NSException exceptionWithName:@"SessionException" reason:@"Couldn't add camera device to session" userInfo:nil] raise];
        
        [self->_captureSession setSessionPreset:^AVCaptureSessionPreset(void){
            if ([self->_captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160])
                return AVCaptureSessionPreset3840x2160;
            else if ([self->_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
                return AVCaptureSessionPresetHigh;
            else if ([self->_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium])
                return AVCaptureSessionPresetMedium;
            
            return AVCaptureSessionPresetLow;
        }()];
        //        if ([self->captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160])
        //            [self->captureSession setSessionPreset:AVCaptureSessionPreset3840x2160];
        //        else if ([self->captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
        //            [self->captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        
        [self->_captureSession commitConfiguration];
    });
}

- (void)configureCaptureSessionOutput
{
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dispatch_async(_queue, ^{
        NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
        
        [self->_videoDataOutput setVideoSettings:outputSettings];
        [self->_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        
        if ([self->_captureSession canAddOutput:self->_videoDataOutput]) {
            [self->_captureSession beginConfiguration];
            [self->_captureSession addOutput:self->_videoDataOutput];
            
            [self->_captureSession setSessionPreset:^AVCaptureSessionPreset(void){
                if ([self->_captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160])
                    return AVCaptureSessionPreset3840x2160;
                else if ([self->_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
                    return AVCaptureSessionPresetHigh;
                else if ([self->_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium])
                    return AVCaptureSessionPresetMedium;
                
                return AVCaptureSessionPresetLow;
            }()];
            
            AVCaptureConnection* connection = [self->_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoStabilizationSupported)
                [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeOff];
            
            [self->_captureSession commitConfiguration];
        }
        
        self->_videoSize.width  = [[self->_videoDataOutput.videoSettings valueForKey:@"Width"]  doubleValue];
        self->_videoSize.height = [[self->_videoDataOutput.videoSettings valueForKey:@"Height"] doubleValue];
        
        
        NSLog(@"[%s:%d]:  %@", __FILENAME__, __LINE__, self->_videoDataOutput.videoSettings);
        
        FHG_NS_LOG(@"Width = %f",  self->_videoSize.width);
        FHG_NS_LOG(@"Height = %f", self->_videoSize.height);
    });
}

#pragma mark - Navigation methods
- (void)configureNavigation:(UINavigationController *)controller
{
    [controller.navigationBar setHidden:YES];
}

- (IBAction)goBackToChoiceSelector:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - Experiment Data Dictionary methods
- (void)setExperimentDataDict:(NSDictionary *)dict
{
    _experimentDataDict = dict;
    
    UIButton *const captureButton = (UIButton *)[_contentView viewWithTag:FHGTagCMVCaptureButton];
    
    [captureButton setTintColor:[UIColor redColor]];
    
    [captureButton setShowsTouchWhenHighlighted:YES];
    [captureButton setAdjustsImageWhenHighlighted:YES];
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
