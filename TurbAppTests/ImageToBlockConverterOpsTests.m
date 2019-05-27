//
//  ImageToBlockConverterOpsTests.m
//  TurbAppTests
//
//  Created by Samuel Aysser on 20.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifdef OLD_TEST

#import <XCTest/XCTest.h>
#import <stdint.h>
#import "../TurbApp/Models/ImageToBlocksConverter.h"
#import "../TurbApp/Models/AllOps.h"
#import "../TurbApp/Models/ModelsResources.h"

static const size_t imgHeight = 8;
static const size_t imgWidth  = 12;

// SHOULD BE BLUE PIXEL 31
static const size_t x = 4;
static const size_t y = 2;

static const uint8_t originalImage[imgHeight * imgWidth * 4] = {
     3,0,1,2,    4,0,1,2,   5,0,1,2,   6,0,1,2,  7,0,1,2,   8,0,1,2,   9,0,1,2,  10,0,1,2,  11,0,1,2,  12,0,1,2,  13,0,1,2,  14,0,1,2,
    15,0,1,2,   16,0,1,2,  17,0,1,2,  18,0,1,2, 19,0,1,2,  20,0,1,2,  21,0,1,2,  22,0,1,2,  23,0,1,2,  24,0,1,2,  25,0,1,2,  26,0,1,2,
    27,0,1,2,   28,0,1,2,  29,0,1,2,  30,0,1,2, 31,0,1,2,  32,0,1,2,  33,0,1,2,  34,0,1,2,  35,0,1,2,  36,0,1,2,  37,0,1,2,  38,0,1,2,
    39,0,1,2,   40,0,1,2,  41,0,1,2,  42,0,1,2, 43,0,1,2,  44,0,1,2,  45,0,1,2,  46,0,1,2,  47,0,1,2,  48,0,1,2,  49,0,1,2,  50,0,1,2,
    51,0,1,2,   52,0,1,2,  53,0,1,2,  54,0,1,2, 55,0,1,2,  56,0,1,2,  57,0,1,2,  58,0,1,2,  59,0,1,2,  60,0,1,2,  61,0,1,2,  62,0,1,2,
    63,0,1,2,   64,0,1,2,  65,0,1,2,  66,0,1,2, 67,0,1,2,  68,0,1,2,  69,0,1,2,  70,0,1,2,  71,0,1,2,  72,0,1,2,  73,0,1,2,  74,0,1,2,
    75,0,1,2,   76,0,1,2,  77,0,1,2,  78,0,1,2, 79,0,1,2,  80,0,1,2,  81,0,1,2,  82,0,1,2,  83,0,1,2,  84,0,1,2,  85,0,1,2,  86,0,1,2,
    87,0,1,2,   88,0,1,2,  89,0,1,2,  90,0,1,2, 91,0,1,2,  92,0,1,2,  93,0,1,2,  94,0,1,2,  95,0,1,2,  96,0,1,2,  97,0,1,2,  98,0,1,2,
};

