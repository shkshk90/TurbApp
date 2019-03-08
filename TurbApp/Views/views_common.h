//
//  views_common.h
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef views_common_h
#define views_common_h

@protocol FHGViewsProtocol <NSObject>

//- (id)initWithContentView:(UIView *const)superView;
- (void)createMainViewWithSafeLayoutGuide:(UILayoutGuide *const)guide;
- (UIView *)viewWithTag:(const NSInteger)tag;

- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector;

@optional
- (void)setTextFieldDelegateAndTarget:(UIViewController<UITextFieldDelegate> *const)target withSelector:(const SEL)selector;


@end

#endif /* views_common_h */
