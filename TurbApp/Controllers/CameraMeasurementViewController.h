//
//  CameraMeasurementViewController.h
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FHGCameraMeasurementViewController : UIViewController

@property (strong,   nonatomic) NSDictionary  *experimentDataDict;
@property (readonly, nonatomic) CGSize         videoSize;

@end

NS_ASSUME_NONNULL_END
