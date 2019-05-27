//
//  ImageToBlockConverterOpsDataTests.m
//  TurbAppTests
//
//  Created by Samuel Aysser on 22.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

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

@interface ImageToBlockConverterOpsDataTests : XCTestCase

@end

@implementation ImageToBlockConverterOpsDataTests {
    void *temp;
    void *blockBuffer;
    
    CGRect roi;
    CGImageRef cgOriginalImage1;
    CGImageRef cgOriginalImage2;
    vImage_CGImageFormat cgFormat;
    
    vImage_Buffer imageACroppedToRoi;
    vImage_Buffer imageBPlane;
    vImage_Buffer imageCPlaneInFloats;
    vImage_Buffer imageD;
    
    struct FhgData data;
    
}

- (void)setUp {
    roi = CGRectMake((CGFloat)x, (CGFloat)y, 4.f, 4.f);
    
    fhg_preOps_createCGFormat(&cgFormat);
    fhg_preOps_createData(&data, 2, 2, &roi, imgHeight, imgWidth);
    
    fhg_preOps_allocTemp(&temp, &data);
    fhg_preOps_allocBlockBuffer(&blockBuffer, &data);
    
    CFDataRef data1 = CFDataCreate(NULL, originalImage, imgHeight * imgWidth * 4);
    CFDataRef data2 = CFDataCreate(NULL, originalImage2, imgHeight * imgWidth * 4);
    
    CGDataProviderRef dataProvider1 = CGDataProviderCreateWithCFData(data1);
    CGDataProviderRef dataProvider2 = CGDataProviderCreateWithCFData(data2);
    
    cgOriginalImage1  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, cgFormat.colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider1, NULL, NO, kCGRenderingIntentDefault);
    cgOriginalImage2  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth, cgFormat.colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, dataProvider2, NULL, NO, kCGRenderingIntentDefault);
    
    CFRelease(data1);
    CFRelease(data2);
    
    CGDataProviderRelease(dataProvider1);
    CGDataProviderRelease(dataProvider2);
    
    
    printf("bpf = %u\n", data.blocksPerRoi);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    CGImageRelease(cgOriginalImage1);
    CGImageRelease(cgOriginalImage2);
    CGColorSpaceRelease(cgFormat.colorSpace);
}

- (void)testPrintOrigImage {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    printf("\n\\***********************************************\\\n"); // CHECK
    for (size_t i = 0; i < imgHeight; ++i) {
        for (size_t j = 0; j < imgWidth; ++j) {
            printf("%hu,%hu,%hu,%hu  ",
                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 0],
                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 1],
                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 2],
                   (uint16_t)originalImage[i * imgWidth * 4 + j * 4 + 3]);
        }
        
        printf("\n\n");
    }
    printf("\n\\***********************************************\\\n");
    printf("\n\\***********************************************\\\n"); // CHECK
    for (size_t i = 0; i < imgHeight; ++i) {
        for (size_t j = 0; j < imgWidth; ++j) {
            printf("%hu,%hu,%hu,%hu  ",
                   (uint16_t)originalImage2[i * imgWidth * 4 + j * 4 + 0],
                   (uint16_t)originalImage2[i * imgWidth * 4 + j * 4 + 1],
                   (uint16_t)originalImage2[i * imgWidth * 4 + j * 4 + 2],
                   (uint16_t)originalImage2[i * imgWidth * 4 + j * 4 + 3]);
        }
        
        printf("\n\n");
    }
    printf("\n\\***********************************************\\\n");
}

- (void)testGetMemory {
    vImage_Buffer inBuff  = {NULL, 4, 4, 4 * imgWidth};
    vImage_Buffer outBuff = {NULL, 4, 4, 4 * 4};
    
    const int a = (int)vImageScale_ARGB8888(&inBuff, &outBuff, NULL, kvImageGetTempBufferSize);
    printf("memory = %d,   %lu\n", a, (unsigned long)sizeof(NSUInteger));
}

- (void)testPrintCGOrigImage {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    vImage_Buffer inBuff = {
        .data     = temp,
        .height   = CGImageGetHeight(cgOriginalImage1),
        .width    = CGImageGetWidth (cgOriginalImage1),
        .rowBytes = CGImageGetBytesPerRow(cgOriginalImage1),
    };

    const vImage_Error convErr = vImageBuffer_InitWithCGImage(&inBuff, &cgFormat, NULL, cgOriginalImage1, kvImageNoAllocate);
    if (convErr != kvImageNoError) {
        printf("ERROR = %d\n", (int)convErr);
        return;
    }

    const uint8_t *const tmp = (uint8_t *)temp;
    printf("\n\\***********************************************\\\n"); // CHECK
    for (size_t i = 0; i < imgHeight; ++i) {
        for (size_t j = 0; j < imgWidth; ++j) {
            printf("%hu,%hu,%hu,%hu  ",
                   (uint16_t)tmp[i * imgWidth * 4 + j * 4 + 0],
                   (uint16_t)tmp[i * imgWidth * 4 + j * 4 + 1],
                   (uint16_t)tmp[i * imgWidth * 4 + j * 4 + 2],
                   (uint16_t)tmp[i * imgWidth * 4 + j * 4 + 3]);
        }

        printf("\n\n");
    }
    printf("\n\\***********************************************\\\n");
}

