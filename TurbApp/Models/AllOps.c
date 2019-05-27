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

