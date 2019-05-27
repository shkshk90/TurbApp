//
//  AllOps.h
//  TurbApp
//
//  Created by Samuel Aysser on 22.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef AllOps_h
#define AllOps_h

#include <stdio.h>
#include <stdint.h>

struct FhgData;

typedef struct CGRect CGRect;
typedef struct CGImage *CGImageRef;
typedef struct vImage_CGImageFormat vImage_CGImageFormat;

typedef struct DSPSplitComplex  DSPSplitComplex;
typedef struct OpaqueFFTSetup  *FFTSetup;

/// ======================== SETUP OPERATIONS =================================================================== ///
/*
 *  CREATES CG FORMAT TO BE USED IN CONVERTING CGIMAGE TO VIMAGE
 */
void fhg_preOps_createCGFormat(vImage_CGImageFormat *const restrict format);

/*
 *  CREATES FHGDATA STRUCTURE
 *  THIS CONTAINS ALL RELEVANT DATA TO PROCESSING
 */
void fhg_preOps_createData(struct FhgData *const restrict data, const uint32_t blockSide,   const uint32_t numberOfFrames,
                           const  CGRect  *const restrict roi,  const uint32_t frameHeight, const uint32_t frameWidth);

/*
 *  ALLOCATES TEMP BUFFER, USING PARAMETERS IN FHGDATA STRUCTURE
 */
void fhg_preOps_allocTemp(void **buffer, const struct FhgData *const restrict data);

/*
 *  ALLOCATES BLOCKS BUFFER, USING PARAMETERS IN FHGDATA STRUCTURE
 */
void fhg_preOps_allocBlockBuffer(void **buffer, const struct FhgData *const restrict data);


/// ======================== MAIN OPERATIONS =================================================================== ///
/*
 *  ALLOCATES TEMP BUFFER, USING PARAMETERS IN FHGDATA STRUCTURE
 */
void fhg_ops_convertFullFrameToBlocks(const restrict CGImageRef fullFrame,
                                      const vImage_CGImageFormat *const restrict format,
                                      const struct FhgData *const restrict data,
                                      void *const restrict blocksBuffer,
                                      void *const restrict tempBuffer);

//void fhg_ops_crossCorrelate(const DSPSplitComplex *const restrict imageA,
//                            const DSPSplitComplex *const restrict imageB,
//                            const struct  FhgData *const restrict data,
//                            void *const restrict temp);
//
//void fhg_ops_crossCorrelate_halfPixel(const DSPSplitComplex *const restrict imageA,
//                                      const DSPSplitComplex *const restrict imageB,
//                                      const struct  FhgData *const restrict data,
//                                      const restrict FFTSetup setup,
//                                      void *const restrict temp);
//
//void fhg_ops_crossCorrelate_subPixel(const DSPSplitComplex *const restrict imageA,
//                                     const DSPSplitComplex *const restrict imageB,
//                                     const size_t upscalingFactor,
//                                     const struct  FhgData *const restrict data,
//                                     const restrict FFTSetup setup,
//                                     void *const restrict temp);

#endif /* AllOps_h */
