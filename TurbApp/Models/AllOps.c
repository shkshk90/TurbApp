//
//  AllOps.c
//  TurbApp
//
//  Created by Samuel Aysser on 22.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#include "AllOps.h"
#include "ModelsResources.h"
#include "fhgm_c_private_resources.h"
#include "ImageToBlocksConverter.h"

#include <Accelerate/Accelerate.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

/********************************** PRIVATIE MEMBERS *************************/
static const float nc_016[] = {
    0.f, 1.f, 2.f, 3.f, 4.f, 5.f, 6.f, 7.f, -8.f,
    -7.f, -6.f, -5.f, -4.f, -3.f, -2.f, -1.f
};
static const float nc_032[] = {
    0.f, 1.f, 2.f, 3.f, 4.f, 5.f, 6.f, 7.f, 8.f,
    9.f, 10.f, 11.f, 12.f, 13.f, 14.f, 15.f, -16.f,
    -15.f, -14.f, -13.f, -12.f, -11.f, -10.f, -9.f,
    -8.f, -7.f, -6.f, -5.f, -4.f, -3.f, -2.f, -1.f
};
static const float nc_064[] = {
    0.f, 1.f, 2.f, 3.f, 4.f, 5.f, 6.f, 7.f, 8.f,
    9.f, 10.f, 11.f, 12.f, 13.f, 14.f, 15.f, 16.f,
    17.f, 18.f, 19.f, 20.f, 21.f, 22.f, 23.f, 24.f,
    25.f, 26.f, 27.f, 28.f, 29.f, 30.f, 31.f, -32.f,
    -31.f, -30.f, -29.f, -28.f, -27.f, -26.f, -25.f,
    -24.f, -23.f, -22.f, -21.f, -20.f, -19.f, -18.f,
    -17.f, -16.f, -15.f, -14.f, -13.f, -12.f, -11.f,
    -10.f, -9.f, -8.f, -7.f, -6.f, -5.f, -4.f, -3.f,
    -2.f, -1.f
};
static const float nc_128[] = {
    0.f, 1.f, 2.f, 3.f, 4.f, 5.f, 6.f, 7.f, 8.f,
    9.f, 10.f, 11.f, 12.f, 13.f, 14.f, 15.f, 16.f,
    17.f, 18.f, 19.f, 20.f, 21.f, 22.f, 23.f, 24.f,
    25.f, 26.f, 27.f, 28.f, 29.f, 30.f, 31.f, 32.f,
    33.f, 34.f, 35.f, 36.f, 37.f, 38.f, 39.f, 40.f,
    41.f, 42.f, 43.f, 44.f, 45.f, 46.f, 47.f, 48.f,
    49.f, 50.f, 51.f, 52.f, 53.f, 54.f, 55.f, 56.f,
    57.f, 58.f, 59.f, 60.f, 61.f, 62.f, 63.f,
    -64.f, -63.f, -62.f, -61.f, -60.f, -59.f, -58.f, -57.f,
    -56.f, -55.f, -54.f, -53.f, -52.f, -51.f, -50.f, -49.f,
    -48.f, -47.f, -46.f, -45.f, -44.f, -43.f, -42.f, -41.f,
    -40.f, -39.f, -38.f, -37.f, -36.f, -35.f, -34.f, -33.f,
    -32.f, -31.f, -30.f, -29.f, -28.f, -27.f, -26.f, -25.f,
    -24.f, -23.f, -22.f, -21.f, -20.f, -19.f, -18.f, -17.f,
    -16.f, -15.f, -14.f, -13.f, -12.f, -11.f, -10.f, -9.f,
    -8.f, -7.f, -6.f, -5.f, -4.f, -3.f, -2.f, -1.f
};
/****************************** END PRIVATIE MEMBERS *************************/

/********************************** PRIVATIE METHODS *************************/
// TESTED, WORKS PERFECTLY AND FAR LESS COMPLEX AND FAR MORE EFFICIENT THAN MATLAB
static inline void ftPad(const DSPSplitComplex *const restrict input,   // block area
                         const DSPSplitComplex *const restrict output,  // 2 * blockarea
                         const struct FhgData *const restrict data,
                         void *const restrict temp);
/****************************** END PRIVATIE METHODS *************************/



