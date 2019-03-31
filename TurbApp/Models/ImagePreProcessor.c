//
//  ImagePreProcessor.c
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "ImagePreProcessor.h"
#import "fhgm_c_private_resources.h"

// TEMP BUFFER Must be allocated with size >= sizeof(Pixel8888) * width * height
// WORKING !!!!
vImage_Buffer
fhgm_ipp_crop_pixel_buffer(CVPixelBufferRef imageBuffer,
                           const CGRect *const restrict roi,
                           void *const restrict temp_buffer)
{
    static const size_t kSizeOfPixel8888 = sizeof(Pixel_8888);          // 4
    
    const size_t height = (size_t)roi->size.height;
    const size_t width  = (size_t)roi->size.width;
    
    const size_t pointX = (size_t)roi->origin.x;
    const size_t pointY = (size_t)roi->origin.y;
    
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    void *const baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    const size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    const size_t startpos    = pointY * bytesPerRow + kSizeOfPixel8888 * pointX;
    
    vImage_Buffer inBuff = {
        .data     = baseAddress + startpos,
        .height   = (vImagePixelCount)height,
        .width    = (vImagePixelCount)width,
        .rowBytes = bytesPerRow
    };
    
    vImage_Buffer outBuff = {
        .data     = (Pixel_8888 *)temp_buffer, // malloc(kSizeOfPixel8888 * width * height),
        .height   = (vImagePixelCount)height,
        .width    = (vImagePixelCount)width,
        .rowBytes = kSizeOfPixel8888 * width
    };
    
    const vImage_Error err = vImageScale_ARGB8888(&inBuff, &outBuff, NULL, kvImageNoFlags);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in cropping vImage  =>  %ld", err);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    return outBuff;
}

vImage_Buffer
fhgm_ipp_crop_CG_Image(const CGImageRef cg_image,
                       const vImage_CGImageFormat *const restrict format,
                       const CGRect *const restrict roi,
                       void *const restrict temp_buffer)
{
    static const size_t kSizeOfPixel8888 = sizeof(Pixel_8888);          // 4
    
    const size_t height = (size_t)roi->size.height;
    const size_t width  = (size_t)roi->size.width;
    
    const size_t pointX = (size_t)roi->origin.x;
    const size_t pointY = (size_t)roi->origin.y;
    
    const size_t cgBytesPerRow = CGImageGetBytesPerRow(cg_image);
    const size_t startpos      = pointY * cgBytesPerRow + kSizeOfPixel8888 * pointX;
    
    void *const inTemp   = temp_buffer + kSizeOfPixel8888 * width * height + 64;
    
    vImage_Buffer inBuff = {
        .data     = inTemp,
        .height   = CGImageGetHeight(cg_image),
        .width    = CGImageGetWidth (cg_image),
        .rowBytes = cgBytesPerRow,
    };
    
    const vImage_Error convErr = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)format, NULL, cg_image, kvImageNoAllocate);
    FHGM_CPR_ASSERT(convErr == kvImageNoError, "Error in creating vImage from CGImage =>  %ld", convErr);
    
    
    inBuff.data  += startpos;
    inBuff.height = height;
    inBuff.width  = width;
    
    vImage_Buffer outBuff = {
        .data     = temp_buffer, // malloc(kSizeOfPixel8888 * width * height),
        .height   = (vImagePixelCount)height,
        .width    = (vImagePixelCount)width,
        .rowBytes = kSizeOfPixel8888 * width
    };
    
    
    void *const scTempNA = inTemp   + kSizeOfPixel8888 * CGImageGetHeight(cg_image) * CGImageGetWidth (cg_image);
    void *const scTemp   = scTempNA + (16 - ((uintptr_t)scTempNA & 15));
    
    const vImage_Error err = vImageScale_ARGB8888(&inBuff, &outBuff, scTemp, kvImageDoNotTile);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in cropping vImage  =>  %ld", err);
    
    return outBuff;
}

// 0 For blue, BGRA
vImage_Buffer
fhgm_ipp_extract_plane_from_bgra_planar8(const vImage_Buffer *const restrict imageBuffer,
                                         const long plane_num,
                                         void *const restrict temp_buffer)
{
    const size_t width  = (size_t)imageBuffer->width;
    const size_t height = (size_t)imageBuffer->height;
    
    vImage_Buffer planeBuff = {
        .data     = (Pixel_8 *)temp_buffer,
        .height   = (vImagePixelCount)height,
        .width    = (vImagePixelCount)width,
        .rowBytes = sizeof(Pixel_8) * width
    };
    
    const vImage_Error err = vImageExtractChannel_ARGB8888(imageBuffer, &planeBuff, plane_num, kvImageNoFlags | VIMAGE_FLAG);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
    
    return planeBuff;
}

