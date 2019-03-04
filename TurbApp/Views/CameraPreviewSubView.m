//
//  CameraPreviewSubView.m
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "CameraPreviewSubView.h"

@import AVFoundation;

@implementation FHGCameraPreviewSubView

+ (Class) layerClass {
    return [AVCaptureVideoPreviewLayer class];
    //    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)[self layer];
}

- (AVCaptureSession *) session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *) session
{
    self.videoPreviewLayer.session = session;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
