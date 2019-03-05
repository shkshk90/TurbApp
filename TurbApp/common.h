//
//  common.h
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//
//

#ifndef common_h
#define common_h

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

#define FHG_TAG_NOT_HANDLED do { \
[NSException raise:@"TagNotHandledException" \
format:@"[%s:%d %s]: Tag is not handled", \
__FILENAME__, __LINE__, __FUNCTION__]; \
} while(NO);

static const CGFloat kFHGMaximumNumberOfSamples = 120.;

@protocol ExperimentDataProtocol <NSObject>

- (void)setExperimentDataWithDict:(NSDictionary *)dict;

@end

#endif /* common_h */