static const uint8_t originalImage2[imgHeight * imgWidth * 4] = {
    85,0,1,2,   86,0,1,2,  75,0,1,2,  76,0,1,2, 77,0,1,2,  78,0,1,2,  79,0,1,2,  80,0,1,2,  81,0,1,2,  82,0,1,2,  83,0,1,2,  84,0,1,2,
    96,0,1,2,   97,0,1,2,  98,0,1,2,  87,0,1,2, 88,0,1,2,  89,0,1,2,  90,0,1,2,  91,0,1,2,  92,0,1,2,  93,0,1,2,  94,0,1,2,  95,0,1,2,
    14,0,1,2,    3,0,1,2,   4,0,1,2,   5,0,1,2,  6,0,1,2,   7,0,1,2,   8,0,1,2,   9,0,1,2,  10,0,1,2,  11,0,1,2,  12,0,1,2,  13,0,1,2,
    23,0,1,2,   24,0,1,2,  25,0,1,2,  26,0,1,2, 15,0,1,2,  16,0,1,2,  17,0,1,2,  18,0,1,2,  19,0,1,2,  20,0,1,2,  21,0,1,2,  22,0,1,2,
    34,0,1,2,   35,0,1,2,  36,0,1,2,  37,0,1,2, 38,0,1,2,  27,0,1,2,  28,0,1,2,  29,0,1,2,  30,0,1,2,  31,0,1,2,  32,0,1,2,  33,0,1,2,
    45,0,1,2,   46,0,1,2,  47,0,1,2,  48,0,1,2, 49,0,1,2,  50,0,1,2,  39,0,1,2,  40,0,1,2,  41,0,1,2,  42,0,1,2,  43,0,1,2,  44,0,1,2,
    51,0,1,2,   52,0,1,2,  53,0,1,2,  54,0,1,2, 55,0,1,2,  56,0,1,2,  57,0,1,2,  58,0,1,2,  59,0,1,2,  60,0,1,2,  61,0,1,2,  62,0,1,2,
    68,0,1,2,   69,0,1,2,  70,0,1,2,  71,0,1,2, 72,0,1,2,  73,0,1,2,  74,0,1,2,  63,0,1,2,  64,0,1,2,  65,0,1,2,  66,0,1,2,  67,0,1,2,
};

@interface ImageToBlockConverterOpsTests : XCTestCase

@end

@implementation ImageToBlockConverterOpsTests {
    void *temp1;
    void *temp2;
    void *temp3;
    
    void *blockBuffer;
    
    CGRect roi;
    CGImageRef cgOriginalImage;
    vImage_CGImageFormat cgFormat;
    
    vImage_Buffer imageACroppedToRoi;
    vImage_Buffer imageBPlane;
    vImage_Buffer imageCPlaneInFloats;
    vImage_Buffer imageD;
    
    size_t blockSize;
    size_t blockArea;
    size_t blocksPerFrame;
    size_t frameArea;
    
}

