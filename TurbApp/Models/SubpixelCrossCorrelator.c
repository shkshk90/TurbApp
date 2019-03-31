//
//  SubpixelCrossCorrelator.c
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "SubpixelCrossCorrelator.h"
#import <complex.h>

#pragma mark - Forward Declarations
static inline size_t calculate_block_size(const size_t log_2_block_size);
static inline size_t calculate_block_size_squared(const size_t log_2_block_size);

static inline size_t get_xjc_from_index(const vDSP_Length index, const size_t log_2_block_size);
static inline size_t get_yir_from_index(const vDSP_Length index, const size_t log_2_block_size);

static inline void ft_add_padding(const DSPSplitComplex *const restrict input,
                                  const DSPSplitComplex *const restrict output,
                                  const size_t block_size,
                                  const DSPSplitComplex *const restrict tmp_block,
                                  const DSPSplitComplex *const restrict tmp_half_pixel_block);
static inline void dft_upscale(const DSPSplitComplex *const restrict input,
                               const DSPSplitComplex *const restrict output_and_temp,
                               const float row_offset,
                               const float col_offset,
                               const size_t upscale_mul_one_half,
                               const size_t block_size,
                               const DSPSplitComplex *const restrict complex_kernel);

static inline void ifft_shift(float *const restrict vec, const float start, const float end);

/*
 *  output IS USUALLY A TEMP BLOCK, SHOULD BE ALLOC AND HAS THE SAME SIZE AS INPUT
 */
static inline void forward_fft2D_shift(const DSPSplitComplex *const restrict input,
                                       const DSPSplitComplex *const restrict output,
                                       const size_t block_size);
static inline void inverse_fft2D_shift(const DSPSplitComplex *const restrict input,
                                       const DSPSplitComplex *const restrict output,
                                       const size_t block_size);




#pragma mark - Main functions

void
fhgm_spxc_create_kernels(float *const restrict kernel_1,
                  float *const restrict kernel_2,
                  const size_t block_size)
{
    const float side_length = (float)block_size;
    
    const float floored_half_side = floorf(side_length / 2.);
    const float  ceiled_half_side = floorf(side_length / 2.);
    
    
    const float start_one = -1. * floored_half_side;
    const float end_one   = ceiled_half_side - 1.;
    
    const float start_two = -1. * side_length;
    const float end_two   = side_length - 1.;
    
    
    ifft_shift(kernel_1, start_one, end_one);
    ifft_shift(kernel_2, start_two, end_two);
}

// VDSP FUNC IS TESTED
// SHOULD BE WORKING
void
fhgm_spxc_create_complex_kernel(const DSPSplitComplex *const restrict n_kernel,
                         const size_t block_size,
                         const size_t upscale,
                         void *const restrict temp)
{
    static const float kZero = 0.;
    
    const float side_length = (float)block_size;
    const float half_side = floorf(side_length / 2.);
    
    const float start = -1. * half_side;
    const float end   = side_length - half_side - 1.;
    
    const float pi_expr_imag = (-2. * M_PI) / (float)(block_size * upscale);
    
    
    float *const real_vec = (float *)temp;
    float *const imag_vec = (float *)(temp + sizeof(float) * block_size);
    
    ifft_shift(real_vec, start, end);    // Size of real is blockSize
    vDSP_vclr(imag_vec, 1, block_size);
    
    const DSPSplitComplex shifted_vec = {
        .realp = real_vec,
        .imagp = imag_vec,
    };
    
    const DSPSplitComplex pi_expr = {
        .realp = (float *)&kZero,
        .imagp = (float *)&pi_expr_imag,
    };
    
    
    /*I couldn't do exp(cmplex) using vDSP */
    //    for (size_t i = 0; i < block_size; ++i) {
    //        const float complex arr_value   = real_vec[i] + 0 * I;
    //        const float complex cmplx_value = cexpf(arr_value * pi_expr);
    //
    //        n_kernel->realp[i] = crealf(cmplx_value);
    //        n_kernel->imagp[i] = cimagf(cmplx_value);
    //    }
    
    vDSP_zvzsml(&shifted_vec,
                1,
                &pi_expr,
                n_kernel,
                1,
                block_size);
}

