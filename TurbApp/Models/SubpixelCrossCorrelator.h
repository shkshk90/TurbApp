//
//  SubpixelCrossCorrelator.h
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef SubpixelCrossCorrelator_h
#define SubpixelCrossCorrelator_h

#import <stdio.h>
#import <Accelerate/Accelerate.h>


// Call once for rows and once for columns
// kernel_1 size should be: BlockSize
// Kernel_2 size should be: 2 * BlockSize ?????
void
fhgm_spxc_create_kernels(float *const restrict kernel_side,
                  float *const restrict kernel_square,
                  const size_t block_size);

// AGAIN, CALL ONCE FOR ROWS, ONCE FOR COLUMNS
// KERNEL SHOULD BE ALLOCATED WITH 2 ARRAYS
// EACH WITH SIZE OF BLOCK_SIZE
// TEMP SHOULD BE ALLOCATED WITH 2 * BLOCKSIZE (NOT BLOCKSIZE SQUARED)
void
fhgm_spxc_create_complex_kernel(const DSPSplitComplex *const restrict n_kernel,
                         const size_t block_size,
                         const size_t upscale,
                         void *const restrict temp);


// XCORR2
// The input are the reference and the sample block AFTER FFT (VIP)
CGPoint
fhgm_spxc_correlate_two_blocks_no_scale(const DSPSplitComplex *const restrict ref_block,
                                 const DSPSplitComplex *const restrict smp_block,
                                 const DSPSplitComplex *const restrict tmp_block,   // Spectrum output, TEMP buffer in other words
                                 const float *const restrict side_kernel,
                                 const size_t log_two_of_blockSize);
/*
 *      tmp_block has 2 pointers, each allocated with  13 * blockSizeSquared
 *      5 = 1 (1 normal block) + 3 * (4 * blockSizeSquared == 2*blockSize * 2*blockSize)
 *      THIS IS REALLY IMPORTANT
 *      1 tmp normal size
 *      1 middle temp for FTPad
 *      2 output temps for FTPad
 *      Roughly looks like:
 *
 *       ---  --- ---  --- ---  --- ---
 *      |  | |   |   ||   |   ||   |   |
 *      ---  ---  --- ---  --- ---  ---
 *          |   |   ||   |   ||   |   |
 *          ---  --- ---  --- ---  ---
 *
 *  tmp_block HAS 2 POINTERS, FOR EACH THE ALLOCATION SHOULD BE:
 *  14 * BLOCKSIZE_SQUARED
 *  14 = 2 * NORMAL BLOCK + 3 * 4 * NORMAL BLOCK ==> 4 * NORMAL BLOCK = 2 * SIDE * 2 * SIDE
 *      1 TEMP NORMAL SIZE
 *      1 OUTPUT OF MUL SPECTRUM
 *      1 BIG TMP
 *      1 BIG OUT OF FTPAD
 *      1 BIG OUT OF FFT
 *
 *  IT LOOKS ROUGHLY LIKE:
 *       ---     ----     --- ---        --- ---
 *      |  | .. |   | .. |   |   |  ..  |   |   | .. ANOTHER ONE
 *      ---     ----     ---- ---       ---- ---
 *                      |   |   |      |   |   |
 *                      ---- ---       ---- ---
 *
 *
 *
 *
 *
 */
CGPoint
fhgm_spxc_correlate_two_blocks_half_pixel(const DSPSplitComplex *const restrict ref_block,
                                   const DSPSplitComplex *const restrict smp_block,
                                   const DSPSplitComplex *const restrict tmp_block,
                                   const float *const restrict square_kernel,
                                   const size_t log_two_of_blockSize,
                                   const FFTSetup setup);

/*
 *  SIZE OF POINTERS IN DFTUPS_TMP_BLOCK SHOULD BE EACH:
 *      IF usfac1p5 is SCALING_FACTOR * 1.5, THEN EACH POINTER:
 *      2 * USFAC1P5^2  +  2 * USFAC1P5  +  2 * USFAC1P5 * BLOCKSIZE
 *      WHERE:
 *          - 2 * USFAC1P5^2 ARE THE OUTPUT BLOCK & A TEMP OUTPUT BLOCK
 *          - 2 * USFAC1P5 ARE THE NOC AND NOR
 *          - 2 * USFAC1P5 * BLOCKSIZE ARE 2 MATRICES HOLDING NOC * NC OR NOR * NR
 *
 *  Done And Tested :D :D
 *
 */
CGPoint
fhgm_spxc_correlate_two_blocks_sub_pixel(const DSPSplitComplex *const restrict ref_block,
                                  const DSPSplitComplex *const restrict smp_block,
                                  const DSPSplitComplex *const restrict tmp_block,
                                  const float *const restrict square_kernel,
                                  const DSPSplitComplex *const restrict complex_kernel,
                                  const size_t log_two_of_blockSize,
                                  const FFTSetup setup,
                                  const size_t scaling_factor,
                                  const DSPSplitComplex *const restrict dftups_tmp_block);

CGPoint
fhgm_spxc_correlate_two_blocks(const vImage_Buffer *const restrict cmplx_ref_block,
                        const vImage_Buffer *const restrict cmplx_smp_block,
                        const void *const restrict tmp_buf);




#pragma mark - Functions for testing
void fct_ftpad(const DSPSplitComplex *const restrict input,
               const DSPSplitComplex *const restrict output,
               const size_t block_size,
               const DSPSplitComplex *const restrict tmp_block,
               const DSPSplitComplex *const restrict tmp_half_pixel_block);

#endif /* SubpixelCrossCorrelator_h */
