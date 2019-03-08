//
//  UIViewController+UIViewController_FHGViewAddition.m
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "UIViewController+UIViewController_FHGViewAddition.h"

@implementation UIViewController (UIViewControllerFHGViewAddition)

- (void)fhg_addMainSubView:(UIView<FHGViewsProtocol> *const)subView
{
    [self.view addSubview:subView];
    [subView createMainViewWithSafeLayoutGuide:self.view.safeAreaLayoutGuide];
    
    NSLog(@"From controller %@: View %@ appeared",
          NSStringFromClass([self class]),
          NSStringFromClass([subView class]));
}


@end
