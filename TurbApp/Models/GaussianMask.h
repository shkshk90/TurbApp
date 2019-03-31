//
//  GaussianMask.h
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef GaussianMask_h
#define GaussianMask_h

#import <stdio.h>
#import <Accelerate/Accelerate.h>

vImage_Buffer
fhgm_gm_create_gaussian_mask_float(const size_t block_size);

vImage_Buffer
fhgm_gm_multiply_block_by_gaussian(const vImage_Buffer *const restrict block,
                                   const vImage_Buffer *const restrict mask,
                                   const size_t block_size);

void
fhgm_gm_multiply_block_by_gaussian_fill(const vImage_Buffer *const restrict block,
                                        const vImage_Buffer *const restrict mask,
                                        const size_t block_size,
                                        float *const restrict result);

void
fhgm_gm_print_gaussian_mask(const vImage_Buffer *const restrict mask);

#endif /* GaussianMask_h */
