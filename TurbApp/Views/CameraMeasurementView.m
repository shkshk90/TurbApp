//
//  CameraMeasurementView.m
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "CameraMeasurementView.h"
#import "views_resources.h"
#import "CameraPreviewSubView.h"

@import Foundation;
@import AVFoundation;
@import CoreText;

@implementation FHGCameraMeasurementView {
@private FHGCameraPreviewSubView   *_cameraView;
    
@private UIButton                   *_exitButton;
@private UIButton                   *_settingsButton;
@private UIButton                   *_captureButton;
    
@private CALayer                    *_roiLayer;
@private CATextLayer                *_instructionsLayer;
    
@private UILayoutGuide              *_guide;
@private CGRect                      _bounds;
    
    

}

#pragma mark - Public methods
- (id)initWithContentView:(UIView *const)superView
{
    self = [super init] ?: nil;
    
    if (self == nil)
        return nil;
    
    _guide          = superView.safeAreaLayoutGuide;
    _bounds         = [UIScreen mainScreen].bounds;
    
    _cameraView     = [[FHGCameraPreviewSubView alloc] init];
    
    _exitButton     = [UIButton buttonWithType:UIButtonTypeSystem];
    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _captureButton  = [UIButton buttonWithType:UIButtonTypeSystem];
    
    _roiLayer          = [CALayer layer];
    _instructionsLayer = [CATextLayer layer];
    
    
    [superView addSubview:self];
    
    [self setOpaque:YES];
    
    [self setupViews];
    [self buildMainView];
    [self setupAllConstraints];
    
    return self;
}

- (UIView *)viewWithTag:(const NSInteger)tag {
    switch ((FHGTagCameraMeasurement)tag) {
        case FHGTagCMVCameraView     : return _cameraView;
        case FHGTagCMVExitButton     : return _exitButton;
        case FHGTagCMVCaptureButton  : return _captureButton;
        case FHGTagCMVSettingsButton : return _settingsButton;
        default : FHG_TAG_NOT_HANDLED;
    }
}

- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector
{
    [_exitButton     addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
    [_captureButton  addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
    [_settingsButton addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
}

- (CALayer *)roiLayer
{
    return _roiLayer;
}

#pragma mark - Public Configuration methods
- (void)updateTextLayer
{
    const CGRect  r = _settingsButton.frame;
    
    const CGFloat x = r.origin.x;
    const CGFloat y = CGRectGetMinY(r) - CGRectGetHeight(r);
    
    const CGFloat w = fhgv_getPercentageOfScreenWidth(_bounds, 50.);
    const CGFloat h = CGRectGetHeight(r) * .5;
    
    [_instructionsLayer setString:@"Set settings first!"];
    [_instructionsLayer setAlignmentMode:kCAAlignmentCenter];
    
    [_instructionsLayer setFont:CTFontCreateWithName((__bridge CFStringRef)@"Optima-Regular" , 18., NULL)];
    [_instructionsLayer setFontSize:18.];
    
    [_instructionsLayer setWrapped:YES];
    [_instructionsLayer setAllowsFontSubpixelQuantization:YES];
    
    [_instructionsLayer setForegroundColor:[UIColor orangeColor].CGColor];
    [_instructionsLayer setBackgroundColor:[UIColor darkGrayColor].CGColor];
    
    [_instructionsLayer setFrame:CGRectMake(x, y, w, h)];
    [_instructionsLayer setShouldRasterize:YES];
    [_instructionsLayer setRasterizationScale:[UIScreen mainScreen].scale];
    
    [_instructionsLayer setOpacity:NO];
}

#pragma mark - General methods
- (void)setupViews
{
    [self setupButton:_exitButton     withTag:FHGTagCMVExitButton];
    [self setupButton:_settingsButton withTag:FHGTagCMVSettingsButton];
    [self setupButton:_captureButton  withTag:FHGTagCMVCaptureButton];
    
    [self configureRoiLayer];
    [self configureTextLayer];
}

- (void)buildMainView
{
    [self addSubview:_cameraView];
    
    [_cameraView addSubview:_exitButton];
    [_cameraView addSubview:_settingsButton];
    [_cameraView addSubview:_captureButton];
    
    [_cameraView.layer addSublayer:_instructionsLayer];
    [_cameraView.layer addSublayer:_roiLayer];
}

-(void)setupAllConstraints
{
    [self setupMainViewConstraints];
    [self setupCameraViewContstraits];
    
    [self setupConstraintsForButton:_exitButton     WithTag:FHGTagCMVExitButton];
    [self setupConstraintsForButton:_settingsButton WithTag:FHGTagCMVSettingsButton];
    [self setupConstraintsForButton:_captureButton  WithTag:FHGTagCMVCaptureButton];
}

#pragma mark - Specific setup methods
- (void)setupCameraViewWithCaptureSession:(AVCaptureSession *const)captureSession
{
    [_cameraView setTag:FHGTagCMVCameraView];
    [_cameraView setOpaque:YES];
    
    AVCaptureVideoPreviewLayer *previewLayer = [_cameraView videoPreviewLayer];
    
    [previewLayer setSession:captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
}

- (void)setupButton:(UIButton *const)button withTag:(const FHGTagCameraMeasurement)tag
{
    [button setTag:(NSInteger)tag];
    
    UIImage *image;
    UIColor *color;
    
    switch (tag) {
        case FHGTagCMVExitButton:
            image  = [[UIImage imageNamed:CMV_EXITBTN_IMG_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            color  = [UIColor whiteColor];
            
            break;
            
        case FHGTagCMVSettingsButton:
            image  = [[UIImage imageNamed:CMV_SETTINGSBTN_IMG_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            color  = [UIColor whiteColor];
            
            break;
            
        case FHGTagCMVCaptureButton:
            image  = [[UIImage imageNamed:CMV_CAPTUREBTN_IMG_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            color  = [UIColor grayColor];
            
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    [button setTintColor:color];
    
    [button setTitle:@""   forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateNormal];
    
    [button setShowsTouchWhenHighlighted:(tag != FHGTagCMVCaptureButton)];
}

- (void)configureTextLayer
{
    [_instructionsLayer setHidden:YES];
}


- (void)configureRoiLayer
{
    const CGFloat roiX   = (CGRectGetWidth(_bounds)  / 2.) - 25.;
    const CGFloat roiY   = (CGRectGetHeight(_bounds) / 2.) - 25.;
    
    [_roiLayer setBorderWidth:2.];
    [_roiLayer setBorderColor:[UIColor orangeColor].CGColor];
    [_roiLayer setFrame:CGRectMake(roiX, roiY, 50., 50.)];
    [_roiLayer setDrawsAsynchronously:YES];
}

#pragma mark - Specific Constraint methods
- (void)setupMainViewConstraints
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[self.leadingAnchor constraintEqualToAnchor:_guide.leadingAnchor] setActive:YES];
    [[self.trailingAnchor constraintEqualToAnchor:_guide.trailingAnchor] setActive:YES];
    [[self.topAnchor constraintEqualToAnchor:_guide.topAnchor] setActive:YES];
    [[self.bottomAnchor constraintEqualToAnchor:_guide.bottomAnchor] setActive:YES];
}

- (void)setupCameraViewContstraits
{
    [_cameraView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[_cameraView.widthAnchor constraintEqualToAnchor:_guide.widthAnchor] setActive:YES];
    [_cameraView addConstraint:[NSLayoutConstraint
                                    constraintWithItem:_cameraView
                                    attribute:NSLayoutAttributeHeight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:_cameraView
                                    attribute:NSLayoutAttributeWidth
                                    multiplier:(16. / 9.) constant:1.]];
}

- (void)setupConstraintsForButton:(UIButton *const)button WithTag:(const FHGTagCameraMeasurement)tag
{
    CGFloat horizontalPercentage = 0.;
    CGFloat verticallPercentage  = 0.;
    CGFloat sidePercentage       = 0.;
    
    switch (tag) {
        case FHGTagCMVExitButton:
            horizontalPercentage = kCMVExitHorlP;
            verticallPercentage  = kCMVExitVertP;
            sidePercentage       = kCMVExitSideP;
            
            break;
            
        case FHGTagCMVSettingsButton:
            horizontalPercentage = kCMVSettHorlP;
            verticallPercentage  = kCMVSettVertP;
            sidePercentage       = kCMVSettSideP;
            
            break;
            
        case FHGTagCMVCaptureButton:
            horizontalPercentage = kCMVCaptHorlP;
            verticallPercentage  = kCMVCaptVertP;
            sidePercentage       = kCMVCaptSideP;
            
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    const CGFloat verticalSpacing    = fhgv_getPercentageOfScreenHeight(_bounds, verticallPercentage);
    const CGFloat horizontalSpacing  = fhgv_getPercentageOfScreenWidth(_bounds, horizontalPercentage);
    const CGFloat buttonSide         = fhgv_getPercentageOfScreenWidth(_bounds, sidePercentage);
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[button.leadingAnchor constraintEqualToAnchor:_guide.leadingAnchor constant:horizontalSpacing] setActive:YES];
    [[button.topAnchor constraintEqualToAnchor:_guide.topAnchor constant:verticalSpacing] setActive:YES];
    [button addConstraint:[NSLayoutConstraint
                           constraintWithItem:button
                           attribute:NSLayoutAttributeWidth
                           relatedBy:NSLayoutRelationEqual
                           toItem:nil
                           attribute:NSLayoutAttributeNotAnAttribute
                           multiplier:1. constant:buttonSide * 1.1]];
    
    [button addConstraint:[NSLayoutConstraint
                           constraintWithItem:button
                           attribute:NSLayoutAttributeHeight
                           relatedBy:NSLayoutRelationEqual
                           toItem:button
                           attribute:NSLayoutAttributeWidth
                           multiplier:1. constant:1.]];
    
    [button setImageEdgeInsets:UIEdgeInsetsMake(buttonSide, buttonSide, buttonSide, buttonSide)];
}





/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
