//
//  CameraPreviewSubView.h
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVCaptureVideoPreviewLayer;
@class AVCaptureSession;

@interface FHGCameraPreviewSubView : UIView

@property (readonly, nonatomic) AVCaptureVideoPreviewLayer  *videoPreviewLayer;
@property (nonatomic)           AVCaptureSession            *session;

@end

NS_ASSUME_NONNULL_END
