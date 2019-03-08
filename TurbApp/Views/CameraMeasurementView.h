//
//  CameraMeasurementView.h
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import  "views_common.h"

@class AVCaptureSession;

NS_ASSUME_NONNULL_BEGIN

@interface FHGCameraMeasurementView : UIView <FHGViewsProtocol>

//- (id)initWithContentView:(UIView *const)superView;
- (id)init;
- (void)createMainViewWithSafeLayoutGuide:(UILayoutGuide *const)guide;

- (UIView *)viewWithTag:(const NSInteger)tag;
- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector;

- (void)setupCameraViewWithCaptureSession:(AVCaptureSession *const)captureSession;
- (CALayer *)roiLayer;
- (CATextLayer *)instructionsLayer;


@end

NS_ASSUME_NONNULL_END