void
fhg_preOps_createCGFormat(vImage_CGImageFormat *const restrict format)
{
    format->bitmapInfo       = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
    format->bitsPerComponent = 8;
    format->bitsPerPixel     = sizeof(Pixel_8888) * 8;
    format->colorSpace       = CGColorSpaceCreateDeviceRGB();
    format->decode           = NULL;
    format->renderingIntent  = kCGRenderingIntentDefault;
    format->version          = 0;
}

void
fhg_preOps_createData(struct FhgData *const restrict data, const uint32_t blockSide,  const uint32_t numberOfFrames,
                      const  CGRect  *const restrict roi,  const uint32_t frameHeight, const uint32_t frameWidth)
{
    const uint32_t roiHeight = (uint32_t)lroundf(roi->size.height);
    const uint32_t roiWidth  = (uint32_t)lroundf(roi->size.width);
    
    FHGM_CPR_ASSERT(blockSide != 0, "Block side is zero", NULL);
    FHGM_CPR_ASSERT(roiHeight == roiWidth, "ROI is not a square", NULL);
    FHGM_CPR_ASSERT(blockSide <= roiWidth,
                    "Block side is larger than ROI.\nBlock side = %u, Roi side = %u",
                    blockSide, roiWidth);
    FHGM_CPR_ASSERT((frameHeight > roiHeight) && (frameWidth > roiWidth),
                    "Roi is larger than frame\nRoi dimensions = (%u, %u) while frame dimensions = (%u, %u)",
                    roiWidth, roiHeight, frameWidth, frameHeight);
    if (frameHeight > frameWidth)
        printf("WARNING! Frame Height (%u) is higher than frame width (%u)", frameHeight, frameWidth);
    
    data->numberOfFrames = numberOfFrames;
    
    data->roi.height = roiHeight;
    data->roi.width  = roiWidth;
    data->roi.area   = roiHeight * roiWidth;
    data->roi.offsetCount = (size_t)(roiHeight * roiWidth);
    data->roi.offsetBytes = (size_t)(roiHeight * roiWidth) * 4;
    
    data->block.height      = blockSide;
    data->block.width       = blockSide;
    data->block.area        = blockSide * blockSide;
    data->block.offsetCount = (size_t)(blockSide * blockSide);
    data->block.offsetBytes = (size_t)(blockSide * blockSide) * 4;
    
    data->fullFrame.height      = frameHeight;
    data->fullFrame.width       = frameWidth;
    data->fullFrame.area        = frameWidth * frameHeight;
    data->fullFrame.offsetCount = (size_t)(frameWidth * frameHeight);
    data->fullFrame.offsetBytes = (size_t)(frameWidth * frameHeight) * 4;
    
    data->fullFrameRowBytes = frameWidth * 4;
    
    data->blocksPerWidthRoi = roiHeight / blockSide;
    data->blocksPerRoi      = (roiHeight * roiWidth) / (blockSide * blockSide);
    
    data->roiOriginPointX   = roi->origin.x;
    data->roiOriginPointY   = roi->origin.y;
    
    data->fftSetupLength    = fhgm_log2n(blockSide * blockSide) + 1 + 2; // 3
    data->fft2DLength       = fhgm_log2n(blockSide); 
}

void fhg_preOps_allocTemp(void **buffer, const struct FhgData *const restrict data)
{
    if (*buffer)
        free(*buffer);
    
    const vImage_Buffer input  = {
        .data     = NULL,
        .height   = data->roi.height,
        .width    = data->roi.width,
        .rowBytes = data->fullFrameRowBytes,
    };
    
    const vImage_Buffer output = {
        .data     = NULL,
        .height   = data->roi.height,
        .width    = data->roi.width,
        .rowBytes = data->roi.width * 4
    };
    
    const vImage_Error tempSizeResult = vImageScale_ARGB8888(&input, &output, NULL, kvImageGetTempBufferSize);
    FHGM_CPR_ASSERT(tempSizeResult > 0, "Temp size for scaling is negative.\nError = %ld", tempSizeResult);
    
    // MUL 2 FOR REDUNDENCY
    // SIZE IS (COUNT FOR SCALING) + (1 FULL FRAME) + (2 * ROI)
    const size_t elementCount = (size_t)tempSizeResult + (size_t)(data->fullFrame.area) + 2 * (size_t)(data->roi.area);
    
    *buffer = malloc(4 * elementCount);
    FHGM_CPR_ASSERT(*buffer != NULL, "Temp buffer is NULL", NULL);
}

