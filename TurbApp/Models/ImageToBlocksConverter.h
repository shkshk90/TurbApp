//
//  ImageToBlocksConverter.h
//  TurbApp
//
//  Created by Samuel Aysser on 20.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef ImageToBlocksConverter_h
#define ImageToBlocksConverter_h

#include <stdio.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Accelerate/Accelerate.h>

struct FhgData;

// Step One, Crop the full image to ROI
vImage_Buffer
fhgmCropFrameAndGetRoi(const CGImageRef cg_image,
                       const vImage_CGImageFormat *const restrict format,
                       const struct FhgData *const restrict data,
                       void *const restrict temp1CG,      // SIZEOF CGIMAGE
                       void *const restrict temp2CG,      // SIZEOF CGIMAGE
                       void *const restrict temp3Roi);    // SIZEOF ROI (OUTPUT, DO NOT RE-USE WITH OTHER FUNCTIONS)


// Step Two, FROM BGRA, EXTRACT THE BLUE PLANE
vImage_Buffer
fhgmExtractPlaneNFromRoi(const vImage_Buffer *const restrict imageBuffer,
                         const long plane_num,
                         void *const restrict temp_buffer); // SIZEOF ROI

// STEP THREE, CONVERT BYTES IN PLANE TO FLOATS
vImage_Buffer
fhgmConvertPlaneBytesToFloats(const vImage_Buffer *const restrict imageBuffer,
                              void *const restrict temp_buffer);

// STEP FOUR, FROM VIMAGE_BUFFER, FILL A RAW BUFFER
void
fhgmFillBufferWithBlocks(const vImage_Buffer *const restrict roiBuffer,
                         float *const restrict blockRawBuffer,
                         const struct FhgData *const restrict data);


/***************************************** OLD *********************************************************/
// Step One, Crop the full image to ROI
vImage_Buffer
fhgmCropLargeImageGetRoi(const CGImageRef cg_image,
                         const vImage_CGImageFormat *const restrict format,
                         const CGRect *const restrict regionOfInterest,
                         void *const restrict temp1CG,      // SIZEOF CGIMAGE
                         void *const restrict temp2CG,      // SIZEOF CGIMAGE
                         void *const restrict temp3Roi);    // SIZEOF ROI (OUTPUT, DO NOT RE-USE WITH OTHER FUNCTIONS)


// STEP FOUR, FROM VIMAGE_BUFFER, FILL A RAW BUFFER
void
fhgmGetBlockAndFillBuffer(const vImage_Buffer *const restrict roiBuffer,
                          float *const restrict blockRawBuffer,
                          const size_t blockSize,
                          const size_t sideBlocksCount);


#endif /* ImageToBlocksConverter_h */
