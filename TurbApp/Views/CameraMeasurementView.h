//
//  CameraMeasurementView.h
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import  "../common.h"

@class AVCaptureSession;

NS_ASSUME_NONNULL_BEGIN

@interface FHGCameraMeasurementView : UIView <FHGViewsProtocol>

- (id)initWithContentView:(UIView *const)superView;
- (UIView *)viewWithTag:(const NSInteger)tag;
- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector;

- (void)setupCameraViewWithCaptureSession:(AVCaptureSession *const)captureSession;
- (CALayer *)roiLayer;

- (void)updateTextLayer;        // To be called in ViewDidAppear
- (void)updateCaptureButton;    // To be called in ViewWillAppear

@end

NS_ASSUME_NONNULL_END
