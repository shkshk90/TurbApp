//
//  views_resources.h
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef views_resources_h
#define views_resources_h

#import <Foundation/Foundation.h>


#pragma mark - First Screen View Resources
/******************* First Screen View *************************/
static const CGFloat kFSVNavigationBarPercentage = 10.;

static const CGFloat kFSVVerticalPercentage   = 15.;
static const CGFloat kFSVHorizontalPercentage = 5.;

#define FSV_IMAGEVIEW_RES     @"FSV_Background"

#define FSV_RECORDBTN_IMG_RES @"FSV_LiveCapture"
#define FSV_VIDEOBTN_IMG_RES  @"FSV_SelectVideo"

#define FSV_RECORDBTN_TXT_RES @"Live Capture"
#define FSV_VIDEOBTN_TXT_RES  @"Select Video"
/***************************************************************/


#pragma mark - Camera Measurement View Resources
/******************* Camera Measurement View *************************/

static const CGFloat kCMVExitSideP = 16.;
static const CGFloat kCMVSettSideP = 15.;
static const CGFloat kCMVCaptSideP = 30.;

#define CMV_EXITBTN_IMG_RES      @"CMV_Exit"
#define CMV_SETTINGSBTN_IMG_RES  @"CMV_Settings"
#define CMV_CAPTUREBTN_IMG_RES   @"CMV_Capture"

#define CMV_INSTRUCTIONS_TXT_RES @"Set settings first!"
/*********************************************************************/


#pragma mark - Experiment Parameters View Resources
/******************* Experiment Parameters View *************************/
static const CGFloat kEPVTopSpacingPercentage    = 3.;
static const CGFloat kEPVBottomSpacingPercentage = 25.;
static const CGFloat kEPVRightSpacingPercentage  = 3.;
static const CGFloat kEPVViewSpacingPercentage   = 4.;

static const CGFloat kEPVStartingSamplesCount    = 30.;

#define EPV_WIDTH_IMG_RES     @"EPV_Width"
#define EPV_HEIGHT_IMG_RES    @"EPV_Height"

#define EPV_F_SMPL_IMG_RES    @"EPV_MinSamples"
#define EPV_M_SMPL_IMG_RES    @"EPV_MaxSamples"

#define EPV_LABEL_DIST_RES    @"Distance [m]:"
#define EPV_LABEL_APRT_RES    @"Aperture [mm]:"
#define EPV_LABEL_LENG_RES    @"Length of scene [m]:"
#define EPV_LABEL_BLKS_RES    @"Single block size [px]:"
#define EBV_LABEL_SMPL_RES    @"Number of Frames:"

#define EPV_PHLDR_WDTH_RES   @"Enter scene width in meters."
#define EPV_PHLDR_HOCH_RES   @"Enter scene height in meters."

#define EPV_PHLDR_DIST_RES    @"Enter Distance in meters."
#define EPV_PHLDR_APRT_RES    @"Enter aperture size in millimeters."
#define EPV_PHLDR_BLKS_RES    @""

#define EPV_SEGCL_BS_ARR_RES  @[ @"16", @"32", @"64", @"128" ]

/*********************************************************************/


#pragma mark - Storage Measurement View Resources
/******************* Storage Measurement View *************************/
static const CGFloat kSMVTopSpacingPercentage     = 3.;
static const CGFloat kSMVBottomSpacingPercentage  = 10.;
static const CGFloat kSMVRightSpacingPercentage   = 3.;
static const CGFloat kSMVViewSpacingPercentage    = 5.;

static const CGFloat kSMVCn2SpacingPercentage = 25.;

#define SMV_STEP1_TXT_RES       @"1. Select Video to Process:"
#define SMV_STEP2_TXT_RES       @"2. Set Parameters:"
#define SMV_STEP3_TXT_RES       @"3. Calculate Cn2:"

#define SMV_LABELS_FONT_RES     @"GillSans"

#define SMV_PREVIEW_IMG_RES     @"SMV_DefaultPreview"

#define SMV_RESTART_ICN_RES     @"SMV_Restart"
#define SMV_SETTINGS_ICN_RES    @"SMV_Settings"
#define SMV_LAUNCH_ICN_RES      @"SMV_Launch"

#define SMV_BACKBUTTON_IMG_RES  @"SMV_BackButton"
/**********************************************************************/





#define FHGV_SCREEN_HEIGHT(P) (CGRectGetHeight([UIScreen mainScreen].bounds) * 0.01 * (CGFloat)(P))
#define FHGV_SCREEN_WIDTH(P)  (CGRectGetWidth( [UIScreen mainScreen].bounds) * 0.01 * (CGFloat)(P))


#pragma mark - C functions

NS_INLINE CGFloat
fhgv_getPercentageOfScreenHeight(const CGRect screenBounds, const CGFloat percentage)
{
    const CGFloat screenHeight  = CGRectGetHeight(screenBounds);
    
    const CGFloat spacing       = screenHeight * 0.01 * (CGFloat)percentage; // % of the screen
    
    return spacing;
}

NS_INLINE CGFloat
fhgv_getPercentageOfScreenWidth(const CGRect screenBounds, const CGFloat percentage)
{
    const CGFloat screenWidth   = CGRectGetWidth(screenBounds);
    
    const CGFloat spacing       = screenWidth * 0.01 * (CGFloat)percentage; // % of the screen
    
    return spacing;
}

NS_INLINE NSInteger
fhgv_indexForBlockSize(const NSInteger size)
{
    NSInteger result = 0;
    
    switch (size) {
        case 16:
            result = 0;
            break;
        case 32:
            result = 1;
            break;
        case 64:
            result = 2;
            break;
        case 128:
            result = 3;
            break;
        default:
            break;
    }
    
    return result;
}
#endif /* views_resources_h */