- (void)testCrop {

    void *const temp1 = temp  +  data.roi.offsetBytes;             // LEAVE SPACE FOR ONE ROI
    void *const temp2 = temp1 + data.fullFrame.offsetBytes;   // LEAVE SPACE FOR ONE FRAME
    void *const temp3 = temp;
    
    printf("Roi Offset = %lu & %lu\n", data.roi.offsetCount, data.roi.offsetBytes);
    printf("FF  Offset = %lu & %lu\n", data.fullFrame.offsetCount, data.fullFrame.offsetBytes);
    
    imageACroppedToRoi = fhgmCropFrameAndGetRoi(cgOriginalImage1, &cgFormat, &data, temp1, temp2, temp3);

//    printf("\n\\***********************************************\\");
//    for (size_t i = 0; i < data.roi.area; ++i)
//        printf("%s%hu, ", ((i & 3) ? "":"\n"), (uint16_t)((uint8_t *)imageACroppedToRoi.data)[i]);
    printf("\n\\***********************************************\\\n");
    const uint8_t *const data = (uint8_t *)imageACroppedToRoi.data;
    printf("\n\\***********************************************\\\n");
    for (size_t i = 0; i < 4; ++i) {
        for (size_t j = 0; j < 4; ++j) {
            printf("%hu,%hu,%hu,%hu,  ",
                   (uint16_t)data[j * 4 + i * 4 * 4 + 0],
                   (uint16_t)data[j * 4 + i * 4 * 4 + 1],
                   (uint16_t)data[j * 4 + i * 4 * 4 + 2],
                   (uint16_t)data[j * 4 + i * 4 * 4 + 3]);
        }
        printf("\n");
    }
    printf("\n\\***********************************************\\\n");

    const size_t indexA = 4*x + 4*y*imgWidth;
    const size_t indexB = 4*(x+4-1) + 4*(y+4-1)*imgWidth;

    XCTAssertEqual(originalImage[indexA], *data,
                   @"Error, originalImage[%lu] = %hu != data[0] = %hu",
                   indexA, (uint16_t)originalImage[indexA], (uint16_t)(*data));
    XCTAssertEqual(originalImage[indexB], *(data + 15 * 4),
                   @"Error, originalImage[%lu] = %hu != data[%lu] = %hu",
                   indexB, (uint16_t)originalImage[indexB], 15ul*4, (uint16_t)(*(data + 15 * 4)));

}

- (void)testExtractPlane {
    [self testCrop];
    
    void *const temp1 = temp  +  data.roi.offsetBytes;

    imageBPlane = fhgmExtractPlaneNFromRoi(&imageACroppedToRoi, 0, temp1);

    const uint8_t *const pata = (uint8_t *)imageBPlane.data;

    printf("\n\\***********************************************\\");
    for(size_t i = 0; i < 16; ++i)
        printf("%s%hu, ", ((i & 3) ? "":"\n"), (uint16_t)pata[i]);
    printf("\n\\***********************************************\\\n");

    const size_t indexA = 4*x + 4*y*imgWidth;
    const size_t indexB = 4*(x+4-1) + 4*(y+4-1)*imgWidth;

    XCTAssertEqual(originalImage[indexA], *pata,
                   @"Error, originalImage[%lu] = %hu != data[0] = %hu",
                   indexA, (uint16_t)originalImage[indexA], (uint16_t)(*pata));
    XCTAssertEqual(originalImage[indexB], *(pata + 15),
                   @"Error, originalImage[%lu] = %hu != data[%lu] = %hu",
                   indexB, (uint16_t)originalImage[indexB], 15ul, (uint16_t)(*(pata + 15)));
}

- (void)testCreateFloatPlane {
    [self testExtractPlane];
    
    void *const temp2 = temp + data.roi.offsetBytes + data.fullFrame.offsetBytes;   // LEAVE SPACE FOR ONE FRAME
    imageCPlaneInFloats = fhgmConvertPlaneBytesToFloats(&imageBPlane, temp2);

    const uint8_t *const pata = (uint8_t *)imageBPlane.data;
    const float *const fata = (float *)imageCPlaneInFloats.data;

    printf("\n\\***********************************************\\");
    for (size_t i = 0; i < 16; ++i)
        printf("%s%f, ", ((i & 3) ? "":"\n"), (float)fata[i] * 255.);
    printf("\n\\***********************************************\\\n");

    for (size_t i = 0; i < 16; ++i) {
        const float testValue = (float)pata[i] / 255.f;
        XCTAssertLessThan(fabsf(testValue - fata[i]), FLT_EPSILON,
                          "ERROR! %hu / 255 = %f  !=  %f",
                          (uint16_t)pata[i], testValue, fata[i]);
    }
}

