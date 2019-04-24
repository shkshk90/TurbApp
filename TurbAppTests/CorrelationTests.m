//
//  CorrelationTests.m
//  TurbAppTests
//
//  Created by Samuel Aysser on 24.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Accelerate/Accelerate.h>
#import "../TurbApp/Models/AllOps.h"
#import "../TurbApp/Models/ModelsResources.h"

#define PXL(N) N,0,1,2

static const size_t imgHeight = 10;
static const size_t imgWidth  = 12;

// SHOULD BE BLUE PIXEL 31
static const size_t x = 4;
static const size_t y = 2;

static const uint8_t originalImage1[imgHeight * imgWidth * 4] = {
    PXL(  3), PXL(  4), PXL(  5), PXL(  6), PXL(  7), PXL(  8), PXL(  9), PXL( 10), PXL( 11), PXL( 12), PXL( 13), PXL( 14),
    PXL( 15), PXL( 16), PXL( 17), PXL( 18), PXL( 19), PXL( 20), PXL( 21), PXL( 22), PXL( 23), PXL( 24), PXL( 25), PXL( 26),
    
    PXL( 27), PXL( 28), PXL( 29), PXL( 30), PXL( 31), PXL( 32), PXL( 33), PXL( 34), PXL( 35), PXL( 36), PXL( 37), PXL( 38),
    PXL( 39), PXL( 40), PXL( 41), PXL( 42), PXL( 43), PXL( 44), PXL( 45), PXL( 46), PXL( 47), PXL( 48), PXL( 49), PXL( 50),
    
    PXL( 51), PXL( 52), PXL( 53), PXL( 54), PXL( 55), PXL( 56), PXL( 57), PXL( 58), PXL( 59), PXL( 60), PXL( 61), PXL( 62),
    PXL( 63), PXL( 64), PXL( 65), PXL( 66), PXL( 67), PXL( 68), PXL( 69), PXL( 70), PXL( 71), PXL( 72), PXL( 73), PXL( 74),
    
    PXL( 75), PXL( 76), PXL( 77), PXL( 78), PXL( 79), PXL( 80), PXL( 81), PXL( 82), PXL( 83), PXL( 84), PXL( 85), PXL( 86),
    PXL( 87), PXL( 88), PXL( 89), PXL( 90), PXL( 91), PXL( 92), PXL( 93), PXL( 94), PXL( 95), PXL( 96), PXL( 97), PXL( 98),
    
    PXL( 99), PXL(100), PXL(101), PXL(102), PXL(103), PXL(104), PXL(105), PXL(106), PXL(107), PXL(108), PXL(109), PXL(110),
    PXL(111), PXL(112), PXL(113), PXL(114), PXL(115), PXL(116), PXL(117), PXL(118), PXL(119), PXL(120), PXL(121), PXL(122),
};

static const uint8_t originalImage2[imgHeight * imgWidth * 4] = {
    PXL(123), PXL(124), PXL(125), PXL(126), PXL(127), PXL(128), PXL(129), PXL(130), PXL(131), PXL(132), PXL(133), PXL(134),
    PXL(135), PXL(136), PXL(137), PXL(138), PXL(139), PXL(140), PXL(141), PXL(142), PXL(143), PXL(144), PXL(145), PXL(146),
    
    PXL(147), PXL(148), PXL(149), PXL(150), PXL(151), PXL(152), PXL(153), PXL(154), PXL(155), PXL(156), PXL(157), PXL(158),
    PXL(159), PXL(160), PXL(161), PXL(162), PXL(163), PXL(164), PXL(165), PXL(166), PXL(167), PXL(168), PXL(169), PXL(170),
    
    PXL(171), PXL(172), PXL(173), PXL(174), PXL(175), PXL(176), PXL(177), PXL(178), PXL(179), PXL(180), PXL(181), PXL(182),
    PXL(183), PXL(184), PXL(185), PXL(186), PXL(187), PXL(188), PXL(189), PXL(190), PXL(191), PXL(192), PXL(193), PXL(194),
    
    PXL(195), PXL(196), PXL(197), PXL(198), PXL(199), PXL(200), PXL(201), PXL(202), PXL(203), PXL(204), PXL(205), PXL(206),
    PXL(207), PXL(208), PXL(209), PXL(210), PXL(211), PXL(212), PXL(213), PXL(214), PXL(215), PXL(216), PXL(217), PXL(218),
    
    PXL(219), PXL(220), PXL(221), PXL(222), PXL(223), PXL(224), PXL(225), PXL(226), PXL(227), PXL(228), PXL(229), PXL(230),
    PXL(231), PXL(232), PXL(233), PXL(234), PXL(235), PXL(236), PXL(237), PXL(238), PXL(239), PXL(240), PXL(241), PXL(242),
};