void
fhgm_spxc_create_upscaled_complex_kernel(const DSPSplitComplex *const restrict up_scaled_kernel,
                                  const size_t upscale)
{
    static const float kZero = 0.;
    static const float kOne  = 1.;
    
    
    const size_t upscale_opf = (upscale * 15) / 10; // * 1.5
    
    vDSP_vramp(&kZero, &kOne, up_scaled_kernel->realp, 1, upscale_opf); // RAMP THE REAL PART
    vDSP_vclr(up_scaled_kernel->imagp, 1, upscale_opf);         // Zero the complex part
}

CGPoint
fhgm_spxc_correlate_two_blocks_no_scale(const DSPSplitComplex *const restrict ref_block,
                                 const DSPSplitComplex *const restrict smp_block,
                                 const DSPSplitComplex *const restrict spo_block,
                                 const float *const restrict side_kernel,
                                 const size_t log_two_of_blockSize)
{
    const vDSP_Length block_size_squared = (vDSP_Length)(calculate_block_size_squared(log_two_of_blockSize));
    
    vDSP_zvmul(ref_block,
               1,
               smp_block,
               1,
               spo_block,
               1,
               block_size_squared,
               -1);
    
    // Use temp buffer after the current block
    float *const magnitudes_arr = (float *)(spo_block->realp + sizeof(float) * block_size_squared);
    
    vDSP_vdist(spo_block->realp, 1, spo_block->imagp, 1, magnitudes_arr, 1, block_size_squared);
    
    float max_val;
    vDSP_Length max_index;
    
    vDSP_maxvi(magnitudes_arr,
               1,
               &max_val,
               &max_index,
               block_size_squared);
    
    
    const size_t max_y_row_index = get_yir_from_index(max_index, log_two_of_blockSize);
    const size_t max_x_col_index = get_xjc_from_index(max_index, log_two_of_blockSize);
    
    const float y_row_shift = side_kernel[max_y_row_index];
    const float x_col_shift = side_kernel[max_x_col_index];
    
    const CGPoint result  = CGPointMake(x_col_shift, y_row_shift);
    
    return result;
}


