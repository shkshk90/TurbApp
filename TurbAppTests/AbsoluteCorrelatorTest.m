//
//  AbsoluteCorrelatorTest.m
//  TurbAppTests
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Accelerate;

#include "../TurbApp/Models/SubpixelCrossCorrelator.h"

@interface AbsoluteCorrelatorTest : XCTestCase

@end

@implementation AbsoluteCorrelatorTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testCrossCorrQuarterPixel {
    float *const real1  = malloc(4 * 16);
    float *const imag1  = calloc(4, 16);
    float *const real2  = malloc(4 * 16);
    float *const imag2  = calloc(4, 16);
    
    
    for (size_t i = 0; i < 16; ++i) {
        real1[i] = (float)i;
        real2[i] = (float)((i + 4) % 16);
//        real2[(i + 3) % 16] = (float)i;
    }
    
    printf("real1:\n");
    for (size_t i = 0; i < 4; ++i) {
        for (size_t j = 0; j < 4; ++j)
            printf("%f  ", real1[i*4+j]);
        printf("\n");
    }
    printf("\nreal2:\n");
    for (size_t i = 0; i < 4; ++i) {
        for (size_t j = 0; j < 4; ++j)
            printf("%f  ", real2[i*4+j]);
        printf("\n");
    }
    
    float *const real3  = calloc(4, 16);
    float *const imag3  = calloc(4, 16);
    float *const real4  = calloc(4, 16);
    float *const imag4  = calloc(4, 16);
    
    const DSPSplitComplex in1 = {real1, imag1};
    const DSPSplitComplex in2 = {real2, imag2};
    
    const DSPSplitComplex ot1 = {real3, imag3};
    const DSPSplitComplex ot2 = {real4, imag4};
    
    float *const real5  = calloc(4, 2 * 16 + 4 * 4 * 16);
    float *const imag5  = calloc(4, 2 * 16 + 4 * 4 * 16);
    
    printf("tmp elm: %d\n", 2 * 16 + 3 * 4 * 16);
    
    const DSPSplitComplex tmp = {real5, imag5};
    
    FFTSetup setup = vDSP_create_fftsetup((vDSP_Length)floorf(log2f(16. * 4 * 2)), kFFTRadix2);
    const vDSP_Length sideLen = (vDSP_Length)floorf(log2(4.));
    
    vDSP_fft2d_zopt(setup, &in1, 1, 0, &ot1, 1, 0, &tmp, sideLen, sideLen, kFFTDirection_Forward);
    vDSP_fft2d_zopt(setup, &in2, 1, 0, &ot2, 1, 0, &tmp, sideLen, sideLen, kFFTDirection_Forward);
    
    float *const kern1 = malloc(4 * 4);
    float *const kern2 = malloc(4 * 16 * 16 * 2);
    float *const kernt = malloc(4 * 16 * 16 * 2);
    float *const kern3 = malloc(4 * 16 * 16);
    float *const kern4 = malloc(4 * 16 * 16);
    
    const DSPSplitComplex complexKernel = {kern3, kern4};
    
    fhgm_spxc_create_kernels(kern1, kern2, 4);
    fhgm_spxc_create_complex_kernel(&complexKernel, 4, 4, kernt);
    
    for (int i = 0; i < 4; ++i)
        printf("%f  ", kern1[i]);
    printf("\n");
    for (int i = 0; i < 4; ++i)
        printf("%.2f+j%.2f  ", kern3[i], kern4[i]);
    printf("\n");
    
    
    const vDSP_Length usfac15 = (vDSP_Length)(4. * 1.5);
    const vDSP_Length e2usfac15 = usfac15 * usfac15;
    
    /*
     *          - 2 * USFAC1P5^2 ARE THE OUTPUT BLOCK & A TEMP OUTPUT BLOCK
     *          - 2 * USFAC1P5 ARE THE NOC AND NOR
     *          - 2 * USFAC1P5 * BLOCKSIZE ARE 2 MATRICES HOLDING NOC * NC OR NOR * NR
     */
    float *const kern5 = malloc(4 * (2*e2usfac15 + 2*usfac15 + 2*usfac15*4));
    float *const kern6 = malloc(4 * (2*e2usfac15 + 2*usfac15 + 2*usfac15*4));
    
    const DSPSplitComplex dftupsTmp = {kern5, kern6};
    
    
    const CGPoint pnt = fhgm_spxc_correlate_two_blocks_sub_pixel(&ot1, &ot2, &tmp, kern2, &complexKernel, (size_t)floorf(log2(4.)), setup, 4, &dftupsTmp);
    //    const CGPoint pnt = fc_correlate_two_blocks_half_pixel(&ot1, &ot2, &tmp, kern2, (size_t)floorf(log2(4.)), setup);
    
    printf("value: %f, %f\n", pnt.x, pnt.y);
    
    XCTAssertEqual((int)pnt.x, 0);
    XCTAssertEqual((int)pnt.y, 1);
    
    free(real1); free(imag1);
    free(real2); free(imag2);
    free(real3); free(imag3);
    free(real4); free(imag4);
    free(real5); free(imag5);
    free(kern1); free(kern2);
    free(kern3); free(kern4);
    free(kern5); free(kern6);
    free(kernt);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
