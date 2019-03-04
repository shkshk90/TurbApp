//
//  CameraMeasurementViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "CameraMeasurementViewController.h"
#import "../common.h"
#import "../Views/CameraMeasurementView.h"
#import "RoiGestureHandler.h"

@import AVFoundation;

#define CMVC_QUEUE_NAME "Camera Measurement Queue"

@interface FHGCameraMeasurementViewController ()

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

#pragma mark - View methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    _contentView     = [[FHGCameraMeasurementView alloc] initWithContentView:self.view];
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
    
    UIButton *const captureButton = (UIButton *)[_contentView viewWithTag:FHGTagCMVCaptureButton];
    [self updateCaptureButton:captureButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_contentView updateTextLayer];
    [[_contentView roiLayer] setHidden:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
    dispatch_async(_queue, ^{
        [self->_captureSession stopRunning];
    });
    
    [super viewDidDisappear:animated];
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
        
        NSLog(@"[%s:%d]:  %@", __FILENAME__, __LINE__, self->_videoDataOutput.videoSettings);
    });
}

#pragma mark - Buttons methods
- (void)updateCaptureButton:(UIButton *const)captureButton
{
//    UIColor *const color  = (dataDict == nil) ? [UIColor grayColor] :
//    [UIColor redColor];
//    const SEL action      = (dataDict == nil) ? @selector(disabledCaptureAction) :
//    @selector(enabledCaptureAction);
//
//    [captureButton setTintColor:color];
//    [captureButton removeTarget:NULL action:nil forControlEvents:UIControlEventAllEvents];
//    [captureButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
}

-(IBAction)buttonsAction:(UIButton *)sender
{
    switch (sender.tag) {
        case FHGTagCMVCaptureButton :
            NSLog(@"Hello");
            break;
            
        case FHGTagCMVSettingsButton :
            NSLog(@"Settings");
            break;
            
        case FHGTagCMVExitButton :
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
            
        default :
            FHG_TAG_NOT_HANDLED;
    }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