CGPoint
fhgm_spxc_correlate_two_blocks_half_pixel(const DSPSplitComplex *const restrict ref_block,
                                   const DSPSplitComplex *const restrict smp_block,
                                   const DSPSplitComplex *const restrict tmp_block,
                                   const float *const restrict square_kernel,
                                   const size_t log_two_of_blockSize,
                                   const FFTSetup setup)
{
    const vDSP_Length log_two_double_blockSize = log_two_of_blockSize + 1;
    
    const vDSP_Length block_size         = (vDSP_Length)(calculate_block_size(log_two_of_blockSize));
    const vDSP_Length block_size_squared = (vDSP_Length)(calculate_block_size_squared(log_two_of_blockSize));
    
    const vDSP_Length double_block_size_squared = block_size_squared << 2;
    
    // SECOND NORMAL BLOCK
    const DSPSplitComplex tmp_block_2 = {
        .realp = tmp_block->realp + block_size_squared,
        .imagp = tmp_block->imagp + block_size_squared,
    };
    
    // FIRST PADDED BLOCK, THIRD TEMP
    const DSPSplitComplex padded_temp = {
        .realp = tmp_block->realp + 2 * block_size_squared,
        .imagp = tmp_block->imagp + 2 * block_size_squared,
    };
    
    // SECOND PADDED BLOCK, 4TH TEMP
    const DSPSplitComplex padded_matrix = {
        .realp = tmp_block->realp + 2 * block_size_squared + double_block_size_squared,
        .imagp = tmp_block->imagp + 2 * block_size_squared + double_block_size_squared,
    };
    
    // THIRD PADDED BLOCK, 5TH TEMP
    const DSPSplitComplex fft_output_unscaled = {
        .realp = tmp_block->realp + 2 * block_size_squared + 2 * double_block_size_squared,
        .imagp = tmp_block->imagp + 2 * block_size_squared + 2 * double_block_size_squared,
    };
    
    vDSP_zvmul(ref_block,
               1,
               smp_block,
               1,
               tmp_block,
               1,
               block_size_squared,
               -1);
    
    // CLEAR CLEAR PADDED TEMP, JUST IN CASE
    vDSP_vclr(padded_temp.realp, 1, double_block_size_squared);
    vDSP_vclr(padded_temp.imagp, 1, double_block_size_squared);
    
    ft_add_padding(tmp_block,
                   &padded_matrix,
                   block_size,
                   &tmp_block_2,
                   &padded_temp);
    
    // CLEAR TMP_BLOCK 1, 2 AND PADDED_TEMP
    vDSP_vclr(tmp_block->realp, 1, 2 * block_size_squared + double_block_size_squared);
    vDSP_vclr(tmp_block->imagp, 1, 2 * block_size_squared + double_block_size_squared);
    
    const vDSP_Length fft_length = log_two_of_blockSize + 1;    // log2(2 * blockSize);
    
    vDSP_fft2d_zopt(setup,
                    &padded_matrix,
                    1,
                    0,
                    &fft_output_unscaled,
                    1,
                    0,
                    &padded_temp,
                    fft_length,
                    fft_length,
                    kFFTDirection_Forward);
    
    
    // MY BY 1 / NUM OF ELEMENTS
    // EQUIVALENT TO DFT_SCALE, IN OPENCV
    const float elements_num_real = 1. / (float)double_block_size_squared;
    const float elements_num_imag = 0.;
    
    const DSPSplitComplex scale = {
        .realp = (float *)&elements_num_real,
        .imagp = (float *)&elements_num_imag,
    };
    
    // RE - USE PADDED TEMP AS SCALED FFT OUTPUT
    const DSPSplitComplex scaled_fft = padded_temp;
    vDSP_zvzsml(&fft_output_unscaled, 1, &scale, &scaled_fft, 1, double_block_size_squared);
    
    // ABSOLUTE VALUES
//    float *const magnitudes_arr = scaled_fft.realp;
    float *const magnitudes_arr = padded_matrix.realp;
    vDSP_vdist(scaled_fft.realp, 1, scaled_fft.imagp, 1, magnitudes_arr, 1, double_block_size_squared);
    
    float max_val;
    vDSP_Length max_index;
    
    vDSP_maxvi(magnitudes_arr, 1, &max_val, &max_index, double_block_size_squared);
    
    const size_t max_y_row_index = get_yir_from_index(max_index, log_two_double_blockSize);
    const size_t max_x_col_index = get_xjc_from_index(max_index, log_two_double_blockSize);
    
    const float y_row_shift = square_kernel[max_y_row_index] / 2.;
    const float x_col_shift = square_kernel[max_x_col_index] / 2.;
    
    const CGPoint result  = CGPointMake(x_col_shift, y_row_shift);
    
    return result;
}

