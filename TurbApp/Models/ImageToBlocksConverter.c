//
//  ImageToBlocksConverter.c
//  TurbApp
//
//  Created by Samuel Aysser on 20.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#include "ImageToBlocksConverter.h"
#import "fhgm_c_private_resources.h"
#import "ModelsResources.h"

// Step One, Crop the full image to ROI
vImage_Buffer
fhgmCropFrameAndGetRoi(const CGImageRef cg_image,
                       const vImage_CGImageFormat *const restrict format,
                       const struct FhgData *const restrict data,
                       void *const restrict temp1CG,      // SIZEOF CGIMAGE
                       void *const restrict temp2CG,      // SIZEOF CGIMAGE
                       void *const restrict temp3Roi)    // SIZEOF ROI (OUTPUT, DO NOT RE-USE WITH OTHER FUNCTIONS)
{
    static const size_t kSizeOfPixel8888 = sizeof(Pixel_8888);          // 4
    
    const size_t roiHeight = (size_t)data->roi.height;
    const size_t roiWidth  = (size_t)data->roi.width;
    
    const size_t pointX = (size_t)data->roiOriginPointX;
    const size_t pointY = (size_t)data->roiOriginPointY;
    
    const size_t cgBytesPerRow = CGImageGetBytesPerRow(cg_image);
    const size_t startPos      = pointY * cgBytesPerRow + kSizeOfPixel8888 * pointX;
    
    vImage_Buffer inBuff = {
        .data     = temp1CG,
        .height   = CGImageGetHeight(cg_image),
        .width    = CGImageGetWidth (cg_image),
        .rowBytes = cgBytesPerRow,
    };
    
    const vImage_Error convErr = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)format, NULL, cg_image, kvImageNoAllocate);
    FHGM_CPR_ASSERT(convErr == kvImageNoError, "Error in creating vImage from CGImage =>  %ld", convErr);
    
    inBuff.data  += startPos;
    inBuff.height = roiHeight;
    inBuff.width  = roiWidth;
    
    vImage_Buffer outBuff = {
        .data     = temp3Roi,
        .height   = roiHeight,
        .width    = roiWidth,
        .rowBytes = kSizeOfPixel8888 * roiWidth
    };
    
    const vImage_Error err = vImageScale_ARGB8888(&inBuff, &outBuff, temp2CG, kvImageDoNotTile);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in cropping vImage  =>  %ld", err);
    
    return outBuff;
}

// 0 For blue, BGRA
vImage_Buffer
fhgmExtractPlaneNFromRoi(const vImage_Buffer *const restrict imageBuffer,
                         const long plane_num,
                         void *const restrict temp_buffer)
{
    vImage_Buffer planeBuff = {
        .data     = temp_buffer,
        .height   = imageBuffer->height,
        .width    = imageBuffer->width,
        .rowBytes = sizeof(Pixel_8) * imageBuffer->width,
    };
    
    const vImage_Error err = vImageExtractChannel_ARGB8888(imageBuffer, &planeBuff, plane_num, kvImageDoNotTile);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
    
    return planeBuff;
}

vImage_Buffer
fhgmConvertPlaneBytesToFloats(const vImage_Buffer *const restrict imageBuffer,
                              void *const restrict temp_buffer)
{
    vImage_Buffer outBuff = {
        .data     = temp_buffer,
        .height   = imageBuffer->height,
        .width    = imageBuffer->width,
        .rowBytes = sizeof(Pixel_F) * imageBuffer->width
    };
    
    const vImage_Error err = vImageConvert_Planar8toPlanarF(imageBuffer, &outBuff, 1.f, 0.f, kvImageDoNotTile);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
    
    return outBuff;
}

