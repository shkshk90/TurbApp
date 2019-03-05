//
//  ExperimentParametersViewController.h
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../common.h"

NS_ASSUME_NONNULL_BEGIN

@interface FHGExperimentParametersViewController : UIViewController

@property (weak, nonatomic) id<ExperimentDataProtocol> delegate;

@end

NS_ASSUME_NONNULL_END