//- (void)setUp {
//    // Put setup code here. This method is called before the invocation of each test method in the class.
//    temp1 = calloc(1, 4 * imgHeight * imgWidth);
//    temp2 = calloc(1, 4 * imgHeight * imgWidth);
//    temp3 = calloc(1, 4 * 4 * 4);
//    
//    roi = CGRectMake((CGFloat)x, (CGFloat)y, 4.f, 4.f);
//    
//    CFDataRef data = CFDataCreate(NULL, originalImage, imgHeight * imgWidth * 4);
//    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(data);
//    //CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, originalImage, imgHeight * imgWidth * 4, NULL);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    cgOriginalImage  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider,
//                                     NULL, NO, kCGRenderingIntentDefault);
//    
//    cgFormat.bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
//    cgFormat.bitsPerComponent = 8;
//    cgFormat.bitsPerPixel = 4 * 8;
//    cgFormat.colorSpace = colorSpace;
//    cgFormat.decode = NULL;
//    cgFormat.renderingIntent = kCGRenderingIntentDefault;
//    cgFormat.version = 0;
//    
//    CFRelease(data);
//    CGDataProviderRelease(dataProvider);
//    
//    blockSize = 2;
//    blockArea = 2 * 2;
//    blocksPerFrame = CGRectGetWidth(roi) * CGRectGetHeight(roi) / blockArea;
//    blockBuffer = malloc(4 * 16);
//    frameArea = 4 * 4;
//    
//    printf("bpf = %lu\n", (unsigned long)blocksPerFrame);
//    
//    printf("%u, %u %u", CGImageGetAlphaInfo(cgOriginalImage), CGImageGetBitmapInfo(cgOriginalImage), CGImageGetByteOrderInfo(cgOriginalImage));
//}
//
//- (void)tearDown {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//    CGImageRelease(cgOriginalImage);
//    CGColorSpaceRelease(cgFormat.colorSpace);
//}
//
//- (void)testPrintOrigImage {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//    printf("\n\\***********************************************\\\n"); // CHECK
//    for (size_t i = 0; i < imgHeight; ++i) {
//        for (size_t j = 0; j < imgWidth; ++j) {
//            printf("%hu,%hu,%hu,%hu  ",
//                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 0],
//                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 1],
//                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 2],
//                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 3]);
//        }
//        
//        printf("\n\n");
//    }
//    printf("\n\\***********************************************\\\n");
//}
//
//- (void)testGetMemory {
//    vImage_Buffer inBuff  = {NULL, 4, 4, 4 * imgWidth};
//    vImage_Buffer outBuff = {NULL, 4, 4, 4 * 4};
//    
//    const int a = (int)vImageScale_ARGB8888(&inBuff, &outBuff, NULL, kvImageGetTempBufferSize);
//    printf("memory = %d,   %lu\n", a, (unsigned long)sizeof(NSUInteger));
//}
//
//- (void)testPrintCGOrigImage {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//    
//    vImage_Buffer inBuff = {
//        .data     = temp1,
//        .height   = CGImageGetHeight(cgOriginalImage),
//        .width    = CGImageGetWidth (cgOriginalImage),
//        .rowBytes = CGImageGetBytesPerRow(cgOriginalImage),
//    };
//    
//    const vImage_Error convErr = vImageBuffer_InitWithCGImage(&inBuff, &cgFormat, NULL, cgOriginalImage, kvImageNoAllocate);
//    if (convErr != kvImageNoError) {
//        printf("ERROR = %d\n", (int)convErr);
//        return;
//    }
//    
//    const uint8_t *const temp = (uint8_t *)temp1;
//    printf("\n\\***********************************************\\\n"); // CHECK
//    for (size_t i = 0; i < imgHeight; ++i) {
//        for (size_t j = 0; j < imgWidth; ++j) {
//            printf("%hu,%hu,%hu,%hu  ",
//                   (uint16_t)temp[i * imgWidth * 4 + j * 4 + 0],
//                   (uint16_t)temp[i * imgWidth * 4 + j * 4 + 1],
//                   (uint16_t)temp[i * imgWidth * 4 + j * 4 + 2],
//                   (uint16_t)temp[i * imgWidth * 4 + j * 4 + 3]);
//        }
//        
//        printf("\n\n");
//    }
//    printf("\n\\***********************************************\\\n");
//}
//
//- (void)testCrop {
//    
//    imageACroppedToRoi = fhgmCropLargeImageGetRoi(cgOriginalImage, &cgFormat, &roi, temp1, temp2, temp3);
//    const uint8_t *const data = (uint8_t *)imageACroppedToRoi.data;
//    
//    printf("\n\\***********************************************\\\n");
//    for (size_t i = 0; i < 4; ++i) {
//        for (size_t j = 0; j < 4; ++j) {
//            printf("%hi,%hi,%hi,%hi,  ",
//                   (uint16_t)data[j * 4 + i * 4 * 4 + 0],
//                   (uint16_t)data[j * 4 + i * 4 * 4 + 1],
//                   (uint16_t)data[j * 4 + i * 4 * 4 + 2],
//                   (uint16_t)data[j * 4 + i * 4 * 4 + 3]);
//        }
//        printf("\n");
//    }
//    printf("\n\\***********************************************\\\n");
//    
//    const size_t indexA = 4*x + 4*y*imgWidth;
//    const size_t indexB = 4*(x+4-1) + 4*(y+4-1)*imgWidth;
//    
//    XCTAssertEqual(originalImage[indexA], *data,
//                   @"Error, originalImage[%lu] = %hu != data[0] = %hu",
//                   indexA, (uint16_t)originalImage[indexA], (uint16_t)(*data));
//    XCTAssertEqual(originalImage[indexB], *(data + 15 * 4),
//                   @"Error, originalImage[%lu] = %hu != data[%lu] = %hu",
//                   indexB, (uint16_t)originalImage[indexB], 15ul*4, (uint16_t)(*(data + 15 * 4)));
//
//}
//
//- (void)testExtractPlane {
//    [self testCrop];
//    
//    imageBPlane = fhgmExtractPlaneNFromRoi(&imageACroppedToRoi, 0, temp1);
//    
//    const uint8_t *const pata = (uint8_t *)imageBPlane.data;
//    
//    printf("\n\\***********************************************\\");
//    for(size_t i = 0; i < 16; ++i)
//        printf("%s%hu, ", ((i & 3) ? "":"\n"), (uint16_t)pata[i]);
//    printf("\n\\***********************************************\\\n");
//    
//    const size_t indexA = 4*x + 4*y*imgWidth;
//    const size_t indexB = 4*(x+4-1) + 4*(y+4-1)*imgWidth;
//    
//    XCTAssertEqual(originalImage[indexA], *pata,
//                   @"Error, originalImage[%lu] = %hu != data[0] = %hu",
//                   indexA, (uint16_t)originalImage[indexA], (uint16_t)(*pata));
//    XCTAssertEqual(originalImage[indexB], *(pata + 15),
//                   @"Error, originalImage[%lu] = %hu != data[%lu] = %hu",
//                   indexB, (uint16_t)originalImage[indexB], 15ul, (uint16_t)(*(pata + 15)));
//}
//
//- (void)testCreateFloatPlane {
//    [self testExtractPlane];
//    
//    imageCPlaneInFloats = fhgmConvertPlaneBytesToFloats(&imageBPlane, temp2);
//    
//    const uint8_t *const pata = (uint8_t *)imageBPlane.data;
//    const float *const fata = (float *)imageCPlaneInFloats.data;
//    
//    printf("\n\\***********************************************\\");
//    for (size_t i = 0; i < 16; ++i)
//        printf("%s%f, ", ((i & 3) ? "":"\n"), (float)fata[i]);
//    printf("\n\\***********************************************\\\n");
//    
//    for (size_t i = 0; i < 16; ++i) {
//        const float testValue = (float)pata[i] / 255.f;
//        XCTAssertLessThan(fabsf(testValue - fata[i]), FLT_EPSILON,
//                          "ERROR! %hu / 255 = %f  !=  %f",
//                          (uint16_t)pata[i], testValue, fata[i]);
//    }
//}
//
//- (void)testCreateBlocks {
//    [self testCreateFloatPlane];
//    fhgmGetBlockAndFillBuffer(&imageCPlaneInFloats, blockBuffer, blockSize, 2);
//    const float *const data = (float *)blockBuffer;
//    
//    printf("raw ==> %lu & %lu\nfloat ==> %lu & %lu",
//           (uintptr_t)blockBuffer, (uintptr_t)(blockBuffer + 1),
//           (uintptr_t)data, (uintptr_t)(data + 1));
//    
//    printf("\n\\***********************************************\\\n");
//    for (size_t i = 0; i < blocksPerFrame; ++i) {
//        const float *const frameStart = data + i * blockArea;
//        for (size_t j = 0; j < blockSize; ++j) {
//            for (size_t k = 0; k < blockSize; ++k) {
//                printf("%f, ", frameStart[j * blockSize + k]);
//            }
//            printf("\n");
//        }
//        printf("\n");
//    }
//    
//    printf("\n\\***********************************************\\");
//    for (size_t i = 0; i < 16; ++i)
//        printf("%s%f, ", ((i & 3) ? "":"\n"), data[i]);
//    printf("\n\\***********************************************\\\n");
//    
//    const float *const fata = (float *)imageCPlaneInFloats.data;
//    size_t index = 0;
//    for (size_t i = 0; i < blocksPerFrame; ++i) {
//        const float *const roiStart   = fata + i * blockSize + (i >= blockSize) * blockArea;
//        const float *const blockStart = data + i * blockArea;
//        
//        
//        for (size_t j = 0; j < blockSize; ++j) {
//            for (size_t k = 0; k < blockSize; ++k) {
//                const float orgnlVal = roiStart[j * blockArea + k];
//                const float blockVal = blockStart[j * blockSize + k];
//                
//                
//                XCTAssertLessThan(fabsf(orgnlVal - blockVal), FLT_EPSILON,
//                                  "ERROR! @ index %lu out of %lu ==>  %f  !=  %f",
//                                  index++, 16ul, orgnlVal, blockVal);
//            }
//        }
//    }
//}
//
//- (void)testMultipleFrames {
//    void *const bbuf = malloc(sizeof(float) * 2 * frameArea);
//    void *const temp = malloc(4 * (10 * frameArea + blockArea));
//    
//    void *const tmp1 = temp + frameArea * sizeof(Pixel_8888);
//    void *const tmp2 = temp + frameArea * sizeof(Pixel_8888) * 2;
//    void *const tmp3 = temp;
//    
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    CFDataRef data1 = CFDataCreate(NULL, originalImage, imgHeight * imgWidth * 4);
//    CGDataProviderRef dataProvider1 = CGDataProviderCreateWithCFData(data1);
//    CGImageRef cgImage1  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider1, NULL, NO, kCGRenderingIntentDefault);
//    
//    CFDataRef data2 = CFDataCreate(NULL, originalImage2, imgHeight * imgWidth * 4);
//    CGDataProviderRef dataProvider2 = CGDataProviderCreateWithCFData(data2);
//    CGImageRef cgImage2  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider2, NULL, NO, kCGRenderingIntentDefault);
//    
//    CFRelease(data1);
//    CGDataProviderRelease(dataProvider1);
//    CFRelease(data2);
//    CGDataProviderRelease(dataProvider2);
//    
//    vImage_Buffer img1A = fhgmCropLargeImageGetRoi(cgImage1, &cgFormat, &roi, tmp1, tmp2, tmp3);
//    vImage_Buffer img1B = fhgmExtractPlaneNFromRoi(&img1A, 0, tmp2);
//    vImage_Buffer img1C = fhgmConvertPlaneBytesToFloats(&img1B, tmp1);
//    fhgmGetBlockAndFillBuffer(&img1C, bbuf, blockSize, 2);
//    
//    vImage_Buffer img2A = fhgmCropLargeImageGetRoi(cgImage2, &cgFormat, &roi, tmp1, tmp2, tmp3);
//    vImage_Buffer img2B = fhgmExtractPlaneNFromRoi(&img2A, 0, tmp2);
//    vImage_Buffer img2C = fhgmConvertPlaneBytesToFloats(&img2B, tmp1);
//    fhgmGetBlockAndFillBuffer(&img2C, bbuf + frameArea * 4, blockSize, 2);
//    
//    printf("\n\\***********************************************\\");
//    for (size_t i = 0; i < 2 * frameArea; ++i)
//        printf("%s%f, ", ((i & 3) ? "":"\n"), ((float *)bbuf)[i] * 255.);
//    printf("\n\\***********************************************\\\n");
//    printf("\n\\***********************************************\\\n");
//    for (size_t i = 0; i < 2; ++i) {
//        for (size_t j = 0; j < blocksPerFrame; ++j) {
//            for (size_t k = 0; k < blockArea; ++k) {
//                const float pix = ((float *)bbuf)[i * frameArea + j * blockArea + k];
//                
//                printf("%f, ", pix * 255.);
//            }
//            printf("\n");
//        }
//        printf("\n");
//    }
//    printf("\n\\***********************************************\\\n");
//    
//    const float *const data = (float *)bbuf;
//    
//    const int opix111 = (int)originalImage[4 * (y*imgWidth + x)];
//    const int ppix111 = (int)lroundf(data[0] * 255.);
//    
//    const int opix112 = (int)originalImage2[4 * (y*imgWidth + x)];
//    const int ppix112 = (int)lroundf(data[frameArea] * 255.);
//    
//    XCTAssertEqual(opix111, ppix111,
//                   @"ERROR! @ first pixel of first block of FIRST frame is not correct\n==>  %d  !=  %d",
//                   opix111, ppix111);
//    XCTAssertEqual(opix112, ppix112,
//                   @"ERROR! @ first pixel of first block of SECOND frame is not correct\n==>  %d  !=  %d",
//                   opix112, ppix112);
//}
//
//- (void)testFirstStepFully {
//    
//    vImage_CGImageFormat format;
//    
//    void *temp = NULL;
//    void *bbuf = NULL;
//    
//    struct FhgData data;
//    fhg_preOps_createData(&data, 2, 2, &roi, imgHeight, imgWidth);
//    
//    fhg_preOps_createCGFormat(&format);
//    fhg_preOps_allocTemp(&temp, &data);
//    fhg_preOps_allocBlockBuffer(&temp, &data);
//    
//    CFDataRef data1 = CFDataCreate(NULL, originalImage, imgHeight * imgWidth * 4);
//    CFDataRef data2 = CFDataCreate(NULL, originalImage2, imgHeight * imgWidth * 4);
//    
//    CGDataProviderRef dataProvider1 = CGDataProviderCreateWithCFData(data1);
//    CGDataProviderRef dataProvider2 = CGDataProviderCreateWithCFData(data2);
//    
//    CGImageRef cgImage1  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, format.colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider1, NULL, NO, kCGRenderingIntentDefault);
//    CGImageRef cgImage2  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, format.colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider2, NULL, NO, kCGRenderingIntentDefault);
//    
//    CFRelease(data1);
//    CFRelease(data2);
//    
//    CGDataProviderRelease(dataProvider1);
//    CGDataProviderRelease(dataProvider2);
//    
//    fhg_ops_convertFullFrameToBlocks(cgImage1, &format, &data, bbuf, temp);
//    fhg_ops_convertFullFrameToBlocks(cgImage2, &format, &data, bbuf + data.roi.offsetBytes, temp);
//    
//    printf("\n\\***********************************************\\");
//    for (size_t i = 0; i < 2 * data.roi.offsetCount; ++i)
//        printf("%s%f, ", ((i & 3) ? "":"\n"), ((float *)bbuf)[i] * 255.);
//    printf("\n\\***********************************************\\\n");
//    printf("\n\\***********************************************\\\n");
//    for (size_t i = 0; i < data.numberOfFrames; ++i) {
//        for (size_t j = 0; j < data.blocksPerRoi; ++j) {
//            for (size_t k = 0; k < data.block.offsetCount; ++k) {
//                const float pix = ((float *)bbuf)[i * frameArea + j * blockArea + k];
//                
//                printf("%f, ", pix * 255.);
//            }
//            printf("\n");
//        }
//        printf("\n");
//    }
//    printf("\n\\***********************************************\\\n");
//    
////    const float *const data = (float *)bbuf;
////    
////    const int opix111 = (int)originalImage[4 * (y*imgWidth + x)];
////    const int ppix111 = (int)lroundf(data[0] * 255.);
////    
////    const int opix112 = (int)originalImage2[4 * (y*imgWidth + x)];
////    const int ppix112 = (int)lroundf(data[frameArea] * 255.);
////    
////    XCTAssertEqual(opix111, ppix111,
////                   @"ERROR! @ first pixel of first block of FIRST frame is not correct\n==>  %d  !=  %d",
////                   opix111, ppix111);
////    XCTAssertEqual(opix112, ppix112,
////                   @"ERROR! @ first pixel of first block of SECOND frame is not correct\n==>  %d  !=  %d",
////                   opix112, ppix112);
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end

#endif