void fhg_preOps_allocBlockBuffer(void **buffer, const struct FhgData *const restrict data)
{
    if (*buffer)
        free(*buffer);
    
    // SIZE IS NUMBER OF FRAMES * FRAME AREA
    const uint32_t elementCount = (data->numberOfFrames + 2) * data->fullFrame.area;
    
    *buffer = malloc(4 * (size_t)elementCount);
    FHGM_CPR_ASSERT(*buffer != NULL, "Temp buffer is NULL", NULL);
}


void fhg_ops_convertFullFrameToBlocks(const restrict CGImageRef fullFrame,
                                    const vImage_CGImageFormat *const restrict format,
                                    const struct FhgData *const restrict data,
                                    void *const restrict blocksBuffer,
                                    void *const restrict tempBuffer)
{
    void *const temp3 = tempBuffer;
    void *const temp1 = tempBuffer + data->roi.offsetBytes * 2;   // LEAVE SPACE FOR ONE ROI + ONE EXTRA
    void *const temp2 = temp1      + data->fullFrame.offsetBytes;       // LEAVE SPACE FOR ONE FRAME
    
    
    const vImage_Buffer regoinOfInterest     = fhgmCropFrameAndGetRoi(fullFrame, format, data, temp1, temp2, temp3);
    const vImage_Buffer roiBluePlane         = fhgmExtractPlaneNFromRoi(&regoinOfInterest, 0, temp2);
    const vImage_Buffer roiBluePlaneInFloats = fhgmConvertPlaneBytesToFloats(&roiBluePlane, temp1);
    
    fhgmFillBufferWithBlocks(&roiBluePlaneInFloats, blocksBuffer, data);
}



static inline void ftPad(const DSPSplitComplex *const restrict input,
                         const DSPSplitComplex *const restrict output,
                         const struct FhgData *const restrict data,
                         void *const restrict tempBuffer)
{
    static const float kZero = 0.f;
    static const float kFour = 4.f;
    
    const size_t bs = data->block.width;
    const size_t hs = bs / 2;
    const size_t ds = bs * 2;
    
    
    const DSPSplitComplex fourComplex = {  .realp = (float *)&kFour, .imagp = (float *)&kZero };
    const DSPSplitComplex inputMulFour = { .realp = tempBuffer, .imagp = tempBuffer + data->block.area * sizeof(float) };
    
    vDSP_zvzsml(input, 1, &fourComplex, &inputMulFour, 1, data->block.area);
    
    const float *const inpRealPtr = inputMulFour.realp;
    const float *const inpImagPtr = inputMulFour.imagp;
    
    float *const outRealPtr = output->realp;
    float *const outImagPtr = output->imagp;
    
    // 4 input quadrants indeces
    const size_t ia = 0;
    const size_t ib = hs;
    const size_t ic = bs * ib;
    const size_t iz = ic + ib;
    
    // 4 output quadrants indeces
    const size_t oa = 0;
    const size_t ob = ds - hs;
    const size_t oc = ds * ob;
    const size_t oz = oc + ob;
    
    
    vDSP_mmov(&inpRealPtr[ia], &outRealPtr[oa], hs, hs, bs, ds);
    vDSP_mmov(&inpRealPtr[ib], &outRealPtr[ob], hs, hs, bs, ds);
    vDSP_mmov(&inpRealPtr[ic], &outRealPtr[oc], hs, hs, bs, ds);
    vDSP_mmov(&inpRealPtr[iz], &outRealPtr[oz], hs, hs, bs, ds);
    
    vDSP_mmov(&inpImagPtr[ia], &outImagPtr[oa], hs, hs, bs, ds);
    vDSP_mmov(&inpImagPtr[ib], &outImagPtr[ob], hs, hs, bs, ds);
    vDSP_mmov(&inpImagPtr[ic], &outImagPtr[oc], hs, hs, bs, ds);
    vDSP_mmov(&inpImagPtr[iz], &outImagPtr[oz], hs, hs, bs, ds);
}
