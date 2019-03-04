//
//  RoiGestureHandler.h
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface FHGRoiGestureHandler : NSObject 

- (id)initWithView:(UIView *const)view forROI:(CALayer *const)layer;
- (void)enableTapOnlywithTarget:(UIViewController *const)target action:(const SEL)action;
- (void)enableAllGestures;

@end

NS_ASSUME_NONNULL_END