CGPoint
fhgm_spxc_correlate_two_blocks_sub_pixel(const DSPSplitComplex *const restrict ref_block,
                                  const DSPSplitComplex *const restrict smp_block,
                                  const DSPSplitComplex *const restrict tmp_block,
                                  const float *const restrict square_kernel,
                                  const DSPSplitComplex *const restrict complex_kernel,
                                  const size_t log_two_of_blockSize,
                                  const FFTSetup setup,
                                  const size_t scaling_factor,
                                  const DSPSplitComplex *const restrict dftups_tmp_block)
{
    const vDSP_Length block_size_squared = (vDSP_Length)(calculate_block_size_squared(log_two_of_blockSize));
    
    const size_t block_size     = calculate_block_size(log_two_of_blockSize);
    const size_t upscale_1_5    = (scaling_factor * 15) / 10;   // usfac * 1.5
    
    const float upscale_fac     = (float)scaling_factor;
    const float dft_shift       = (float)(upscale_1_5 >> 1);    // usfac * 1.5 / 2
    
    const CGPoint first_xcorr2 = fhgm_spxc_correlate_two_blocks_half_pixel(ref_block, smp_block, tmp_block,
                                                                    square_kernel, log_two_of_blockSize, setup);
    
    
    const float row_shift_scaled = roundf(first_xcorr2.y * upscale_fac) / upscale_fac;
    const float col_shift_scaled = roundf(first_xcorr2.x * upscale_fac) / upscale_fac;
    
    const float dft_shift_row = dft_shift - row_shift_scaled * upscale_fac;
    const float dft_shift_col = dft_shift - col_shift_scaled * upscale_fac;
    
    
    vDSP_zvmul(ref_block, 1, smp_block, 1, tmp_block, 1, block_size_squared, -1);
    dft_upscale(tmp_block, dftups_tmp_block, dft_shift_row, dft_shift_col, upscale_1_5, block_size, complex_kernel);
    
    
    const size_t upscale_1_5_squared = upscale_1_5 * upscale_1_5;
    // Should we take mag?
    const float *const real_arr = dftups_tmp_block->realp;
    const float *const imag_arr = dftups_tmp_block->imagp;
    
    // Second block, use as magnitudes
    float *const magnitudes_arr = dftups_tmp_block->realp + upscale_1_5_squared;
    
    vDSP_vdist(real_arr, 1, imag_arr, 1, magnitudes_arr, 1, upscale_1_5_squared);
    
    float max_val;
    
    vDSP_Length max_index;
    vDSP_maxvi(magnitudes_arr, 1, &max_val, &max_index, upscale_1_5_squared);
    
    const float max_y_row_index = (float)(max_index / upscale_1_5);
    const float max_x_col_index = (float)(max_index % upscale_1_5);
    
    const float y_row_shift = row_shift_scaled + ((max_y_row_index - dft_shift) / upscale_fac);
    const float x_col_shift = col_shift_scaled + ((max_x_col_index - dft_shift) / upscale_fac);
    
    const CGPoint result  = CGPointMake(x_col_shift, y_row_shift);
    
    return result;
}


CGPoint
fhgm_spxc_correlate_two_blocks(const vImage_Buffer *const restrict ref_block,
                        const vImage_Buffer *const restrict smp_block,
                        const void *const restrict tmp_buf)
{
    return CGPointMake(0, 9);
}




#pragma mark - Private main functions
// Tested... Working as sicairos
static inline void
ft_add_padding(const DSPSplitComplex *const restrict input,
               const DSPSplitComplex *const restrict output,
               const size_t block_size,
               const DSPSplitComplex *const restrict tmp_block,
               const DSPSplitComplex *const restrict tmp_half_pixel_block)
{
    forward_fft2D_shift(input, tmp_block, block_size);
    
    const size_t out_block_size = block_size << 1;
    
    const size_t input_center  = (block_size  >> 1) + 1;
    const size_t output_center = (out_block_size >> 1) + 1;
    
    const size_t center_diff = output_center - input_center;
    
    const size_t p1      = 0;
    const size_t p2      = center_diff;
    
    const size_t cdpp1   = center_diff + p1;
    const unsigned char flag = (out_block_size >= cdpp1) && ((out_block_size - cdpp1) < block_size);
    
    const vDSP_Length r1 = (flag != 0) ? out_block_size - cdpp1 : block_size;
    
    // Use Output as Temp 1 and tmp_half_pixel as temp2
    vDSP_mmov(tmp_block->realp + p1 * block_size + p1,
              //    tmp_half_pixel_block->realp + p2 * block_size + p2,
              output->realp    + p2 * out_block_size + p2,
              r1, r1,
              block_size, block_size * 2);
    vDSP_mmov(tmp_block->imagp + p1 * block_size + p1,
              //    tmp_half_pixel_block->imagp + p2 * block_size + p2,
              output->imagp    + p2 * out_block_size + p2,
              r1, r1,
              block_size, block_size * 2);
    
    // tmp_half_pixel as Temp 2
    //    inverse_fft2D_shift(tmp_half_pixel_block, output, block_size);
    inverse_fft2D_shift(output, tmp_half_pixel_block, out_block_size);
    
    static const float area_scale_r = 4.;
    static const float area_scale_i = 0.;
    
    const DSPSplitComplex area_scale = {
        .realp = (float *)(&area_scale_r),
        .imagp = (float *)(&area_scale_i),
    };
    
    vDSP_zvzsml(tmp_half_pixel_block, 1,
                &area_scale,
                output, 1,
                out_block_size * out_block_size);   // area of output
}

