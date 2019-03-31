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

/************** MACROS ******************************************************************/
#define FHG_ALIGN_PTR(P) do { \
    const uintptr_t ptrAlignment = (uintptr_t)(P) & 15; \
    if (ptrAlignment != 0) \
        (P) = (P) + (16 - ptrAlignment); \
} while (NO);

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

#define FHG_RAISE_EXCEPTION(EXCEPTION_NAME, DESCRIPTION, ...) do { \
    [NSException raise:EXCEPTION_NAME \
        format:@"[%s:%d %s]: ]" DESCRIPTION, \
        __FILENAME__, __LINE__, __FUNCTION__, __VA_ARGS__]; \
} while(NO)

#define FHG_NS_LOG(MESSAGE, ...) do { \
    NSLog(@"[%s:%d  %s] " MESSAGE, \
        __FILENAME__, __LINE__, __FUNCTION__, __VA_ARGS__); \
} while(NO)

#define FHG_TAG_NOT_HANDLED do { \
    [NSException raise:@"TagNotHandledException" \
        format:@"[%s:%d %s]: Tag is not handled", \
        __FILENAME__, __LINE__, __FUNCTION__]; \
} while(NO)

#define FHG_NS_ASSERT(CONDITION, ERROR_MSG, ...) do { \
    NSAssert4(CONDITION, \
              @"[%s:%d %s]:" ERROR_MSG, \
              __FILENAME__, __LINE__, __FUNCTION__, __VA_ARGS__); \
} while (NO);
/****************************************************************************************/


/************ Constants *****************************************************************/
static const NSUInteger kFHGMaximumCountOfSamples  = 120;
static const NSUInteger kFHGMaximumCountOfFrames   = kFHGMaximumCountOfSamples + 1;

static const CGFloat    kFHGMaximumNumberOfSamples = (CGFloat)kFHGMaximumCountOfSamples;
static const CGFloat    kFHGMinimumNumberOfSeconds = 9.;

static const int64_t    kFHGNumberOfSecondsToSkip  = 3;

static const NSUInteger kFHGMaximumVideoHeight     = 2160;
static const NSUInteger kFHGMaximimVideoWidth      = 3840;

/****************************************************************************************/

/**** Experiment-Related ****************************************************************/
#define FHGK_EXP_PARAM_DISTANCE_TO_TARGET       @"Distance To Target"
#define FHGK_EXP_PARAM_APERTURE_SIZE            @"Aperture"
#define FHGK_EXP_PARAM_LENGTH_OF_SCENE          @"Scene Length"
#define FHGK_EXP_PARAM_BLOCK_SIZE               @"Block Size"
#define FHGK_EXP_PARAM_NUMBER_OF_SAMPLES        @"Samples Count"
#define FHGK_EXP_PARAM_PIXELS_IN_SCENE          @"Scene Pixels"
#define FHGK_EXP_PARAM_SUBPIXEL_UPSCALE         @"Subpixel upscale"


@protocol FHGProtocolExperimentParametersDelegate <NSObject>

@required
@property (strong,   nonatomic) NSDictionary  *experimentDataDict;
@property (readonly, nonatomic) CGSize         videoSize;
//- (nullable NSDictionary *)loadExperimentData;
//- (void)save:(NSDictionary *const)experimentData;


@end

@protocol FHGProtocolDebuggableControllerDelegate <NSObject>

@required

- (UIView *)debugView;


@end

/****************************************************************************************/

#endif /* common_h */
