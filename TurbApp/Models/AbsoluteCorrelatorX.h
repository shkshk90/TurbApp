//
//  AbsoluteCorrelatorX.h
//  TurbApp
//
//  Created by Samuel Aysser on 26.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "../common.h"

NS_ASSUME_NONNULL_BEGIN

@interface FHGAbsoluteCorrelatorX : NSObject

@property (readonly, nonatomic) NSMutableArray                              *tipTiltValues;
@property (weak,     nonatomic) id<FHGProtocolDebuggableControllerDelegate>  delegate;

- (void)play;
- (void)freeMemory;

- (void)setVideoUrl:(AVURLAsset *const)asset;
- (void)setExperimentData:(NSDictionary *const)dataDict;
- (void)setRoiFrame:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