static inline void
dft_upscale(const DSPSplitComplex *const restrict input,
            const DSPSplitComplex *const restrict output_and_temp,
            const float row_offset,
            const float col_offset,
            const size_t upscale_opf,
            const size_t block_size,
            const DSPSplitComplex *const restrict complex_kernel)
{
    static const float kOne  = 1.;
    
    const size_t output_size = upscale_opf * upscale_opf;
    const size_t kernel_size = upscale_opf * block_size;
    
    /*
     *      LET'S SEPERATE THE MATRICES
     *          - 2 * USFAC1P5^2 ARE THE OUTPUT BLOCK & A TEMP BLOCK
     *          - 2 * USFAC1P5 ARE THE NOC AND NOR
     *          - 2 * USFAC1P5 * BLOCKSIZE ARE 2 MATRICES HOLDING NOC * NC OR NOR * NR
     */
    const DSPSplitComplex output = {
        .realp = output_and_temp->realp,
        .imagp = output_and_temp->imagp,
    };
    
    const DSPSplitComplex temp_output = {
        .realp = output_and_temp->realp + output_size,
        .imagp = output_and_temp->imagp + output_size,
    };
    
    // STARTS AFTER 2 * USFAC1P5 ^ 2
    const DSPSplitComplex row_offset_arr = {
        .realp = output_and_temp->realp + 2 * output_size,
        .imagp = output_and_temp->imagp + 2 * output_size,
    };
    // STARTS AFTER 2 * USFAC1P5^2 + USFAC1P5
    const DSPSplitComplex col_offset_arr = {
        .realp = output_and_temp->realp + 2 * output_size + upscale_opf,
        .imagp = output_and_temp->imagp + 2 * output_size + upscale_opf,
    };
    
    // FIRST KERNEL AFTER 2 OUTPUT & 2 ARRAYS
    const DSPSplitComplex row_kernel = {
        .realp = output_and_temp->realp + 2 * output_size + 2 * upscale_opf,
        .imagp = output_and_temp->imagp + 2 * output_size + 2 * upscale_opf,
    };
    // SECOND KERNEL AFTER 2 OUTPUT, 2 ARRAYS AND ONE KERNEL
    const DSPSplitComplex col_kernel = {
        .realp = output_and_temp->realp + 2 * output_size + 2 * upscale_opf + kernel_size,
        .imagp = output_and_temp->imagp + 2 * output_size + 2 * upscale_opf + kernel_size,
    };
    
    const float row_start = 0. - row_offset;
    const float col_start = 0. - col_offset;
    
    vDSP_vramp(&row_start, &kOne, row_offset_arr.realp, 1, upscale_opf); // RAMP THE REAL PART
    vDSP_vclr(row_offset_arr.imagp, 1, upscale_opf);                     // Zero the complex part
    
    vDSP_vramp(&col_start, &kOne, col_offset_arr.realp, 1, upscale_opf); // RAMP THE REAL PART
    vDSP_vclr(col_offset_arr.imagp, 1, upscale_opf);                     // Zero the complex part
    
    
    const int iKernelSize = (int)kernel_size;
    
    
    /*
     *  e^(x+iy) = e^x * e^iy =
     *      e^x * (cos(y) + isin(y))
     */
    
    /******** COLS *********/
    vDSP_zmmul(complex_kernel, 1, &col_offset_arr, 1, &col_kernel, 1, block_size, upscale_opf, 1);
    vvexpf(temp_output.realp, col_kernel.realp, &iKernelSize);
    
    vvcosf(temp_output.imagp, col_kernel.imagp, &iKernelSize);
    vDSP_vmul(temp_output.realp, 1, temp_output.imagp, 1, col_kernel.realp, 1, kernel_size);
    
    vvsinf(temp_output.imagp, col_kernel.imagp, &iKernelSize);
    vDSP_vmul(temp_output.realp, 1, temp_output.imagp, 1, col_kernel.imagp, 1, kernel_size);
    
    /******** ROWS *********/
    vDSP_zmmul(&row_offset_arr, 1, complex_kernel, 1, &row_kernel, 1, upscale_opf, block_size, 1);
    vvexpf(temp_output.realp, row_kernel.realp, &iKernelSize);
    
    vvcosf(temp_output.imagp, row_kernel.imagp, &iKernelSize);
    vDSP_vmul(temp_output.realp, 1, temp_output.imagp, 1, row_kernel.realp, 1, kernel_size);
    
    vvsinf(temp_output.imagp, row_kernel.imagp, &iKernelSize);
    vDSP_vmul(temp_output.realp, 1, temp_output.imagp, 1, row_kernel.imagp, 1, kernel_size);
    
    
    
    /******** Final Mul ********/
    //    vDSP_zmmul(&row_kernel, 1, input, 1, &temp_output, 1, upscale_opf, block_size, block_size);
    //    vDSP_zmmul(input, 1, &row_kernel, 1, &output, 1, block_size, upscale_opf, block_size);
    vDSP_zmmul(input, 1, &col_kernel, 1, &temp_output, 1, block_size, upscale_opf, block_size);
    vDSP_zmmul(&row_kernel, 1, &temp_output, 1, &output, 1, upscale_opf, upscale_opf, block_size);
    
    // Done
    
    //    printf("\n\nKernc:\n");
    //    for (size_t i = 0; i < block_size; ++i) {
    //        for (size_t j = 0; j < upscale_opf; ++j) {
    //            const size_t ind = i * upscale_opf + j;
    //            printf("%.2f + i%.2f,   ", col_kernel.realp[ind], col_kernel.imagp[ind]);
    //        }
    //        printf("\n");
    //    }
    //    printf("\n==========\nKernr:\n");
    //    for (size_t i = 0; i < upscale_opf; ++i) {
    //        for (size_t j = 0; j < block_size; ++j) {
    //            const size_t ind = i * block_size + j;
    //            printf("%.2f + i%.2f,   ", row_kernel.realp[ind], row_kernel.imagp[ind]);
    //        }
    //        printf("\n");
    //    }
    //    printf("\n==========\nin:\n");
    //    for (size_t i = 0; i < block_size; ++i) {
    //        for (size_t j = 0; j < block_size; ++j) {
    //            const size_t ind = i * block_size + j;
    //            printf("%.2f + i%.2f,   ", input->realp[ind], input->imagp[ind]);
    //        }
    //        printf("\n");
    //    }
    //    printf("\n==========\nk:\n");
    //    for (size_t i = 0; i < block_size; ++i) {
    //        for (size_t j = 0; j < upscale_opf; ++j) {
    //            const size_t ind = i * upscale_opf + j;
    //            printf("%.2f + i%.2f,   ", temp_output.realp[ind], temp_output.imagp[ind]);
    //        }
    //        printf("\n");
    //    }
    ////    printf("\n==========\nk:\n");
    ////    for (size_t i = 0; i < upscale_opf; ++i) {
    ////        for (size_t j = 0; j < block_size; ++j) {
    ////            const size_t ind = i * block_size + j;
    ////            printf("%.2f + i%.2f,   ", temp_output.realp[ind], temp_output.imagp[ind]);
    ////        }
    ////        printf("\n");
    ////    }
    ////    printf("\n==========\nout:\n");
    ////    for (size_t i = 0; i < block_size; ++i) {
    ////        for (size_t j = 0; j < upscale_opf; ++j) {
    ////            const size_t ind = i * upscale_opf + j;
    ////            printf("%.2f + i%.2f,   ", output.realp[ind], output.imagp[ind]);
    ////        }
    ////        printf("\n");
    ////    }
    //    printf("\n==========\nout:\n");
    //    for (size_t i = 0; i < upscale_opf; ++i) {
    //        for (size_t j = 0; j < upscale_opf; ++j) {
    //            const size_t ind = i * upscale_opf + j;
    //            printf("%.2f + i%.2f,   ", output.realp[ind], output.imagp[ind]);
    //        }
    //        printf("\n");
    //    }
    
}


