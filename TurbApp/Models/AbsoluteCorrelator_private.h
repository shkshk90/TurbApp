//
//  AbsoluteCorrelator_private.h
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef AbsoluteCorrelator_private_h
#define AbsoluteCorrelator_private_h

#import "ImagePreProcessor.h"
#import "ModelsResources.h"

typedef CGPoint (^FHGMCorrelationBlock)(const DSPSplitComplex *const restrict ref,
                                        const DSPSplitComplex *const restrict smp);

NS_INLINE void
create_raw_blocks_from_pixels(const CVPixelBufferRef full_image,
                              float *const restrict blocks_buffer,
                              const size_t block_side,
                              const size_t block_count_per_roi_side,
                              const CGRect region_of_interest,
                              const FHGMRawBuffer *const restrict tmp_buffer)
{
    const vImage_Buffer croppedBufferBGRA  = fhgm_ipp_crop_pixel_buffer(full_image, &region_of_interest, tmp_buffer->buf);
    const vImage_Buffer croppedBufferROI   = fhgm_ipp_extract_plane_from_bgra_planar8(&croppedBufferBGRA, 0, tmp_buffer->buf + tmp_buffer->size2D);
    
    const vImage_Buffer croppedBufferROI_F = fhgm_ipp_convert_bytes_to_floats(&croppedBufferROI, tmp_buffer->buf);
    
    fhgm_ipp_cut_image_into_raw_blocks_F(&croppedBufferROI_F, blocks_buffer, block_side, block_count_per_roi_side);
    
    CVPixelBufferUnlockBaseAddress(full_image, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferRelease(full_image);
}

NS_INLINE void
create_raw_blocks_from_cg_image(const CGImageRef full_image,
                                const vImage_CGImageFormat *const restrict format,
                                float *const restrict blocks_buffer,
                                const size_t block_side,
                                const size_t block_count_per_roi_side,
                                const CGRect region_of_interest,
                                const FHGMRawBuffer *const restrict tmp_buffer)
{
    void *tempBufferOne = tmp_buffer->buf;
    void *tempBufferTwo = tmp_buffer->buf + tmp_buffer->size2D;
    
    const vImage_Buffer croppedBufferBGRA  = fhgm_ipp_crop_CG_Image(full_image, format, &region_of_interest, tempBufferOne);
    const vImage_Buffer croppedBufferROI   = fhgm_ipp_extract_plane_from_bgra_planar8(&croppedBufferBGRA, 0, tempBufferTwo);
    const vImage_Buffer croppedBufferROI_F = fhgm_ipp_convert_bytes_to_floats(&croppedBufferROI, tempBufferOne);

    fhgm_ipp_cut_image_into_raw_blocks_F(&croppedBufferROI_F, blocks_buffer, block_side, block_count_per_roi_side);
}

NS_INLINE void *
fhg_corr_malloc(const size_t size)
{
    void *const ptr = malloc(size);
    NSCAssert1(ptr != NULL, @"Error: pointer of size %lu is NULL\n", size);
    
    return ptr;
}

NS_INLINE void *
fhg_corr_calloc(const size_t count, const size_t size)
{
    void *const ptr = calloc(count, size);
    NSCAssert1(ptr != NULL, @"Error: pointer of size %lu is NULL\n", size);
    
    return ptr;
}

#endif /* AbsoluteCorrelator_private_h */
