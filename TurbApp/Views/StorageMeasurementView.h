//
//  StorageMeasurement.h
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "views_common.h"

NS_ASSUME_NONNULL_BEGIN

@interface FHGStorageMeasurementView : UIView <FHGViewsProtocol>

- (id)initWithContentView:(UIView *const)superView;
- (UIView *)viewWithTag:(const NSInteger)tag;

- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector;

- (CALayer *)roiLayer;

@end

NS_ASSUME_NONNULL_END