// TESTED AND WORKING
static inline void
ifft_shift(float *const restrict vec, const float start, const float end)
{
    static const float inc = 1.;
    const float tmp_elements_num = end - start + 1.;
    
    const float elem_half_num    = tmp_elements_num / 2.;
    
    const float val_1       = floorf(end - elem_half_num + 1.);
    const vDSP_Length cnt_1 = (vDSP_Length)ceilf(elem_half_num);
    
    vDSP_vramp(&val_1,
               &inc,
               vec,
               1,
               cnt_1);
    
    float *const vec_2      = vec + cnt_1;
    const float  val_2      = start;
    const vDSP_Length cnt_2 = (vDSP_Length)floorf(elem_half_num);
    
    vDSP_vramp(&val_2,
               &inc,
               vec_2,
               1,
               cnt_2);
}

static inline void
forward_fft2D_shift(const DSPSplitComplex *const restrict input,
                    const DSPSplitComplex *const restrict output,
                    const size_t block_size)
{
    const size_t quadrant_side = block_size >> 1;   // divide by 2
    //
    const size_t large_quadrant_side = quadrant_side;
    const size_t small_quadrant_side = quadrant_side;
    
    // (0, 0) ==> (S, S)
    const size_t input_offset_1  = 0;
    const size_t output_offset_1 = small_quadrant_side * block_size + small_quadrant_side;
    
    // (L, 0) ==> (0, S)
    const size_t input_offset_2  = large_quadrant_side;
    const size_t output_offset_2 = small_quadrant_side * block_size;
    
    // (0, L) ==> (S, 0)
    const size_t input_offset_3  = large_quadrant_side * block_size;
    const size_t output_offset_3 = small_quadrant_side;
    
    // (L, L) ==> (0, 0)
    const size_t input_offset_4  = large_quadrant_side * block_size + large_quadrant_side;
    const size_t output_offset_4 = 0;
    
    
    const vDSP_Length width_1  = large_quadrant_side;
    const vDSP_Length height_1 = large_quadrant_side;
    
    const vDSP_Length width_2  = small_quadrant_side;
    const vDSP_Length height_2 = large_quadrant_side;
    
    const vDSP_Length width_3  = large_quadrant_side;
    const vDSP_Length height_3 = small_quadrant_side;
    
    const vDSP_Length width_4  = small_quadrant_side;
    const vDSP_Length height_4 = small_quadrant_side;
    
    
    vDSP_mmov(input->realp  + input_offset_1, output->realp + output_offset_1,
              width_1, height_1, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_1, output->imagp + output_offset_1,
              width_1, height_1, block_size, block_size);
    
    vDSP_mmov(input->realp  + input_offset_2, output->realp + output_offset_2,
              width_2, height_2, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_2, output->imagp + output_offset_2,
              width_2, height_2, block_size, block_size);
    
    vDSP_mmov(input->realp  + input_offset_3, output->realp + output_offset_3,
              width_3, height_3, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_3, output->imagp + output_offset_3,
              width_3, height_3, block_size, block_size);
    
    vDSP_mmov(input->realp  + input_offset_4, output->realp + output_offset_4,
              width_4, height_4, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_4, output->imagp + output_offset_4,
              width_4, height_4, block_size, block_size);
}

