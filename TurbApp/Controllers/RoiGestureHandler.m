//
//  RoiGestureHandler.m
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "RoiGestureHandler.h"

@import UIKit;

NS_INLINE CGRect moveFrame(const CGRect rect, const CGPoint point);
NS_INLINE CGRect calculateScaledFrame(const CGRect rect, const CGFloat scale);


#pragma mark - Interface
@interface FHGRoiGestureHandler () <UIGestureRecognizerDelegate>

@end

#pragma mark - Implementation + members
@implementation FHGRoiGestureHandler {
@private UIView                     *_contentView;
@private CALayer                    *_roiLayer;
    
@private UITapGestureRecognizer     *_tapGestureRecognizer;
@private UIPinchGestureRecognizer   *_pinchGestureRecognizer;
@private UIPanGestureRecognizer     *_panGestureRecognizer;
    
@private CGFloat                    _roiWidth;
@private CGFloat                    _roiHeight;
}

#pragma mark - Public methods
- (id)initWithView:(UIView *const)view forROI:(CALayer *const)layer
{
    self = [super init] ?: nil;
    
    if (self == nil)
        return nil;
    
    const CGRect layerFrame = layer.frame;
    
    _contentView = view;
    _roiLayer    = layer;
    
    _tapGestureRecognizer   = [[UITapGestureRecognizer alloc]   initWithTarget:nil action:NULL];
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:nil action:NULL];
    _panGestureRecognizer   = [[UIPanGestureRecognizer alloc]   initWithTarget:nil action:NULL];
    
    _roiWidth  = CGRectGetWidth(layerFrame);
    _roiHeight = CGRectGetHeight(layerFrame);
    
    [_tapGestureRecognizer   setDelegate:self];
    [_pinchGestureRecognizer setDelegate:self];
    [_panGestureRecognizer   setDelegate:self];
    
    [view addGestureRecognizer:_tapGestureRecognizer];
    [view addGestureRecognizer:_pinchGestureRecognizer];
    [view addGestureRecognizer:_panGestureRecognizer];
    
    return self;
}

- (void)enableTapOnlywithTarget:(UIViewController *const)target action:(const SEL)action
{
    [_tapGestureRecognizer   setEnabled:YES];
    [_panGestureRecognizer   setEnabled:NO];
    [_pinchGestureRecognizer setEnabled:NO];
    
    [_tapGestureRecognizer removeTarget:nil action:NULL];
    [_tapGestureRecognizer addTarget:target action:action];
}

- (void)enableAllGestures
{
    [_tapGestureRecognizer   removeTarget:nil action:NULL];
    [_pinchGestureRecognizer removeTarget:nil action:NULL];
    [_panGestureRecognizer   removeTarget:nil action:NULL];
    
    [_tapGestureRecognizer   addTarget:self action:@selector(changeRoiLocation:)];
    [_pinchGestureRecognizer addTarget:self action:@selector(handlePinchGesture:)];
    [_panGestureRecognizer   addTarget:self action:@selector(dragRoi:)];
    
    [_tapGestureRecognizer   setEnabled:YES];
    [_panGestureRecognizer   setEnabled:YES];
    [_pinchGestureRecognizer setEnabled:YES];
}

#pragma mark - Gesture methods
- (void)dragRoi:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            [self changeRoiLocation:gestureRecognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
            _roiWidth  = _roiLayer.frame.size.width;
            _roiHeight = _roiLayer.frame.size.height;
            break;
        default:
            break;
    }
}

- (void)changeRoiLocation:(UIGestureRecognizer *)gestureRecognizer
{
    const CGRect newFrame = moveFrame(_roiLayer.frame, [gestureRecognizer locationInView:_contentView]);
    
    if (CGRectContainsRect(_contentView.bounds, newFrame)) {
        [_roiLayer setFrame:newFrame];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self changeRoiLocation:gestureRecognizer];
            break;
            
        case UIGestureRecognizerStateChanged: {
            
            const CGRect newFrame = calculateScaledFrame(_roiLayer.frame, gestureRecognizer.scale);
            if (CGRectContainsRect(_contentView.bounds, newFrame))
                [_roiLayer setFrame:newFrame];
            
            [gestureRecognizer setScale:1.];
            break;
        }
            
        case UIGestureRecognizerStateEnded:
            _roiWidth  = _roiLayer.frame.size.width;
            _roiHeight = _roiLayer.frame.size.height;
            break;
        default:
            break;
    }
}

@end

#pragma mark - C functions

NS_INLINE
CGRect moveFrame(const CGRect rect, const CGPoint point)
{
    const CGFloat newX      = point.x - (rect.size.width / 2.);
    const CGFloat newY      = point.y - (rect.size.height / 2.);
    
    const CGRect newFrame   = CGRectMake(newX, newY, rect.size.width, rect.size.height);
    
    return newFrame;
}

NS_INLINE
CGRect calculateScaledFrame(const CGRect rect, const CGFloat scale)
{
    const CGFloat newWidth      = rect.size.width  * scale;
    const CGFloat newHeight     = rect.size.height * scale;
    
    const CGFloat diffInWidth   = newWidth  - rect.size.width;
    const CGFloat diffInHeight  = newHeight - rect.size.height;
    
    const CGFloat newX          = rect.origin.x - (diffInWidth  / 2.);
    const CGFloat newY          = rect.origin.y - (diffInHeight / 2.);
    
    return CGRectMake(newX, newY, newWidth, newHeight);
}