void
fhgmFillBufferWithBlocks(const vImage_Buffer *const restrict roiBuffer,
                         float *const restrict blockRawBuffer,
                         const struct FhgData *const restrict data)
{
    const size_t widthOfRoi      = (size_t)(roiBuffer->width);
    const size_t blockSize       = (size_t)data->block.width;
    const size_t blockSizeSq     = (size_t)data->block.area;
    const size_t sideBlocksCount = (size_t)data->blocksPerWidthRoi;
    
    const float *const firstPixelInRoi = (float *)(roiBuffer->data);
    
    for (size_t i = 0; i < sideBlocksCount; ++i) {
        
        const size_t iWidth = i * widthOfRoi;
        const size_t iCount = i * sideBlocksCount;
        
        for (size_t j = 0; j < sideBlocksCount; ++j) {
            
            const size_t srcIndex = (iWidth + j) * blockSize;
            const size_t dstIndex = (iCount + j) * blockSizeSq;
            
            const float *firstPixelInBlock = &firstPixelInRoi[srcIndex];
            float       *rawBlock          = blockRawBuffer + dstIndex;
            
            vDSP_mmov(firstPixelInBlock, rawBlock, blockSize, blockSize, widthOfRoi, blockSize);
        }
    }
}




/*********************************** OLD ********************************************/

vImage_Buffer
fhgmCropLargeImageGetRoi(const CGImageRef cg_image,
                         const vImage_CGImageFormat *const restrict format,
                         const CGRect *const restrict roi,
                         void *const restrict temp1CG,
                         void *const restrict temp2CG,
                         void *const restrict temp3Roi)
{
    static const size_t kSizeOfPixel8888 = sizeof(Pixel_8888);          // 4
    
    const size_t roiHeight = (size_t)roi->size.height;
    const size_t roiWidth  = (size_t)roi->size.width;
    
    const size_t pointX = (size_t)roi->origin.x;
    const size_t pointY = (size_t)roi->origin.y;
    
    const size_t cgBytesPerRow = CGImageGetBytesPerRow(cg_image);
    const size_t startPos      = pointY * cgBytesPerRow + kSizeOfPixel8888 * pointX;
    
    //void *const inTemp   = temp_buffer + kSizeOfPixel8888 * roiWidth * roiHeight + 64; // OFFSET, LEAVE PLACE FOR THE OUTPUT
    
    vImage_Buffer inBuff = {
        .data     = temp1CG,
        .height   = CGImageGetHeight(cg_image),
        .width    = CGImageGetWidth (cg_image),
        .rowBytes = cgBytesPerRow,
    };
    
    const vImage_Error convErr = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)format, NULL, cg_image, kvImageNoAllocate);
    FHGM_CPR_ASSERT(convErr == kvImageNoError, "Error in creating vImage from CGImage =>  %ld", convErr);
    
    inBuff.data  += startPos;
    inBuff.height = roiHeight;
    inBuff.width  = roiWidth;
    
    vImage_Buffer outBuff = {
        .data     = temp3Roi, // malloc(kSizeOfPixel8888 * width * height),
        .height   = roiHeight,
        .width    = roiWidth,
        .rowBytes = kSizeOfPixel8888 * roiWidth
    };
    
    
    //    void *const scTempNA = inTemp   + kSizeOfPixel8888 * CGImageGetHeight(cg_image) * CGImageGetWidth(cg_image);
    //    void *const scTemp   = scTempNA + (16 - ((uintptr_t)scTempNA & 15)); // ALIGN
    
    const vImage_Error err = vImageScale_ARGB8888(&inBuff, &outBuff, temp2CG, kvImageDoNotTile);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in cropping vImage  =>  %ld", err);
    
    return outBuff;
}


void
fhgmGetBlockAndFillBuffer(const vImage_Buffer *const restrict roiBuffer,
                          float *const restrict blockRawBuffer,
                          const size_t blockSize,
                          const size_t sideBlocksCount)
{
    const size_t widthOfRoi     = (size_t)(roiBuffer->width);
    const size_t blockSizeSq    = blockSize * blockSize;

    const float *const firstPixelInRoi = (float *)(roiBuffer->data);

    for (size_t i = 0; i < sideBlocksCount; ++i) {

        const size_t iWidth = i * widthOfRoi;
        const size_t iCount = i * sideBlocksCount;

        for (size_t j = 0; j < sideBlocksCount; ++j) {

            const size_t srcIndex = (iWidth + j) * blockSize;
            const size_t dstIndex = (iCount + j) * blockSizeSq;

            const float *firstPixelInBlock = &firstPixelInRoi[srcIndex];
            float       *rawBlock          = blockRawBuffer + dstIndex;

            vDSP_mmov(firstPixelInBlock, rawBlock, blockSize, blockSize, widthOfRoi, blockSize);
        }
    }
}