static inline void
inverse_fft2D_shift(const DSPSplitComplex *const restrict input,
                    const DSPSplitComplex *const restrict output,
                    const size_t block_size)
{
    const size_t quadrant_side = block_size >> 1;
    
    const size_t large_quadrant_side = quadrant_side;
    const size_t small_quadrant_side = quadrant_side ;
    
    //    const float half_side = ((float)block_size) / 2.;
    //
    //    const size_t large_quadrant_side = (size_t)ceilf(half_side);
    //    const size_t small_quadrant_side = (size_t)floorf(half_side) - 1.;
    
    
    // (0, 0) <== (S, S)
    const size_t input_offset_1  = small_quadrant_side * block_size + small_quadrant_side;
    const size_t output_offset_1 = 0;
    
    // (L, 0) <== (0, S)
    const size_t input_offset_2  = small_quadrant_side * block_size;
    const size_t output_offset_2 = large_quadrant_side;
    
    // (0, L) <== (S, 0)
    const size_t input_offset_3  = small_quadrant_side;
    const size_t output_offset_3 = large_quadrant_side * block_size;
    
    // (L, L) <== (0, 0)
    const size_t input_offset_4  = 0;
    const size_t output_offset_4 = large_quadrant_side * block_size + large_quadrant_side;
    
    
    const vDSP_Length width_1  = large_quadrant_side;
    const vDSP_Length height_1 = large_quadrant_side;
    
    const vDSP_Length width_2  = small_quadrant_side;
    const vDSP_Length height_2 = large_quadrant_side;
    
    const vDSP_Length width_3  = large_quadrant_side;
    const vDSP_Length height_3 = small_quadrant_side;
    
    const vDSP_Length width_4  = small_quadrant_side;
    const vDSP_Length height_4 = small_quadrant_side;
    
    
    vDSP_mmov(input->realp  + input_offset_1, output->realp + output_offset_1,
              width_1, height_1, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_1, output->imagp + output_offset_1,
              width_1, height_1, block_size, block_size);
    
    vDSP_mmov(input->realp  + input_offset_2, output->realp + output_offset_2,
              width_2, height_2, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_2, output->imagp + output_offset_2,
              width_2, height_2, block_size, block_size);
    
    vDSP_mmov(input->realp  + input_offset_3, output->realp + output_offset_3,
              width_3, height_3, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_3, output->imagp + output_offset_3,
              width_3, height_3, block_size, block_size);
    
    vDSP_mmov(input->realp  + input_offset_4, output->realp + output_offset_4,
              width_4, height_4, block_size, block_size);
    vDSP_mmov(input->imagp  + input_offset_4, output->imagp + output_offset_4,
              width_4, height_4, block_size, block_size);
}