- (void)testCreateBlocks {
    [self testCreateFloatPlane];
    fhgmFillBufferWithBlocks(&imageCPlaneInFloats, blockBuffer, &data);
    const float *const bata = (float *)blockBuffer;

    printf("raw ==> %lu & %lu\nfloat ==> %lu & %lu",
           (uintptr_t)blockBuffer, (uintptr_t)(blockBuffer + 1),
           (uintptr_t)bata, (uintptr_t)(bata + 1));

    printf("\n\\***********************************************\\\n");
    for (size_t i = 0; i < data.blocksPerRoi; ++i) {
        const float *const frameStart = bata + i * data.block.area;
        for (size_t j = 0; j < data.block.width; ++j) {
            for (size_t k = 0; k < data.block.width; ++k) {
                printf("%f, ", 255.*frameStart[j * data.block.width + k]);
            }
            printf("\n");
        }
        printf("\n");
    }

    printf("\n\\***********************************************\\");
    for (size_t i = 0; i < 16; ++i)
        printf("%s%f, ", ((i & 3) ? "":"\n"), bata[i]);
    printf("\n\\***********************************************\\\n");

    const float *const fata = (float *)imageCPlaneInFloats.data;
    size_t index = 0;
    for (size_t i = 0; i < data.blocksPerRoi; ++i) {
        const float *const roiStart   = fata + i * data.block.width + (i >= data.block.width) * data.block.area;
        const float *const blockStart = bata + i * data.block.area;


        for (size_t j = 0; j < data.block.width; ++j) {
            for (size_t k = 0; k < data.block.width; ++k) {
                const float orgnlVal = roiStart[j * data.block.area + k];
                const float blockVal = blockStart[j * data.block.width + k];


                XCTAssertLessThan(fabsf(orgnlVal - blockVal), FLT_EPSILON,
                                  "ERROR! @ index %lu out of %lu ==>  %f  !=  %f",
                                  index++, 16ul, orgnlVal, blockVal);
            }
        }
    }
}

- (void)testSingleFirstStep {
    fhg_ops_convertFullFrameToBlocks(cgOriginalImage1, &cgFormat, &data, blockBuffer, temp);
    const float *const bata = (float *)blockBuffer;
    
    long blockValues[16];
    
    size_t index = 0;
    printf("\n\\***********************************************\\\n");
    for (size_t i = 0; i < data.blocksPerRoi; ++i) {
        const float *const frameStart = bata + i * data.block.area;
        for (size_t j = 0; j < data.block.width; ++j) {
            for (size_t k = 0; k < data.block.width; ++k) {
                printf("%f, ", 255.*frameStart[j * data.block.width + k]);
                blockValues[index++] = lroundf(255.*frameStart[j * data.block.width + k]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    printf("\n\\***********************************************\\");
    for (size_t i = 0; i < data.roi.area; ++i)
        printf("%s%f, ", ((i & 3) ? "":"\n"), 255. * bata[i]);
    printf("\n\\***********************************************\\\n");
    
    long orgnlValues[16] = {31, 32, 43, 44, 33, 34, 45, 46, 55, 56, 67, 68, 57, 58, 69, 70, };
    
    for (size_t i = 0; i < data.roi.area; ++i)
        XCTAssertEqual(orgnlValues[i], blockValues[i], @"ERROR, %ld != %ld\n", orgnlValues[i], blockValues[i]);
}

- (void)testMultipleFrames {
    printf("ROI Offset = %lu, %lu\n", data.roi.offsetCount, data.roi.offsetBytes);
    fhg_ops_convertFullFrameToBlocks(cgOriginalImage1, &cgFormat, &data, blockBuffer, temp);
    fhg_ops_convertFullFrameToBlocks(cgOriginalImage2, &cgFormat, &data, blockBuffer + data.roi.offsetBytes, temp);
    const float *const bata = (float *)blockBuffer;
    
    printf("\n\\***********************************************\\\n");
    for (size_t i = 0; i < data.blocksPerRoi; ++i) {
        const float *const frameStart = bata + i * data.block.area;
        for (size_t j = 0; j < data.block.width; ++j) {
            for (size_t k = 0; k < data.block.width; ++k) {
                printf("%f, ", 255.*frameStart[j * data.block.width + k]);
            }
            printf("\n");
        }
        printf("\n");
    }
    
    printf("\n\\***********************************************\\");
    for (size_t i = 0; i < data.roi.area * 2; ++i)
        printf("%s%f, ", ((i & 3) ? "":"\n"), 255. * bata[i]);
    printf("\n\\***********************************************\\\n");
    
    printf("\n\\***********************************************\\");
    for (size_t i = 0; i < 2 * data.roi.area; ++i)
        printf("%s%f, ", ((i & 3) ? "":"\n"), ((float *)blockBuffer)[i] * 255.);
    printf("\n\\***********************************************\\\n");
    printf("\n\\***********************************************\\\n");
    for (size_t i = 0; i < 2; ++i) {
        for (size_t j = 0; j < data.blocksPerRoi; ++j) {
            for (size_t k = 0; k < data.block.area; ++k) {
                const float pix = ((float *)blockBuffer)[i * data.roi.area + j * data.block.area + k];

                printf("%f, ", pix * 255.);
            }
            printf("\n");
        }
        printf("\n");
    }
    printf("\n\\***********************************************\\\n");
    
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

// ImageToBlockConverterOpsDataTests
