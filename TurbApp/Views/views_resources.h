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
static const CGFloat FSVNavigationBarPercentage = 10.;

static const CGFloat FSVVerticalPercentage   = 15.;
static const CGFloat FSVHorizontalPercentage = 5.;

#define FSV_IMAGEVIEW_RES @"FSV_Background"

#define FSV_RECORDBTN_IMG_RES @"FSV_LiveCapture"
#define FSV_VIDEOBTN_IMG_RES  @"FSV_SelectVideo"

#define FSV_RECORDBTN_TXT_RES @"Live Capture"
#define FSV_VIDEOBTN_TXT_RES  @"Select Video"
/***************************************************************/





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

#endif /* views_resources_h */