static const uint8_t originalImage3[imgHeight * imgWidth * 4] = {
    PXL(219), PXL(220), PXL(221), PXL(222), PXL(223), PXL(224), PXL(225), PXL(226), PXL(227), PXL(228), PXL(229), PXL(230),
    PXL(231), PXL(232), PXL(233), PXL(234), PXL(235), PXL(236), PXL(237), PXL(238), PXL(239), PXL(240), PXL(241), PXL(242),
    
    PXL(  3), PXL(  4), PXL(  5), PXL(  6), PXL(  7), PXL(  8), PXL(  9), PXL( 10), PXL( 11), PXL( 12), PXL( 13), PXL( 14),
    PXL( 15), PXL( 16), PXL( 17), PXL( 18), PXL( 19), PXL( 20), PXL( 21), PXL( 22), PXL( 23), PXL( 24), PXL( 25), PXL( 26),
    
    PXL( 27), PXL( 28), PXL( 29), PXL( 30), PXL( 31), PXL( 32), PXL( 33), PXL( 34), PXL( 35), PXL( 36), PXL( 37), PXL( 38),
    PXL( 39), PXL( 40), PXL( 41), PXL( 42), PXL( 43), PXL( 44), PXL( 45), PXL( 46), PXL( 47), PXL( 48), PXL( 49), PXL( 50),
    
    PXL( 51), PXL( 52), PXL( 53), PXL( 54), PXL( 55), PXL( 56), PXL( 57), PXL( 58), PXL( 59), PXL( 60), PXL( 61), PXL( 62),
    PXL( 63), PXL( 64), PXL( 65), PXL( 66), PXL( 67), PXL( 68), PXL( 69), PXL( 70), PXL( 71), PXL( 72), PXL( 73), PXL( 74),
    
    PXL( 75), PXL( 76), PXL( 77), PXL( 78), PXL( 79), PXL( 80), PXL( 81), PXL( 82), PXL( 83), PXL( 84), PXL( 85), PXL( 86),
    PXL( 87), PXL( 88), PXL( 89), PXL( 90), PXL( 91), PXL( 92), PXL( 93), PXL( 94), PXL( 95), PXL( 96), PXL( 97), PXL( 98),
};

#undef PXL

#define CREATE_CG_IMG(IMG_ARR, CG_IMG, CG_FORMAT) do {                              \
    CFDataRef data = CFDataCreate(NULL, IMG_ARR, imgHeight * imgWidth * 4);         \
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(data);          \
    CG_IMG  = CGImageCreate(imgWidth, imgHeight, 8, 4 * 8, 4 * imgWidth,            \
        CG_FORMAT.colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little,      \
        dataProvider, NULL, NO, kCGRenderingIntentDefault);                         \
    CFRelease(data);                                                                \
    CGDataProviderRelease(dataProvider);                                            \
} while (NO)


@interface CorrelationTests : XCTestCase

@end

@implementation CorrelationTests {
    void *temp;
    void *blockBuffer;
    
    CGRect roi;
    vImage_CGImageFormat cgFormat;
    
    CGImageRef cgOriginalImage1;
    CGImageRef cgOriginalImage2;
    CGImageRef cgOriginalImage3;
    
    struct FhgData data;
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    roi = CGRectMake(1., 1., 8., 8.);
    
    fhgPreOpsCreateCGFormat(&cgFormat);
    fhgPreOpsCreateData(&data, 4, 3, &roi, imgHeight, imgWidth);
    
    fhgPreOpsAllocTemp(&temp, &data);
    fhgPreOpsAllocBlockBuffer(&blockBuffer, &data);
    
    
    CREATE_CG_IMG(originalImage1, cgOriginalImage1, cgFormat);
    CREATE_CG_IMG(originalImage2, cgOriginalImage2, cgFormat);
    CREATE_CG_IMG(originalImage3, cgOriginalImage3, cgFormat);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
