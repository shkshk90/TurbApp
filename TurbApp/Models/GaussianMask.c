//
//  GaussianMask.c
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#include "GaussianMask.h"
#import "fhgm_c_private_resources.h"


vImage_Buffer
fhgm_gm_create_gaussian_mask_float(const size_t block_size)
{
    vImage_Buffer mask;
    const vImage_Error err = vImageBuffer_Init(&mask,
                                               (vImagePixelCount)block_size,
                                               (vImagePixelCount)block_size,
                                               sizeof(Pixel_F) * 8,
                                               VIMAGE_FLAG);
    
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in allocating mask  =>  %ld", err);
    
    Pixel_F *const mask_data = (Pixel_F *)mask.data;
    
    // Gaussian Data
    const float sigma = (float)(block_size) / 2.;
    
    const float a = 1. / (2. * M_PI * sigma * sigma);
    const float s = 2. * sigma * sigma;
    const float r = ((float)(block_size) - 1.) / 2.;
    
    
    for (size_t i = 0; i < block_size; ++i) {
        for (size_t j = 0; j < block_size; ++j) {
            const float ei_r = i - r;
            const float je_r = j - r;
            
            const float eir2 = ei_r * ei_r;
            const float jer2 = je_r * je_r;
            
            const float exponent = -((eir2 + jer2) / s);
            const float exp_val  = expf(exponent);
            
            const float gaussian_val = a * exp_val;
            
            mask_data[i * block_size + j] = gaussian_val;
        }
    }
    
    return mask;
}

vImage_Buffer
fhgm_gm_multiply_block_by_gaussian(const vImage_Buffer *const restrict block,
                              const vImage_Buffer *const restrict mask,
                              const size_t block_size)
{
    vImage_Buffer blurred_block;
    const vImage_Error err = vImageBuffer_Init(&blurred_block,
                                               (vImagePixelCount)block_size,
                                               (vImagePixelCount)block_size,
                                               sizeof(Pixel_F) * 8,
                                               VIMAGE_FLAG);
    
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in allocating blurred block  =>  %ld", err);
    
    float *const block_data = (float *)(block->data);
    float *const mask_data  = (float *)(mask->data);
    float *const blurred_block_data = (float *)(blurred_block.data);
    
    
    vDSP_vmul(block_data,
              1,
              mask_data,
              1,
              blurred_block_data,
              1,
              block_size * block_size);
    
    return blurred_block;
}

void
fhgm_gm_multiply_block_by_gaussian_fill(const vImage_Buffer *const restrict block,
                                   const vImage_Buffer *const restrict mask,
                                   const size_t block_size,
                                   float *const restrict blurred_block_data)
{
    float *const block_data = (float *)block->data;
    float *const mask_data  = (float *)mask->data;
    
    vDSP_vmul(block_data,
              1,
              mask_data,
              1,
              blurred_block_data,
              1,
              block_size * block_size);
}

void
fhgm_gm_print_gaussian_mask(const vImage_Buffer *const restrict mask)
{
    const float *const data = (float *)mask->data;
    const size_t bs = (size_t)mask->width;
    
    for (size_t i = 0; i < bs; ++i) {
        printf("%zu -->  ", i);
        
        for (size_t j = 0; j < bs; ++j) printf("%f,  ", data[i * bs + j]);
        
        printf("\n");
    }
}