vImage_Buffer
fhgm_ipp_convert_bytes_to_floats(const vImage_Buffer *const restrict imageBuffer,
                                 void *const restrict temp_buffer)
{
    const size_t width  = (size_t)imageBuffer->width;
    const size_t height = (size_t)imageBuffer->height;
    
    vImage_Buffer outBuff = {
        .data     = (Pixel_F *)temp_buffer,
        .height   = (vImagePixelCount)height,
        .width    = (vImagePixelCount)width,
        .rowBytes = sizeof(Pixel_F) * width
    };
    
    const vImage_Error err = vImageConvert_Planar8toPlanarF(imageBuffer, &outBuff, 1.f, 0.f, VIMAGE_FLAG);
    FHGM_CPR_ASSERT(err == kvImageNoError, "Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
    
    return outBuff;
}

void
fhgm_ipp_cut_image_into_raw_blocks_F(const vImage_Buffer *const restrict roiBuffer,
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
            
            const size_t srcIndex = ( iWidth + j) * blockSize;
            const size_t dstIndex = ( iCount + j) * blockSizeSq;
            
            const float *firstPixelInBlock = &firstPixelInRoi[srcIndex];
            float       *rawBlock          = blockRawBuffer + dstIndex;
            
            vDSP_mmov(firstPixelInBlock,       rawBlock,
                      (vDSP_Length)blockSize,  (vDSP_Length)blockSize,
                      (vDSP_Length)widthOfRoi, (vDSP_Length)blockSize);
        }
    }
}






/****************** TESTING **************************************************/
vImage_Buffer
fc_convert_floats_to_bytes(const vImage_Buffer *const restrict imageBuffer,
                           void *const restrict temp_buffer)
{
    const size_t width  = (size_t)imageBuffer->width;
    const size_t height = (size_t)imageBuffer->height;
    
    vImage_Buffer outBuff = {
        .data     = (Pixel_8 *)temp_buffer,
        .height   = (vImagePixelCount)height,
        .width    = (vImagePixelCount)width,
        .rowBytes = sizeof(Pixel_8) * width
    };
    
    const vImage_Error convErr = vImageConvert_PlanarFtoPlanar8(imageBuffer, &outBuff, 1.f, 0.f, VIMAGE_FLAG);
    FHGM_CPR_ASSERT(convErr == kvImageNoError, "Error in converting vImage from Planar8 to PlanarF  =>  %ld", convErr);
    
    return outBuff;
}

// Seems to be working
// Needs testing + Plotting
void
fc_cut_image_into_raw_blocks_F(const vImage_Buffer *const restrict roiBuffer,
                               float *const restrict blockRawBuffer,
                               const size_t blockSize,
                               const size_t sideBlocksCount)
{
    const size_t widthOfRoi     = (size_t)(roiBuffer->width);
    //    const size_t halfBlockCount = widthOfRoi / blockSize;
    const size_t blockSizeSq    = blockSize * blockSize;
    
    const float *const firstPixelInRoi = (float *)(roiBuffer->data);
    
    //    for (size_t i = 0; i < blocksCount; ++i) {
    for (size_t i = 0; i < sideBlocksCount; ++i) {
        for (size_t j = 0; j < sideBlocksCount; ++j) {
            
            //            const size_t fatIndex = i * blockSize;
            //            const size_t rowIndex = fatIndex / widthOfRoi;
            //
            //            const size_t srcIndex = fatIndex + rowIndex * widthOfRoi;
            //            const size_t dstIndex = i * blockSize * blockSize;
            
            const size_t srcIndex = (i * widthOfRoi      + j) * blockSize;
            const size_t dstIndex = (i * sideBlocksCount + j) * blockSizeSq;
            
            //            printf("@%lu, fi = %lu, ri = %lu, wr = %lu, %lu, %lu, %lu, %lu  (%p)\n",
            //                   i, fatIndex, rowIndex, widthOfRoi, srcIndex, dstIndex, blocksCount, blockSize, firstPixelInRoi + srcIndex);
            
            const float *const firstPixelInBlock = &firstPixelInRoi[srcIndex];
            float *const rawBlock = blockRawBuffer + dstIndex;
            
            vDSP_mmov(firstPixelInBlock,
                      rawBlock,
                      (vDSP_Length)blockSize,
                      (vDSP_Length)blockSize,
                      (vDSP_Length)widthOfRoi,
                      (vDSP_Length)blockSize);
        }
        
    }
}

