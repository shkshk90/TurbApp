//
//  ExperimentParameters_common.h
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef ExperimentParameters_common_h
#define ExperimentParameters_common_h

typedef NS_ENUM(NSInteger, FHGTagExperimentParametersViews) {
    FHGTagEPVViewMainScrollView  = 1,
    FHGTagEPVViewSamplesSlider   = 10,
};

typedef NS_ENUM(NSInteger, FHGTagExperimentParametersTextField) {
    FHGTagEPVTextFieldDistance      = 2,
    FHGTagEPVTextFieldAperture      = 3,
    FHGTagEPVTextFieldLength        = 4,
    FHGTagEPVTextFieldSamplesCount  = 5,
};

typedef NS_ENUM(NSInteger, FHGTagExperimentParametersSegmentedControl) {
    FHGTagEPVSegControlLength    = 6,
    FHGTagEPVSegControlBlockSize = 7,
};

typedef NS_ENUM(NSInteger, FHGTagExperimentParametersLengthOfScene) {
    FHGTagEPVSceneWidth          = 8,
    FHGTagEPVSceneHeight         = 9,
};

#endif /* ExperimentParameters_common_h */
