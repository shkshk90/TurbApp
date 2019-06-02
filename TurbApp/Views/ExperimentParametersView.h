//
//  ExperimentParametersView.h
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "views_common.h"

NS_ASSUME_NONNULL_BEGIN

@interface FHGExperimentParametersView : UIView <FHGViewsProtocol>
  
//- (id)initWithContentView:(UIView *const)superView;
- (id)init;
- (void)createMainViewWithSafeLayoutGuide:(UILayoutGuide *const)guide;

- (UIView *)viewWithTag:(const NSInteger)tag;
- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector;
- (void)setTextFieldDelegateAndTarget:(UIViewController<UITextFieldDelegate> *const)target withSelector:(const SEL)selector;

- (void)changeLengthViewsToWidth:(const NSInteger)lengthOfScene;
- (void)fillTextField:(const NSInteger)fieldTag withData:(const CGFloat)value;
- (void)updateSegmentedControl:(const NSInteger)fieldTag withValue:(const NSUInteger)value;
- (void)setSliderTarget:(UIViewController *const)target withSelector:(const SEL)action;
// Add a change here 
@end

NS_ASSUME_NONNULL_END
