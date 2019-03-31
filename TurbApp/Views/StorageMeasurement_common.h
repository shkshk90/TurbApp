//
//  StorageMeasurement_common.h
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef StorageMeasurement_common_h
#define StorageMeasurement_common_h

typedef NS_ENUM(NSInteger, FHGTagStorageMeasurementSteps) {
    FHGTagSMVStepOne    = 1,
    FHGTagSMVStepTwo    = 2,
    FHGTagSMVStepThree  = 3,
};

typedef NS_ENUM(NSInteger, FHGTagStorageMeasurementButtonTags) {
    FHGTagSMVResetButton    = 4,
    FHGTagSMVSettingsButton = 5,
    FHGTagSMVLaunchButton   = 6,
};

typedef NS_ENUM(NSInteger, FHGTagStorageMeasurementViewsTags) {
    FHGTagSMVPreview        = 7,
    FHGTagSMVDebugStackView  = 8,
};

#endif /* StorageMeasurement_common_h */
