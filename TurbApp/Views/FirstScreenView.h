//
//  FirstScreenView.h
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "views_common.h"

NS_ASSUME_NONNULL_BEGIN

@interface FHGFirstScreenView : UIView <FHGViewsProtocol>

- (id)initWithContentView:(UIView *)superView;
- (UIView *)viewWithTag:(const NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