// IMPORTANT
// ALL data pointers in arrayOfBlocks should be already allocated with
// (Pixel_F *)malloc(kSizeOfOnePixel (sizeof Pixel_F) * blockSize * blockSize);
void
fc_cut_image_into_blocks_F(const vImage_Buffer *const restrict roiBuffer,
                           vImage_Buffer *const restrict arrayOfBlocks,
                           const size_t blockSize,
                           void *const restrict temp_buffer)
{
    const size_t widthInRoi        = (size_t)(roiBuffer->width);
    const size_t bytesPerRowInRoi  = roiBuffer->rowBytes;
    
    const size_t blocksCount       = widthInRoi * widthInRoi / (blockSize * blockSize);
    
    Pixel_F *const firstPixelInRoi = (Pixel_F *)(roiBuffer->data);
    
    void *const tempBufferForScaling = temp_buffer; //malloc(tempBufferSize);
    
    vImage_Buffer tempImageBuffer = {
        .data       = NULL,
        .height     = (vImagePixelCount)blockSize,
        .width      = (vImagePixelCount)blockSize,
        .rowBytes   = bytesPerRowInRoi
    };
    
    //    printf("BC: %lu, wir = %lu, bpr = %lu, bs = %lu\n", blocksCount, widthInRoi, bytesPerRowInRoi, blockSize);
    
    for (size_t i = 0; i < blocksCount; ++i) {
        
        const size_t fatIndex = i * blockSize;
        const size_t rowIndex = fatIndex / widthInRoi;
        
        Pixel_F *const firstPixelInBlock = &firstPixelInRoi[fatIndex + rowIndex * widthInRoi];
        
        tempImageBuffer.data = firstPixelInBlock;
        
        vImage_Error err =  vImageScale_PlanarF(&tempImageBuffer, &arrayOfBlocks[i], tempBufferForScaling, kvImageNoFlags | kvImagePrintDiagnosticsToConsole);
        FHGM_CPR_ASSERT(err == kvImageNoError, "Error while cutting image to blocks (F)  =>  %ld", err);
    }
}

// IMPORTANT
// ALL data pointers in arrayOfBlocks should be already allocated with
// (Pixel_F *)malloc(kSizeOfOnePixel (sizeof Pixel_8) * blockSize * blockSize);
void
fc_cut_image_into_blocks_8(const vImage_Buffer *const restrict roiBuffer,
                           vImage_Buffer *const restrict arrayOfBlocks,
                           const size_t blockSize,
                           void *restrict temp_buffer)
{
    const size_t widthInRoi             = (size_t)(roiBuffer->width);
    const size_t bytesPerRowInRoi       = roiBuffer->rowBytes;
    
    const size_t blocksCount            = widthInRoi * widthInRoi / (blockSize * blockSize);
    
    Pixel_8 *const firstPixelInRoi = (Pixel_8 *)(roiBuffer->data);
    
    void *const tempBufferForScaling = temp_buffer;
    
    vImage_Buffer tempImageBuffer = {
        .data       = NULL,
        .height     = (vImagePixelCount)blockSize,
        .width      = (vImagePixelCount)blockSize,
        .rowBytes   = bytesPerRowInRoi
    };
    
    for (size_t i = 0; i < blocksCount; ++i) {
        
        const size_t fatIndex = i * blockSize;
        const size_t rowIndex = fatIndex / widthInRoi;
        
        Pixel_8 *const firstPixelInBlock = &firstPixelInRoi[fatIndex + rowIndex * widthInRoi];
        
        tempImageBuffer.data = firstPixelInBlock;
        
        vImage_Error err =  vImageScale_Planar8(&tempImageBuffer, &arrayOfBlocks[i], tempBufferForScaling, kvImageNoFlags);
        FHGM_CPR_ASSERT(err == kvImageNoError, "Error while cutting image to blocks (8)  =>  %ld", err);
    }
}