#pragma mark - Private util functions
static inline size_t
calculate_block_size(const size_t log_two_of_block_size)
{
    const size_t result = 1ul << log_two_of_block_size;
    
    return result;
}

static inline size_t
calculate_block_size_squared(const size_t log_two_of_block_size)
{
    // (2 ^ (BS))^2 == 2 ^ (BS * 2)
    const size_t result = 1ul << (log_two_of_block_size << 1);
    
    return result;
}


/*
 *  MAKES THE INVERSE OF THE EQUATION K = I * WIDTH + J;
 *      TO GET I AND J FROM K, WHICH WILL BE:
 *          I ==> Y ==> DIVIDE BY WIDTH
 *          J ==> X ==> MODULUS WIDTH
 *
 *          I = K / WIDTH - J / WIDTH (J / WIDTH = 0)
 *          J = K % WIDTH - I * WIDTH % WIDTH (I * WIDTH % WIDTH = 0)
 *
 *      DO THESE OPS IN BITWISE FOR SPEED
 *          SINCE WE KNOW THAT BLOCKSIZE IS MULTIPLE OF 2:
 *
 *          I = K >> log2(WIDTH)
 *          J = K & (WIDTH - 1)
 *
 *  TESTED AND WORKING
 *
 */

static inline size_t
get_xjc_from_index(const vDSP_Length index, const size_t log_two_of_block_size)
{
    const vDSP_Length length_minus_one = (vDSP_Length)(calculate_block_size(log_two_of_block_size) - 1ul);
    const vDSP_Length result_val = index &  length_minus_one;
    
    const size_t result = (size_t)result_val;
    
    return result;
}

static inline size_t
get_yir_from_index(const vDSP_Length index, const size_t log_two_of_block_size)
{
    const vDSP_Length result_val = index >> log_two_of_block_size;
    const size_t result = (size_t)result_val;
    
    return result;
}


#pragma mark - Testing
void fct_ftpad(const DSPSplitComplex *const restrict input,
               const DSPSplitComplex *const restrict output,
               const size_t block_size,
               const DSPSplitComplex *const restrict tmp_block,
               const DSPSplitComplex *const restrict tmp_half_pixel_block)
{
    ft_add_padding(input, output, block_size, tmp_block, tmp_half_pixel_block);
}
