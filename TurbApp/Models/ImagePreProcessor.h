//
//  ImagePreProcessor.h
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef ImagePreProcessor_h
#define ImagePreProcessor_h

#include <stdio.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Accelerate/Accelerate.h>

// Step One, Crop the full image to ROI
vImage_Buffer
fhgm_ipp_crop_pixel_buffer(CVPixelBufferRef imageBuffer,
                           const CGRect *const restrict regionOfInterest,
                           void *const restrict temp_buffer);

vImage_Buffer
fhgm_ipp_crop_CG_Image(const CGImageRef cg_image,
                       const vImage_CGImageFormat *const restrict format,
                       const CGRect *const restrict regionOfInterest,
                       void *const restrict temp_buffer);

// Step Two, FROM BGRA, EXTRACT THE BLUE PLANE
vImage_Buffer
fhgm_ipp_extract_plane_from_bgra_planar8(const vImage_Buffer *const restrict imageBuffer,
                                         const long plane_num,
                                         void *const restrict temp_buffer);

// STEP THREE, CONVERT BYTES IN PLANE TO FLOATS
vImage_Buffer
fhgm_ipp_convert_bytes_to_floats(const vImage_Buffer *const restrict imageBuffer,
                                 void *const restrict temp_buffer);


// STEP FOUR, FROM VIMAGE_BUFFER, FILL A RAW BUFFER
void
fhgm_ipp_cut_image_into_raw_blocks_F(const vImage_Buffer *const restrict roiBuffer,
                                     float *const restrict blockRawBuffer,
                                     const size_t blockSize,
                                     const size_t sideBlocksCount);


/********************** FOR TESTING ****************************************/
vImage_Buffer
fc_convert_floats_to_bytes(const vImage_Buffer *const restrict imageBuffer,
                           void *const restrict temp_buffer);

void
fc_cut_image_into_blocks_F(const vImage_Buffer *const restrict roiBuffer,
                           vImage_Buffer *const restrict blockBuffer,
                           const size_t blockSize,
                           void *const restrict temp_buffer);

void
fc_cut_image_into_blocks_8(const vImage_Buffer *const restrict roiBuffer,
                           vImage_Buffer *const restrict blockBuffer,
                           const size_t blockSize,
                           void *const restrict temp_buffer);

#endif /* ImagePreProcessor_h */
