//
//  AbsoluteCorrelatorX.m
//  TurbApp
//
//  Created by Samuel Aysser on 26.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

@import AVFoundation;
@import Accelerate;
@import CoreGraphics;

#import "AbsoluteCorrelatorX.h"
#import "ModelsResources.h"
#import "AbsoluteCorrelator_private.h"
#import "GaussianMask.h"
#import "SubpixelCrossCorrelator.h"
#import "../common.h"

// Test new buffers technique
#define NEW_BUFFERS 1
#define NOTIMPLEMENTED 1
#define USE_GAUSSIAN_MASK 0

#pragma mark - Implementation & Private members
@implementation FHGAbsoluteCorrelatorX {
    
    // Experiment-related data
@private CGSize                      _videoSize;
@private CGRect                      _roi;
    
@private NSUInteger                  _upscaleFactor;
@private NSUInteger                  _numberOfSamples;
@private NSUInteger                  _numberOfSamplesPlusRef;
    
@private NSUInteger                  _blockSide;
@private NSUInteger                  _blockArea;
    
@private NSUInteger                  _roiSide;
@private NSUInteger                  _blocksPerROI;
@private NSUInteger                  _blockSidesPerROISide;
    
@private size_t                      _currentFrameIndex;

    
@private float                      *_gaussianMask;
@private float                      *_emptyImagBlock;
@private float                      ***_rawBlocksArray[2];
@private float                      ***_fftBlocksComplexArray[2];
    
@private float                      *_sideKernel;
@private float                      *_sideComplexKernel[2];
@private float                      *_doubleSideKernel;
@private CGPoint                    **_tipTiltPairs;
    
    
    
// vImages
//@private vImage_Buffer               _gaussianMask;
    
    
    // Buffers
//@private FHGMRawBuffer               _tempRawBuffer;                // GENERAL TEMP BUFFER
//@private FHGMRawBuffer               _allBlocksInAllFramesArray;    // ALL BLOCKS IN ALL FRAMES RAW BUFFER
//@private FHGMRawBuffer               _gaussianAllBlocksArray;       // ALL BLOCKS IN ALL FRAMES MUL GAUSSIAN RAW BUFFER
//@private FHGMRawBuffer               _fftComplexRawBuffer;
//@private FHGMRawBuffer               _sideKernel;
//@private FHGMRawBuffer               _sideComplexKernel;
//@private FHGMRawBuffer               _areaKernel;
//@private FHGMRawBuffer               _dftUpscaleTempBuffer;
//@private FHGMRawBuffer               _tipTiltPairsArray;
//
//@private float                      *_emptyBlockArea;
    
    // FFT
@private FFTSetup                    _fftSetup;
    
    
    // Frame retrieval members
@private AVURLAsset                 *_videoURL;
    
@private AVAssetImageGenerator      *_imageGenerator;
@private NSMutableArray             *_allSamplesTimes;
    
    // Dispatch Queues
@private dispatch_queue_t           _serialQueue;
@private dispatch_group_t           _dispatchGroup;    // For Syncing
    
//    // Memory-related variables
//@private BOOL                       _memoryFreed;
//@private BOOL                       _experimentDataIsSet;
//
//
//    // Special variables
//@private FHGMCorrelationBlock       _correlationBlock;
}

#pragma mark - Setup
- (instancetype)init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _allSamplesTimes     = [NSMutableArray arrayWithCapacity:kFHGMaximumCountOfFrames];
    _currentFrameIndex   = 0;
    
    _blockSide           = 32;
    _blockArea           = 32 * 32;
    
    
    _serialQueue     = dispatch_queue_create(SERIAL_QUEUE_LABEL, DISPATCH_QUEUE_SERIAL);
    _dispatchGroup   = dispatch_group_create();
    
    dispatch_async(_serialQueue, ^(void){
        const vDSP_Length len = fhgm_log_two(kAIMMaxBlockArea) + 1 + 2; // FOR COMPLEX AND FOR FTPAD

        self->_fftSetup = vDSP_create_fftsetup(len, kFFTRadix2);

        FHG_NS_ASSERT(self->_fftSetup != 0, @"Error: _fftSetup is NULL", NULL);
    });
    
    
    
//    _gaussianMask    = malloc(kAIMMaxBlockArea * sizeof(float));
//    _emptyImagBlock  = calloc(kAIMMaxBlockArea,  sizeof(float));
//
//    _rawBlocksArray           = malloc(kFHGMaximumCountOfFrames * sizeof(float **));
//
//    _fftBlocksComplexArray[0] = malloc(kFHGMaximumCountOfFrames * sizeof(float **));
//    _fftBlocksComplexArray[1] = malloc(kFHGMaximumCountOfFrames * sizeof(float **));
//
//    _sideKernel               = malloc(kAIMMaxBlockSide * sizeof(float));
//    _sideComplexKernel[0]     = malloc(kAIMMaxBlockSide * sizeof(float));
//    _sideComplexKernel[1]     = malloc(kAIMMaxBlockSide * sizeof(float));
//
//    _doubleSideKernel         = malloc(2 * kAIMMaxBlockSide * sizeof(float));
//
//    _tipTiltPairs             = malloc(kFHGMaximumCountOfFrames * sizeof(CGPoint *));
    
    
    
    return self;
}

- (void)freeMemory {}

#pragma mark - Main Processing Routines
- (void)play
{
    //    [self allocAndCreateGaussianMask];
    //    [self allocAndCreateKernels];
    //    [self allocDFTUpscaleArray];
    //    [self allocTipTiltArray];
    //
    //    [self selectCorrelationFunction];
    
    /********************************* ALLOC MAIN MEMORY ***********************************/
    do {
        _gaussianMask             = fhg_corr_malloc(_blockArea * sizeof(float));
        _emptyImagBlock           = fhg_corr_calloc(_blockArea,  sizeof(float));
        
        _rawBlocksArray[0]        = fhg_corr_malloc(_numberOfSamplesPlusRef * sizeof(float **));
        _rawBlocksArray[1]        = fhg_corr_malloc(_numberOfSamplesPlusRef * sizeof(float **));
        
        _fftBlocksComplexArray[0] = fhg_corr_malloc(_numberOfSamplesPlusRef * sizeof(float **));
        _fftBlocksComplexArray[1] = fhg_corr_malloc(_numberOfSamplesPlusRef * sizeof(float **));
        
        _sideKernel               = fhg_corr_malloc(_blockSide * sizeof(float));
        _sideComplexKernel[0]     = fhg_corr_malloc(_blockSide * sizeof(float));
        _sideComplexKernel[1]     = fhg_corr_malloc(_blockSide * sizeof(float));
        
        _doubleSideKernel         = fhg_corr_malloc(2 * _blockSide * sizeof(float));
        
        _tipTiltPairs             = fhg_corr_malloc(_numberOfSamplesPlusRef * sizeof(CGPoint *));
        
        for (size_t i = 0; i < _numberOfSamplesPlusRef; ++i) {
            _rawBlocksArray[0][i]        = fhg_corr_malloc(_blocksPerROI * sizeof(float *));
            _rawBlocksArray[1][i]        = fhg_corr_malloc(_blocksPerROI * sizeof(float *));
            
            _fftBlocksComplexArray[0][i] = fhg_corr_malloc(_blocksPerROI * sizeof(float *));
            _fftBlocksComplexArray[1][i] = fhg_corr_malloc(_blocksPerROI * sizeof(float *));
            
            _tipTiltPairs[i]              = fhg_corr_malloc(_blocksPerROI * sizeof(CGPoint));
            
            for (size_t j = 0; j < _blocksPerROI; ++j) {
                _rawBlocksArray[0][i][j]        = fhg_corr_malloc(_blockArea * sizeof(float));
                _rawBlocksArray[1][i][j]        = fhg_corr_calloc(_blockArea,  sizeof(float)); // EMPTY COMPLEX
                
                _fftBlocksComplexArray[0][i][j] = fhg_corr_malloc(_blockArea * sizeof(float));
                _fftBlocksComplexArray[1][i][j] = fhg_corr_malloc(_blockArea * sizeof(float));
            }
        }
    } while (NO);
    
    FHG_NS_LOG(@"Play started, creating blocks", NULL);
    
    
    /********************************* REFERENCE DATA *************************************/
    const CMTime referenceTime = [(NSValue *)[_allSamplesTimes objectAtIndex:0] CMTimeValue];
    
    const CGImageRef referenceImage  = [_imageGenerator copyCGImageAtTime:referenceTime actualTime:NULL error:nil];
    vImage_CGImageFormat referenceFormat = {
        .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(referenceImage),
        .bitsPerPixel     = (uint32_t)CGImageGetBitsPerPixel(referenceImage),
        .colorSpace       = CGImageGetColorSpace(referenceImage),
        .bitmapInfo       = CGImageGetBitmapInfo(referenceImage),
        .version          = 0,
        .decode           = CGImageGetDecode(referenceImage),
        .renderingIntent  = CGImageGetRenderingIntent(referenceImage),
    };
    
    CFRetain(referenceFormat.colorSpace);
    
    /**********************  PROC DATA ************************************************/
    const size_t roiSide   = _roiSide;
    const size_t roiArea   = roiSide * roiSide;
    
    const size_t roiOriginX = (size_t)lroundf(_roi.origin.x);
    const size_t roiOriginY = (size_t)lroundf(_roi.origin.y);
    
    const size_t cgRefWidth       = CGImageGetWidth(referenceImage);
    const size_t cgRefHeight      = CGImageGetHeight(referenceImage);
    const size_t cgRefBytesPerRow = CGImageGetBytesPerRow(referenceImage);
    
    const size_t roiPointerOffset = roiOriginY * cgRefBytesPerRow + roiOriginX * sizeof(Pixel_8888);
    
    
    const size_t blockSide = _blockSide;
    const size_t blockArea = _blockArea;
    
    const size_t blockPixelsPerRoiRow = _blockArea * _blockSidesPerROISide;
    
    
    __block vImage_Error err    = kvImageNoError;
    //__block size_t blockCounter = 0;
    
    
    vImage_Buffer roiInFrameTempVImageBuffer = {NULL, roiSide, roiSide, cgRefBytesPerRow};
    vImage_Buffer roiTempVImageBuffer        = {NULL, roiSide, roiSide, roiSide * sizeof(Pixel_8888)};
    

    const vImage_Error scaleTempBufferSize = vImageScale_ARGB8888(&roiInFrameTempVImageBuffer, &roiTempVImageBuffer, NULL, kvImageGetTempBufferSize);
    FHG_NS_ASSERT(scaleTempBufferSize > 0, @"Scale Temp buffer size is not positive, %lu", scaleTempBufferSize);
    

    /**********************  XCORR VARIABLES  ************************************/
    const size_t fftSideLength  = fhgm_log_two(blockSide);
    const size_t upscaleOneHalf = (_upscaleFactor * 15) / 10;       // usfac * 1.5
    const size_t upscaleOneHalfSquared = upscaleOneHalf * upscaleOneHalf;
    
    const float upscaleFacReal  = (float)_upscaleFactor;
    const float dftShift        = (float)(upscaleOneHalf >> 1);    // usfac * 1.5 / 2
    
    const size_t logTwoDoubleBlockSize = fftSideLength + 1;
    const size_t doubleBlockArea       = blockSide * 2 * blockSide * 2;
    
    
    
    /******************* FORWARD FFT **************************/
    const size_t quadrant_side = blockSide / 2;   // divide by 2
    //
    const size_t large_quadrant_side = quadrant_side;
    const size_t small_quadrant_side = quadrant_side;
    
    // (0, 0) ==> (S, S)
    const size_t forwardInputOffset1  = 0;
    const size_t forwardOutputOffset1 = small_quadrant_side * blockSide + small_quadrant_side;
    
    // (L, 0) ==> (0, S)
    const size_t forwardInputOffset2  = large_quadrant_side;
    const size_t forwardOutputOffset2 = small_quadrant_side * blockSide;
    
    // (0, L) ==> (S, 0)
    const size_t forwardInputOffset3  = large_quadrant_side * blockSide;
    const size_t forwardOutputOffset3 = small_quadrant_side;
    
    // (L, L) ==> (0, 0)
    const size_t forwardInputOffset4  = large_quadrant_side * blockSide + large_quadrant_side;
    const size_t forwardOutputOffset4 = 0;
    
    
    const size_t forwardWidth1  = large_quadrant_side;
    const size_t forwardHeight1 = large_quadrant_side;
    
    const size_t forwardWidth2  = small_quadrant_side;
    const size_t forwardHeight2 = large_quadrant_side;
    
    const size_t forwardWidth3  = large_quadrant_side;
    const size_t forwardHeight3 = small_quadrant_side;
    
    const size_t forwardWidth4  = small_quadrant_side;
    const size_t forwardHeight4 = small_quadrant_side;
    
    
    /******************* INVERSE FFT **************************/
    const size_t inverseInputOffset1  = small_quadrant_side * blockSide + small_quadrant_side;
    const size_t inverseOutputOffset1 = 0;
    
    const size_t inverseInputOffset2  = small_quadrant_side * blockSide;
    const size_t inverseOutputOffset2 = large_quadrant_side;
    
    const size_t inverseInputOffset3  = small_quadrant_side;
    const size_t inverseOutputOffset3 = large_quadrant_side * blockSide;
    
    const size_t inverseInputOffset4  = 0;
    const size_t inverseOutputOffset4 = large_quadrant_side * blockSide + large_quadrant_side;
    
    const size_t inverseWidth1  = large_quadrant_side;
    const size_t inverseHeight1 = large_quadrant_side;
    
    const size_t inverseWidth2  = small_quadrant_side;
    const size_t inverseHeight2 = large_quadrant_side;
    
    const size_t inverseWidth3  = large_quadrant_side;
    const size_t inverseHeight3 = small_quadrant_side;
    
    const size_t inverseWidth4  = small_quadrant_side;
    const size_t inverseHeight4 = small_quadrant_side;
    
    float area_scale_r = 4.;
    float area_scale_i = 0.;
    
    float elements_num_real = 1. / (float)doubleBlockArea;
    float elements_num_imag = 0.;
    
    const DSPSplitComplex area_scale = { &area_scale_r, &area_scale_i };
    const DSPSplitComplex scale = { &elements_num_real, &elements_num_imag };
    const DSPSplitComplex complex_kernel = { _sideComplexKernel[0], _sideComplexKernel[1] };
    
    
    
    const size_t out_block_size = blockSide * 2;
    
    const size_t input_center  = (blockSide  / 2) + 1;
    const size_t output_center = (out_block_size / 2) + 1;
    
    const size_t center_diff = output_center - input_center;
    
    const size_t p1      = 0;
    const size_t p2      = center_diff;
    
    const size_t cdpp1   = center_diff + p1;
    const unsigned char flag = (out_block_size >= cdpp1) && ((out_block_size - cdpp1) < blockSide);
    const size_t r1     = (flag != 0) ? out_block_size - cdpp1 : blockSide;
    
    
    float max_val;
    size_t max_index;
    
    
    
    static const float kOne  = 1.;
    
    const size_t output_size = upscaleOneHalf * upscaleOneHalf;
    const size_t kernel_size = upscaleOneHalf * blockSide;
    
    
    
    /**********************  ALLOC TEMP MEMORY  ************************************/
    void *const tempOneAA      = fhg_corr_malloc(sizeof(Pixel_8888) * cgRefWidth * cgRefHeight * 2);
    void *const tempOneAB      = fhg_corr_malloc((size_t)scaleTempBufferSize + 64);
    void *const tempOneA       = fhg_corr_malloc(sizeof(Pixel_8888) * roiSide * roiSide * 2);
    void *const tempOneB       = fhg_corr_malloc(roiSide * roiSide * 2);
    void *const tempOneC       = fhg_corr_malloc(sizeof(float) * roiSide * roiSide * 2);
    
    void *const tempTwoReal    = fhg_corr_malloc(_blockArea * 2 * sizeof(float));
    void *const tempTwoImag    = fhg_corr_malloc(_blockArea * 2 * sizeof(float));
    
    void *const tempThreeRealA = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeRealB = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeRealC = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeRealD = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeRealE = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeRealF = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    
    void *const tempThreeImagA = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeImagB = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeImagC = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeImagD = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeImagE = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    void *const tempThreeImagF = fhg_corr_malloc(sizeof(float) * _blockArea * 8);
    
    
    __block size_t tipTiltCounter = 0;
    
    /**********************  PROCESSING  ************************************/
    dispatch_group_enter(_dispatchGroup);
    [_imageGenerator
        generateCGImagesAsynchronouslyForTimes:_allSamplesTimes
        completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable frameImage,
                            CMTime actualTime,    AVAssetImageGeneratorResult result,
                            NSError * _Nullable error) {
            // IF IMAGE COULDN'T BE RETRIEVED
            if (error || frameImage == NULL)
              FHG_RAISE_EXCEPTION(@"GenerateCGImageException",
                                  @"Image @ time %f couldn't be retrieved.\n%@"
                                  "Image Address  =  %p,  Reason  =  %@\n"
                                  "Error is: %@",
                                  CMTimeGetSeconds(requestedTime),
                                  (frameImage == NULL) ? @"Image is Null\n" : @"",
                                  frameImage,
                                  (result == AVAssetImageGeneratorSucceeded) ? @"Success" :
                                  (result == AVAssetImageGeneratorFailed)    ? @"Failed"  :
                                  @"Cancelled",
                                  error);

            const NSUInteger frameIndex = self->_currentFrameIndex;
            self->_currentFrameIndex += 1;

            CFRetain(frameImage);
            
            dispatch_async(self->_serialQueue, ^(void){
                
                /**********************  STEP 1   ************************************/
                vImage_Buffer frameImageBuf  = { tempOneAA, cgRefHeight, cgRefWidth, cgRefBytesPerRow };
                vImage_Buffer frameRoiSubBuf = { frameImageBuf.data + roiPointerOffset, roiSide, roiSide, frameImageBuf.rowBytes};
                vImage_Buffer roiBGRA        = { tempOneA, roiSide, roiSide, roiSide * sizeof(Pixel_8888)};
                
                vImage_Buffer roiBluePlane   = { tempOneB, roiSide, roiSide, sizeof(Pixel_8) * roiSide };
            
                vImage_Buffer roiImageBuffer = { tempOneC, roiSide, roiSide, sizeof(Pixel_F) * roiSide };
                
                /**********************  STEP 1A  ************************************/
                
                err = vImageBuffer_InitWithCGImage(&frameImageBuf, (vImage_CGImageFormat *)&referenceFormat, NULL, frameImage, kvImageNoAllocate);
                FHG_NS_ASSERT(err == kvImageNoError, @"Error in creating vImage from CGImage =>  %ld", err);
            
                err = vImageScale_ARGB8888(&frameRoiSubBuf, &roiBGRA, tempOneAB, kvImageDoNotTile);
                FHG_NS_ASSERT(err == kvImageNoError, @"Error in cropping vImage  =>  %ld", err);
                
                CFRelease(frameImage);
                /**********************  STEP 1B  ************************************/
            
                err = vImageExtractChannel_ARGB8888(&roiBGRA, &roiBluePlane, 0, kvImageDoNotTile);
                FHG_NS_ASSERT(err == kvImageNoError, @"Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
                /**********************  STEP 1C  ************************************/
                
                err = vImageConvert_Planar8toPlanarF(&roiBluePlane, &roiImageBuffer, 1.f, 0.f, kvImageDoNotTile);
                FHG_NS_ASSERT(err == kvImageNoError, @"Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
                
                /**********************  STEP 1D  ************************************/
                const float *const roiImageBufferData = roiImageBuffer.data;
                float **const rawFrameArray           = self->_rawBlocksArray[0][frameIndex];
                
                size_t blockCounter = 0;
                
                for (size_t i = 0; i < roiArea; i += blockPixelsPerRoiRow) {
                    for (size_t j = 0; j < roiSide; j += blockSide) {
                        const float *blkSrc = roiImageBufferData + i + j;
                        float       *blkDst = rawFrameArray[blockCounter];
                        
                        vDSP_mmov(blkSrc, blkDst, blockSide, blockSide, roiSide, blockSide);
                        
                        ++blockCounter;
                        //printf("%lu/%lu = (%lu, %lu)\n", blockCounter, self->_blocksPerROI, i, j);
                    }
                }
                
                /**********************  STEP 2,3,4 DATA  ************************************/
                float **const realFrameArray = self->_rawBlocksArray[0][frameIndex];
                float **const imagFrameArray = self->_rawBlocksArray[1][frameIndex];
                
                float **const realSmpFftArray   = self->_fftBlocksComplexArray[0][frameIndex];
                float **const imagSmpFftArray   = self->_fftBlocksComplexArray[1][frameIndex];
                
                for (size_t i = 0; i < self->_blocksPerROI; ++i) {
                        
                    /**********************  STEP 2  ************************************/
                    const DSPSplitComplex spatBlock = { realFrameArray[i],  imagFrameArray[i] };
                    const DSPSplitComplex freqBlock = { realSmpFftArray[i], imagSmpFftArray[i] };
                    const DSPSplitComplex tempBlock = { tempTwoReal,        tempTwoImag };
                    
                    vDSP_fft2d_zopt(self->_fftSetup,
                                    &spatBlock,  1, 0, &freqBlock,  1, 0,
                                    &tempBlock, fftSideLength, fftSideLength, kFFTDirection_Forward);
                }
                
                if (frameIndex == 0)
                    return;
            
                float **const realRefFftArray   = self->_fftBlocksComplexArray[0][0];
                float **const imagRefFftArray   = self->_fftBlocksComplexArray[1][0];

                for (size_t i = 0; i < self->_blocksPerROI; ++i) {

                    /**********************  STEP 3  ************************************/
                    /*********  fhgm_spxc_correlate_two_blocks_sub_pixel  ***************/
                    const DSPSplitComplex refBlock = { realRefFftArray[i], imagRefFftArray[i] };
                    const DSPSplitComplex smpBlock = { realSmpFftArray[i], imagSmpFftArray[i] };

                    const DSPSplitComplex tempA = { tempThreeRealA, tempThreeImagA };
                    const DSPSplitComplex tempB = { tempThreeRealB, tempThreeImagB };
                    const DSPSplitComplex tempC = { tempThreeRealC, tempThreeImagC };
                    const DSPSplitComplex tempD = { tempThreeRealD, tempThreeImagD };
                    const DSPSplitComplex tempE = { tempThreeRealE, tempThreeImagE };
                    const DSPSplitComplex tempF = { tempThreeRealF, tempThreeImagF };
                    
                    
                    
                    /**********************  STEP 3.1  ************************************/
                    /*********  fhgm_spxc_correlate_two_blocks_half_pixel  ***************/
                    vDSP_vclr(tempB.realp, 1, doubleBlockArea);
                    vDSP_vclr(tempB.imagp, 1, doubleBlockArea);
                    
                    vDSP_zvmul(&refBlock, 1,  &smpBlock, 1,  &tempA, 1,  blockArea, -1);
                    /**********************  STEP 3.1.1  ************************************/
                    /*********  ft_add_padding           ************************************/
                        /**********************  STEP 3.1.1.1  ************************************/
                        /*********  forward_fft2D_shift        ************************************/
                    vDSP_mmov(tempA.realp + forwardInputOffset1, tempB.realp + forwardOutputOffset1,
                              forwardWidth1, forwardHeight1, blockSide, blockSide);
                    vDSP_mmov(tempA.imagp+ forwardInputOffset1, tempB.imagp + forwardOutputOffset1,
                              forwardWidth1, forwardHeight1, blockSide, blockSide);
                    
                    vDSP_mmov(tempA.realp + forwardInputOffset2, tempB.realp + forwardOutputOffset2,
                              forwardWidth2, forwardHeight2, blockSide, blockSide);
                    vDSP_mmov(tempA.imagp + forwardInputOffset2, tempB.imagp + forwardOutputOffset2,
                              forwardWidth2, forwardHeight2, blockSide, blockSide);
                    
                    vDSP_mmov(tempA.realp + forwardInputOffset3, tempB.realp + forwardOutputOffset3,
                              forwardWidth3, forwardHeight3, blockSide, blockSide);
                    vDSP_mmov(tempA.imagp + forwardInputOffset3, tempB.imagp + forwardOutputOffset3,
                              forwardWidth3, forwardHeight3, blockSide, blockSide);
                    
                    vDSP_mmov(tempA.realp + forwardInputOffset4, tempB.realp + forwardOutputOffset4,
                              forwardWidth4, forwardHeight4, blockSide, blockSide);
                    vDSP_mmov(tempA.imagp + forwardInputOffset4, tempB.imagp + forwardOutputOffset4,
                              forwardWidth4, forwardHeight4, blockSide, blockSide);
                        /*END:   STEP 3.1.1.1         ************************************************/
                        /*END:   forward_fft2D_shift  ************************************************/
                    vDSP_mmov(tempB.realp + p1 * blockSide + p1,  tempC.realp + p2 * blockSide + p2,
                              r1, r1, blockSide, blockSide * 2);
                    vDSP_mmov(tempB.imagp + p1 * blockSide + p1,  tempC.imagp + p2 * out_block_size + p2,
                              r1, r1, blockSide, blockSide * 2);
                    
                        /**********************  STEP 3.1.1.2  ************************************/
                        /*********  inverse_fft2D_shift        ************************************/
                    vDSP_mmov(tempC.realp  + inverseInputOffset1, tempD.realp + inverseOutputOffset1,
                              inverseWidth1, inverseHeight1, blockSide, blockSide);
                    vDSP_mmov(tempC.imagp  + inverseInputOffset1, tempD.imagp + inverseOutputOffset1,
                              inverseWidth1, inverseHeight1, blockSide, blockSide);
                    
                    vDSP_mmov(tempC.realp  + inverseInputOffset2, tempD.realp + inverseOutputOffset2,
                              inverseWidth2, inverseHeight2, blockSide, blockSide);
                    vDSP_mmov(tempC.imagp  + inverseInputOffset2, tempD.imagp + inverseOutputOffset2,
                              inverseWidth2, inverseHeight2, blockSide, blockSide);
                    
                    vDSP_mmov(tempC.realp  + inverseInputOffset3, tempD.realp + inverseOutputOffset3,
                              inverseWidth3, inverseHeight3, blockSide, blockSide);
                    vDSP_mmov(tempC.imagp  + inverseInputOffset3, tempD.imagp + inverseOutputOffset3,
                              inverseWidth3, inverseHeight3, blockSide, blockSide);
                    
                    vDSP_mmov(tempC.realp  + inverseInputOffset4, tempD.realp + inverseOutputOffset4,
                              inverseWidth4, inverseHeight4, blockSide, blockSide);
                    vDSP_mmov(tempC.imagp  + inverseInputOffset4, tempD.imagp + inverseOutputOffset4,
                              inverseWidth4, inverseHeight4, blockSide, blockSide);
                        /*** END:   STEP 3.1.1.2         *********************************************/
                        /*** END:   inverse_fft2D_shift  *********************************************/
                    vDSP_zvzsml(&tempD, 1, &area_scale, &tempE, 1, doubleBlockArea);   // area of output
                    /*END:   STEP 3.1.1      ************************************************/
                    /*END:   ft_add_padding  ************************************************/
                    
                    vDSP_vclr(tempB.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempB.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    vDSP_vclr(tempC.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempC.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    vDSP_vclr(tempD.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempD.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    
                    vDSP_fft2d_zopt(self->_fftSetup, &tempE, 1, 0, &tempF, 1, 0,
                                    &tempB, fftSideLength + 1, fftSideLength + 1, kFFTDirection_Forward);
                    vDSP_zvzsml(&tempF, 1, &scale, &tempC, 1, doubleBlockArea);
                    vDSP_vdist(tempC.realp, 1, tempC.imagp, 1, tempD.realp, 1, doubleBlockArea);
                    vDSP_maxvi(tempD.realp, 1, (float *)&max_val, (size_t *)&max_index, doubleBlockArea);
                    
                    // (1ul << (logTwoDoubleBlockSize << 1))
                    const size_t max_y_row_index = max_index >> logTwoDoubleBlockSize;
                    const size_t max_x_col_index = max_index & ((1ul << (logTwoDoubleBlockSize << 1)) - 1);
                    
                    const float y_row_shift = self->_doubleSideKernel[max_y_row_index] / 2.;
                    const float x_col_shift = self->_doubleSideKernel[max_x_col_index] / 2.;
                    
                    const CGPoint firstXcorr2 = CGPointMake(x_col_shift, y_row_shift);
                    /*END:   STEP 3.1                                   ***************/
                    /*END:   fhgm_spxc_correlate_two_blocks_half_pixel  ***************/
                    
                    
                    
                    vDSP_vclr(tempB.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempB.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    vDSP_vclr(tempC.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempC.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    vDSP_vclr(tempD.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempD.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    vDSP_vclr(tempE.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempE.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    vDSP_vclr(tempF.realp, 1, 2 * blockArea + doubleBlockArea);
                    vDSP_vclr(tempF.imagp, 1, 2 * blockArea + doubleBlockArea);
                    
                    
                    
                    /**********************  STEP 3.2  ************************************/
                    const float row_shift_scaled = roundf(firstXcorr2.y * upscaleFacReal) / upscaleFacReal;
                    const float col_shift_scaled = roundf(firstXcorr2.x * upscaleFacReal) / upscaleFacReal;
                    
                    const float dft_shift_row = dftShift - row_shift_scaled * upscaleFacReal;
                    const float dft_shift_col = dftShift - col_shift_scaled * upscaleFacReal;
                    
                    vDSP_zvmul(&refBlock, 1,  &smpBlock, 1,  &tempA, 1,  blockArea, -1); // Maybe reuse tempA ???
                    
                    
                    /******************************* UPSCALE ********************************/
                    const float row_start = 0. - dft_shift_row;
                    const float col_start = 0. - dft_shift_col;
                    
                    
                    vDSP_vramp(&col_start, &kOne, tempB.realp, 1, upscaleOneHalf);
                    vDSP_vramp(&row_start, &kOne, tempD.realp, 1, upscaleOneHalf);
                    
                    
                    const int iKernelSize = (int)kernel_size;
                    
                    //  e^(x+iy) = e^x * e^iy = e^x * (cos(y) + isin(y))
                    /******** COLS *********/
                    vDSP_zmmul(&complex_kernel, 1, &tempB, 1, &tempC, 1, blockSide, upscaleOneHalf, 1);
                    
                    vvexpf(tempF.realp, tempC.realp, &iKernelSize);
                    vvcosf(tempF.imagp, tempC.imagp, &iKernelSize);
                    
                    vDSP_vmul(tempF.realp, 1, tempF.imagp, 1, tempC.realp, 1, kernel_size);
                    vvsinf(tempF.imagp, tempC.imagp, &iKernelSize);
                    
                    vDSP_vmul(tempF.realp, 1, tempF.imagp, 1, tempC.imagp, 1, kernel_size);
                    
                    /******** ROWS *********/
                    vDSP_zmmul(&tempD, 1, &complex_kernel, 1, &tempE, 1, upscaleOneHalf, blockSide, 1);
                    
                    vvexpf(tempF.realp, tempE.realp, &iKernelSize);
                    vvcosf(tempF.imagp, tempE.imagp, &iKernelSize);
                    
                    vDSP_vmul(tempF.realp, 1, tempF.imagp, 1, tempE.realp, 1, kernel_size);
                    vvsinf(tempF.imagp, tempE.imagp, &iKernelSize);
                    
                    vDSP_vmul(tempF.realp, 1, tempF.imagp, 1, tempE.imagp, 1, kernel_size);
                    
                    
                    /******** Final Mul ********/
                    vDSP_zmmul(&tempA, 1, &tempC, 1, &tempF, 1, blockSide,      upscaleOneHalf, blockSide);
                    vDSP_zmmul(&tempE, 1, &tempF, 1, &tempA, 1, upscaleOneHalf, upscaleOneHalf, blockSide);
                    
                    vDSP_vdist(tempA.realp, 1, tempA.imagp, 1, tempB.realp, 1, upscaleOneHalfSquared);
                    vDSP_maxvi(tempB.realp, 1, (float *)&max_val, (size_t *)&max_index, upscaleOneHalfSquared);
                    
                    const float max_y_row_index_2 = (float)(max_index / upscaleOneHalf);
                    const float max_x_col_index_2 = (float)(max_index % upscaleOneHalf);
                    
                    const float y_row_shift_2 = row_shift_scaled + ((max_y_row_index_2 - dftShift) / upscaleFacReal);
                    const float x_col_shift_2 = col_shift_scaled + ((max_x_col_index_2 - dftShift) / upscaleFacReal);
                    
                    const CGPoint result  = CGPointMake(x_col_shift_2, y_row_shift_2);
                    /********************************************************************************************************/
                    /********************************************************************************************************/
                    /********************************************************************************************************/
                    /********************************************************************************************************/
                    /********************************************************************************************************/
                    /********************************************************************************************************/
                    /********************************************************************************************************/
                    [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:tipTiltCounter];

                    printf("{%f, %f} ", result.x, result.y);
                    ++tipTiltCounter;
                }
                
                if (frameIndex >= self->_numberOfSamples)
                    dispatch_group_leave(self->_dispatchGroup);
          });
    }];
    
    /********************************* ENDED ***********************************/
     dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
//    [self test]; WORKING TILL HERE
    FHG_NS_LOG(@"Done processing", NULL);
    
    /********************************* FREE MAIN MEMORY ***********************************/
    do {
        for (size_t i = 0; i < _numberOfSamplesPlusRef; ++i) {
            for (size_t j = 0; j < _blocksPerROI; ++j) {
                free(_rawBlocksArray[0][i][j]);
                free(_rawBlocksArray[1][i][j]);
                
                free(_fftBlocksComplexArray[0][i][j]);
                free(_fftBlocksComplexArray[1][i][j]);
            }
            
            free(_rawBlocksArray[0][i]);
            free(_rawBlocksArray[1][i]);
            
            free(_fftBlocksComplexArray[0][i]);
            free(_fftBlocksComplexArray[1][i]);
            
            //free(_tipTiltPair[i]);
        }
        
        free(_gaussianMask);
        free(_emptyImagBlock);
        
        free(_rawBlocksArray[0]);
        free(_rawBlocksArray[1]);
        
        free(_fftBlocksComplexArray[0]);
        free(_fftBlocksComplexArray[1]);
        
        free(_sideKernel);
        free(_sideComplexKernel[0]);
        free(_sideComplexKernel[1]);
        
        free(_doubleSideKernel);
        
    //    free(_tipTiltPairs);
    } while (NO);
    
    /********************************* FREE TEMP MEMORY ***********************************/
    do {
        free(tempOneAA);
        free(tempOneAB);
        free(tempOneA);
        free(tempOneB);
        free(tempOneC);
        
        free(tempTwoReal);
        free(tempTwoImag);
        
        free(tempThreeRealA);
        free(tempThreeRealB);
        free(tempThreeRealC);
        
        free(tempThreeImagA);
        free(tempThreeImagB);
        free(tempThreeImagC);
    } while (NO);
    
    
    
    
    
    
    //FHG_NS_LOG(@"Format info: bpC = %d, bpP = %d, CS = %@", format.bitsPerComponent, format.bitsPerPixel, CGColorSpaceCopyName(format.colorSpace));
    
    
//    /**********************  STEP 1  ************************************/
//    /**********************  STEP 1A  ************************************/
//    vImage_Buffer inBuff = { tempOne1AA, CGImageGetHeight(referenceImage), CGImageGetWidth(referenceImage), cgBytesPerRow, };
//
//    err = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)&referenceFormat, NULL, referenceImage, kvImageNoAllocate);
//    NSAssert1(err == kvImageNoError, @"Error in creating vImage from CGImage =>  %ld", err);
//
//    vImage_Buffer roiBuff = {inBuff.data + startpos, height, width, inBuff.rowBytes };
//    vImage_Buffer croppedBufferBGRA = { tempOne1A, height, width, kSizeOfPixel8888 * width };
//
//    err = vImageScale_ARGB8888(&roiBuff, &croppedBufferBGRA, tempOne1AB, kvImageDoNotTile);
//    NSAssert1(err == kvImageNoError, @"Error in cropping vImage  =>  %ld", err);
//
//    /**********************  STEP 1B  ************************************/
//    vImage_Buffer croppedBufferROI = { tempOne1B, height, width, width };
//
//    err = vImageExtractChannel_ARGB8888(&croppedBufferBGRA, &croppedBufferROI, 0, kvImageNoFlags);
//    NSAssert1(err == kvImageNoError, @"Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
//
//    /**********************  STEP 1C  ************************************/
//    vImage_Buffer referenceRoi = { tempOne1C, height, width, sizeof(Pixel_F) * width };
//
//    err = vImageConvert_Planar8toPlanarF(&croppedBufferROI, &referenceRoi, 1.f, 0.f, kvImageNoFlags);
//    NSAssert1(err == kvImageNoError, @"Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
//
//    /**********************  STEP 1C  ************************************/
//    const float *const firstPixelInRoi = (float *)referenceRoi.data;
//    float *const frameBlockBuffer      = (float *)_allBlocksInAllFramesArray.buf;
//
//    size_t counter = 0;
//
//    for (size_t i = 0; i < self->_blockSidesPerROISide; ++i) {
//
//        const size_t iWidth = i * width;
//        const size_t iCount = i * self->_blockSidesPerROISide;
//
//        for (size_t j = 0; j < self->_blockSidesPerROISide; ++j) {
//            const size_t srcIndex = ( iWidth + j) * self->_blockSide;
//            const size_t dstIndex = ( iCount + j) * self->_blockArea;
//
//            const float *firstPixelInBlock = firstPixelInRoi  + srcIndex;
//            float       *rawBlock          = frameBlockBuffer + dstIndex;
//
//            vDSP_mmov(firstPixelInBlock, rawBlock, _blockSide, _blockSide, width, _blockSide);
//
//            /**********************  STEP 2  ************************************/
//            const vDSP_Length fftSideLength = fhgm_log_two(self->_blockSide);
//
//            refFftBlocksReal[counter] = malloc(_blockArea * kSizeOfFloat);
//            refFftBlocksImag[counter] = malloc(_blockArea * kSizeOfFloat);
//
//            const DSPSplitComplex ordBlock = { rawBlock,       tempTwoOrdImag };
//            const DSPSplitComplex fftBlock = { refFftBlocksReal[counter] , refFftBlocksImag[counter] };
//            const DSPSplitComplex tmpBlock = { tempTwoTmpReal, tempTwoTmpImag };
//
//            vDSP_fft2d_zopt(self->_fftSetup,
//                            &ordBlock,  1, 0, &fftBlock,  1, 0,
//                            &tmpBlock, fftSideLength, fftSideLength, kFFTDirection_Forward);
//
//            ++counter;
//        }
//    }
//
//    [self createFFTComplexAt:0];
    
    
//    __block size_t ttCounter = 0;
    
    
    //CGImageRef *const cgArray = (CGImageRef *)_cgImagesArray.buf;
//    dispatch_group_enter(_dispatchGroup);
    
//    [_imageGenerator generateCGImagesAsynchronouslyForTimes:_allSamplesTimes
//                                          completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image,
//                                                              CMTime actualTime,    AVAssetImageGeneratorResult result,
//                                                              NSError * _Nullable error) {
//                                              // IF IMAGE COULDN'T BE RETRIEVED
//                                              if (error || image == NULL)
//                                                  FHG_RAISE_EXCEPTION(@"GenerateCGImageException",
//                                                                      @"Image @ time %f couldn't be retrieved.\n%@"
//                                                                      "Image Address  =  %p,  Reason  =  %@\n"
//                                                                      "Error is: %@",
//                                                                      CMTimeGetSeconds(requestedTime),
//                                                                      (image == NULL) ? @"Image is Null\n" : @"",
//                                                                      image,
//                                                                      (result == AVAssetImageGeneratorSucceeded) ? @"Success" :
//                                                                      (result == AVAssetImageGeneratorFailed)    ? @"Failed"  :
//                                                                      @"Cancelled",
//                                                                      error);
//
//                                              const NSUInteger index = self->_currentFrameIndex;
//                                              self->_currentFrameIndex += 1;
//
//                                              if (index == 0)
//                                                  return;
//
//                                              CFRetain(image);
//
//
//                                              dispatch_async(self->_serialQueue, ^(void){
//
//                                                  /**********************  STEP 1  ************************************/
//                                                  float *const frameBlockBuffer = (float *)(self->_allBlocksInAllFramesArray.buf + index * frameStride);
//                                                  vImage_Error err;
//
//
//                                                  /**********************  STEP 1A  ************************************/
//                                                  vImage_Buffer inBuff = { tempOne1AA, CGImageGetHeight(image), CGImageGetWidth(image), cgBytesPerRow, };
//
//                                                  err = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)&referenceFormat, NULL, image, kvImageNoAllocate);
//                                                  NSAssert1(err == kvImageNoError, @"Error in creating vImage from CGImage =>  %ld", err);
//
//                                                  vImage_Buffer roiBuff = { inBuff.data + startpos, height, width, inBuff.rowBytes,};
//                                                  vImage_Buffer croppedBufferBGRA = { tempOne1A, height, width, kSizeOfPixel8888 * width };
//
//                                                  err = vImageScale_ARGB8888(&roiBuff, &croppedBufferBGRA, tempOne1AB, kvImageDoNotTile);
//                                                  NSAssert1(err == kvImageNoError, @"Error in cropping vImage  =>  %ld", err);
//                                                  CFRelease(image);
//
//                                                  /**********************  STEP 1B  ************************************/
//                                                  vImage_Buffer croppedBufferROI = { tempOne1B, height, width, sizeof(Pixel_8) * width };
//
//                                                  err = vImageExtractChannel_ARGB8888(&croppedBufferBGRA, &croppedBufferROI, 0, kvImageNoFlags);
//                                                  NSAssert1(err == kvImageNoError, @"Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
//
//                                                  /**********************  STEP 1C  ************************************/
//                                                  vImage_Buffer sampleRoiBuffer = { tempOne1C, height, width, sizeof(Pixel_F) * width };
//
//                                                  err = vImageConvert_Planar8toPlanarF(&croppedBufferROI, &sampleRoiBuffer, 1.f, 0.f, kvImageNoFlags);
//                                                  NSAssert1(err == kvImageNoError, @"Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
//
//                                                  /**********************  STEP 1D  ************************************/
//                                                  const float *const firstPixelInRoi = (float *)sampleRoiBuffer.data;
//
//                                                  size_t blockCounter = 0;
//
//                                                  printf("%lu == > A:  \n", index);
//                                                  for (size_t i = 0; i < self->_blockSidesPerROISide; ++i) {
//
//                                                      const size_t iWidth = i * width;
//                                                      const size_t iCount = i * self->_blockSidesPerROISide;
//
//                                                      for (size_t j = 0; j < self->_blockSidesPerROISide; ++j) {
//                                                          const size_t srcIndex = ( iWidth + j) * self->_blockSide;
//                                                          const size_t dstIndex = ( iCount + j) * self->_blockArea;
//
//                                                          const float *firstPixelInBlock = firstPixelInRoi  + srcIndex;
//                                                          float       *rawBlock          = frameBlockBuffer + dstIndex;
//
//                                                          vDSP_mmov(firstPixelInBlock, rawBlock,
//                                                                    self->_blockSide, self->_blockSide, width, self->_blockSide);
//
//                                                          /**********************  STEP 2  ************************************/
//                                                          const vDSP_Length fftSideLength = fhgm_log_two(self->_blockSide);
//
//                                                          const DSPSplitComplex ordBlock = { rawBlock,       tempTwoOrdImag };
//                                                          const DSPSplitComplex fftBlock = { tempTwoFftReal, tempTwoFftImag };
//                                                          const DSPSplitComplex tmpBlock = { tempTwoTmpReal, tempTwoTmpImag };
//
//                                                          vDSP_fft2d_zopt(self->_fftSetup,
//                                                                          &ordBlock,  1, 0, &fftBlock,  1, 0,
//                                                                          &tmpBlock, fftSideLength, fftSideLength, kFFTDirection_Forward);
//
//                                                          /**********************  STEP 3  ************************************/
//                                                          const DSPSplitComplex refBlock = { refFftBlocksReal[blockCounter], refFftBlocksImag[blockCounter] };
//                                                          const DSPSplitComplex smpBlock = fftBlock;
//
//                                                          const DSPSplitComplex tempA = { tempThreeRealA, tempThreeImagA };
//                                                          const DSPSplitComplex tempB = { tempThreeRealB, tempThreeImagB };
//                                                          const DSPSplitComplex tempC = { tempThreeRealC, tempThreeImagC };
//
//                                                          const CGPoint result =
//                                                          fhgm_spxc_correlate_two_blocks_sub_pixel(&refBlock, &smpBlock, &tempA,
//                                                                                                   self->_areaKernel.buf, &tempB,
//                                                                                                   fftSideLength, self->_fftSetup,
//                                                                                                   self->_upscaleFactor, &tempC);
//
//                                                          [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:ttCounter];
//
//                                                          printf("{%f, %f} ", result.x, result.y);
//                                                          ++ttCounter;
//                                                          ++blockCounter;
//
//                                                      }
//                                                  }
//
//
//                                                  /**********************  STEP OLD  ************************************/
//                                                  [self createFFTComplexAt:index];
//                                                  [self processFrameAtIndex:index];
//
//                                                  printf("B\n");
//
//
//                                                  /**********************  GENERIC_STEP  ************************************/
//                                                  if (index == self->_numRefAndSamples - 1)
//                                                      dispatch_group_leave(self->_dispatchGroup);
//                                              });
//                                          }];
    
//    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
//
//    CFRelease(referenceImage);
//    CFRelease(referenceFormat.colorSpace);
//
//    FHG_NS_LOG(@"Blocks are ready", NULL);
//
//    size_t i = 0;
//    for (NSValue *val in _tipTiltValues) {
//        CGPoint pt = *(CGPoint *)(_tipTiltPairsArray.buf + i * sizeof(CGPoint));
//        printf("%f, %f  ==  %f, %f\n", [val CGPointValue].x, [val CGPointValue].y, pt.x, pt.y);
//        ++i;
//    }
    //    NSLog(@"%@", _tipTiltValues);
    
    //[self startProcessing];
    
    // ONLY FOR DEBUGGING
    
}

- (void) test
{
    NSMutableArray *const stacks = [[NSMutableArray alloc] initWithCapacity:100];
    UIStackView *const debugStackView = (UIStackView *)[_delegate debugView];

    const vImage_CGImageFormat format = {
        .bitsPerComponent = 8, .bitsPerPixel = 8,
        .colorSpace = CGColorSpaceCreateDeviceGray(), //CGColorSpaceCreateDeviceGray(),
        .bitmapInfo = (CGBitmapInfo)kCGImageByteOrderDefault, //kCGImageAlphaFirst | kCGBitmapByteOrder32Little, kCGBitmapFloatComponents
        .version = 0, .decode = nil, .renderingIntent = kCGRenderingIntentDefault
    };
    vImage_Error err;
    vImage_Buffer rawImage  = {NULL, _blockSide, _blockSide, _blockSide * sizeof(Pixel_F)};
    
    float **const blockPtr1  = _rawBlocksArray[0][0];
    float **const blockPtr2  = _rawBlocksArray[0][1];
    
    float **blockPtr = blockPtr1;
    
    printf("==> bs = %lu, BA = %lu\n", _blockSidesPerROISide, _blocksPerROI);
    
    size_t counter = 0;
    size_t i = 0;
    while (i++ < _blockSidesPerROISide) {
        UIStackView *const test = [[UIStackView alloc] init];
        [test setDistribution:UIStackViewDistributionFillEqually];
        [test setSpacing:1.];
        
        for (size_t j = 0; j < _blockSidesPerROISide; ++j) {
            const float *const ptr = blockPtr[counter++];
            rawImage.data = (void *)ptr;
            vImage_Buffer sample = { malloc(rawImage.height * rawImage.width * sizeof(Pixel_8)),
                rawImage.height, rawImage.width, rawImage.width * sizeof(Pixel_8)};
            
            err = vImageConvert_PlanarFtoPlanar8(&rawImage, &sample, 1.f, 0.f, kvImageDoNotTile);
            FHG_NS_ASSERT(err == kvImageNoError, @"Error in converting vImage from Planar8 to PlanarF  =>  %ld", err);
            
            CGImageRef cgImg = vImageCreateCGImageFromBuffer(&sample, &format, nil, nil, kvImageDoNotTile, &err);
            if (err != kvImageNoError) FHG_RAISE_EXCEPTION(@"vImageErr", @"Error = %d", (int)err);
            
            UIImageView *mainImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:cgImg]];
            [test addArrangedSubview:mainImageView];
            
            free(sample.data);
            CFRelease(cgImg);
        }
        
        [stacks addObject:test];
        
        if ((counter >= _blocksPerROI) && (blockPtr == blockPtr1)) {
            i = 0;
            blockPtr = blockPtr2;
            counter = 0;
        }
    }

    [debugStackView setSpacing:10.];
    for (UIStackView *const stack in stacks)
        [debugStackView addArrangedSubview:stack];
}


//- (void)startProcessing
//{
//    const size_t blockIncrement = _fftComplexRawBuffer.size2D;
//    const size_t frameIncrement = _fftComplexRawBuffer.size3D;
//
//    void  *const tipTiltPtr     = _tipTiltPairsArray.buf;
//    const size_t tipTiltInc     = _tipTiltPairsArray.size2D;
//    const size_t arrayIncrement = _tipTiltPairsArray.size2D / _tipTiltPairsArray.size1D;
//
//    void  *const fftRawRealPtr  = _fftComplexRawBuffer.buf;
//    void  *const fftRawImagPtr  = _fftComplexRawBuffer.buf + _fftComplexRawBuffer.size4D;
//
//    dispatch_group_enter(_dispatchGroup);
//    // WE USE SERIAL QUEUES BECAUSE WE MAKE USE OF THE TEMP BUFFERS
//    dispatch_apply(_numberOfSamples, _serialQueue, ^(size_t i) {
//
//        dispatch_group_enter(self->_dispatchGroup);
//
//        const size_t sampleIndex = i + 1;
//
//        void *const  sampleFFTRealPtr = fftRawRealPtr + sampleIndex * frameIncrement;
//        void *const  sampleFFTImagPtr = fftRawImagPtr + sampleIndex * frameIncrement;
//
//
//        // TipTilt has no reference, and no block inc.
//        CGPoint *const tipTiltsInSample = (CGPoint *)(tipTiltPtr + i * tipTiltInc);
//
//        // Process all blocks in frame i
//        for (size_t j = 0; j < self->_blocksPerROI; ++j) {
//
//            const DSPSplitComplex refBlock = {
//                .realp = (float *)(fftRawRealPtr + j * blockIncrement),
//                .imagp = (float *)(fftRawImagPtr + j * blockIncrement),
//            };
//
//            const DSPSplitComplex smpBlock = {
//                .realp = (float *)(sampleFFTRealPtr + j * blockIncrement),
//                .imagp = (float *)(sampleFFTImagPtr + j * blockIncrement),
//            };
//
//            const CGPoint result = self->_correlationBlock(&refBlock, &smpBlock);
//
//            tipTiltsInSample[j]  = result;
//            [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:(i * arrayIncrement + j)];
//        }
//
//        dispatch_group_leave(self->_dispatchGroup);
//        if (self->_numberOfSamples - i == 1)
//            dispatch_group_leave(self->_dispatchGroup);
//    });
//
//    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
//
//    FHG_NS_LOG(@"Tip Tilt Pairs are ready, ", NULL);
//    FHG_NS_LOG(@"TipTiltPairs: %@", _tipTiltValues);
//
//    //    for (size_t i = 0; i < _blocksPerROI * _numberOfSamples; ++i) {
//    //        printf("(%f, %f)\n", ((CGPoint *)(_tipTiltPairsArray.buf))[i].x,  ((CGPoint *)(_tipTiltPairsArray.buf))[i].y);
//    //    }
//}

//- (void)createBlocksFrom:(const CGImageRef)image at:(const NSUInteger)index with:(const vImage_CGImageFormat *const)format
//{
//    const size_t frameStride      = _allBlocksInAllFramesArray.size3D;
//    float *const frameBlockBuffer = (float *)(_allBlocksInAllFramesArray.buf + index * frameStride);
//
//    create_raw_blocks_from_cg_image(image,
//                                    format,
//                                    frameBlockBuffer,
//                                    _blockSide,
//                                    _blockSidesPerROISide,
//                                    _roi,
//                                    &_tempRawBuffer);
//
//    CFRelease(image);
//}
//
//- (void)createGaussianFrameAt:(const NSUInteger)index
//{
//#if USE_GAUSSIAN_MASK == 1
//    const size_t frameStride = _allBlocksInAllFramesArray.size3D;
//    const size_t blockStride = _allBlocksInAllFramesArray.size2D;
//
//    for (size_t j = 0; j < _blocksPerROI; ++j) {
//        const vImage_Buffer block = {
//            .data     = _allBlocksInAllFramesArray.buf + index * frameStride + j * blockStride,
//            .width    = _blockSide,
//            .height   = _blockSide,
//            .rowBytes = _blockSide * sizeof(Pixel_F),
//        };
//
//        float *const gaussianBlock = (float *)(_gaussianAllBlocksArray.buf + index * frameStride + j * blockStride);
//
//        fhgm_gm_multiply_block_by_gaussian_fill(&block, &_gaussianMask, _blockSide, gaussianBlock);
//    }
//#endif
//}
//
//- (void)createFFTComplexAt:(const NSUInteger)index
//{
//    const size_t blockIncrement     = _allBlocksInAllFramesArray.size2D;
//    const size_t frameIncrement     = _allBlocksInAllFramesArray.size3D;
//
//    const vDSP_Length fftSideLength = fhgm_log_two(_blockSide);
//
//    void  *const inputPtr        = (USE_GAUSSIAN_MASK == 1) ? _gaussianAllBlocksArray.buf : _allBlocksInAllFramesArray.buf;
//    void  *const complexRealPtr  = _fftComplexRawBuffer.buf;
//    void  *const complexImagPtr  = _fftComplexRawBuffer.buf + _fftComplexRawBuffer.size4D;
//
//    const DSPSplitComplex tempComplex = {
//        .realp = (float *)(_tempRawBuffer.buf),
//        .imagp = (float *)(_tempRawBuffer.buf + _tempRawBuffer.size2D),
//    };
//
//    // Pointer to start of Frame index
//    void *const inputRefFramePtr   = inputPtr       + index * frameIncrement;
//    void *const refFftRealFramePtr = complexRealPtr + index * frameIncrement;
//    void *const refFftImagFramePtr = complexImagPtr + index * frameIncrement;
//
//
//    // Process all blocks in frame index
//    for (size_t j = 0; j < _blocksPerROI; ++j) {
//        // Pointer to start of Block j of Frame 0
//        void *const inputRefBlockPtr   = inputRefFramePtr   + j * blockIncrement;
//        void *const refFftRealBlockPtr = refFftRealFramePtr + j * blockIncrement;
//        void *const refFftImagBlockPtr = refFftImagFramePtr + j * blockIncrement;
//
//        const DSPSplitComplex refGausBlock = {
//            .realp = (float *)inputRefBlockPtr,
//            .imagp = _emptyBlockArea,
//        };
//
//        const DSPSplitComplex refFftBlock = {
//            .realp = (float *)refFftRealBlockPtr,
//            .imagp = (float *)refFftImagBlockPtr,
//        };
//
//        vDSP_fft2d_zopt(_fftSetup,
//                        &refGausBlock, 1, 0,
//                        &refFftBlock,  1, 0,
//                        &tempComplex,
//                        fftSideLength, fftSideLength,
//                        kFFTDirection_Forward);
//
////        NSLog(@"\n(%lu, %lu):  %lu, %lu  -  %lu, %lu",
////              index, j,
////              (uintptr_t)refGausBlock.realp, (uintptr_t)refGausBlock.imagp,
////              (uintptr_t)refFftBlock.realp, (uintptr_t)refFftBlock.imagp);
//    }
//
//}
//
//- (void)processFrameAtIndex:(const NSUInteger)index
//{
//    if (index == 0)
//        return;
//
//    const size_t blockIncrement = _fftComplexRawBuffer.size2D;
//    const size_t frameIncrement = _fftComplexRawBuffer.size3D;
//
//
//    void  *const tipTiltPtr     = _tipTiltPairsArray.buf;
//    const size_t tipTiltInc     = _tipTiltPairsArray.size2D;
//    const size_t arrayIncrement = _tipTiltPairsArray.size2D / _tipTiltPairsArray.size1D;
//
//    void *const fftRawRealPtr = _fftComplexRawBuffer.buf;
//    void *const fftRawImagPtr = _fftComplexRawBuffer.buf + _fftComplexRawBuffer.size4D;
//
//
//    const size_t i = index - 1;
//    const size_t sampleIndex = index;
//
//    void *const  sampleFFTRealPtr = fftRawRealPtr + sampleIndex * frameIncrement;
//    void *const  sampleFFTImagPtr = fftRawImagPtr + sampleIndex * frameIncrement;
//
//
//    // TipTilt has no reference, and no block inc.
//    CGPoint *const tipTiltsInSample = (CGPoint *)(tipTiltPtr + i * tipTiltInc);
//
//    // Process all blocks in frame i
//    for (size_t j = 0; j < self->_blocksPerROI; ++j) {
//
//        const DSPSplitComplex refBlock = {
//            .realp = (float *)(fftRawRealPtr + j * blockIncrement),
//            .imagp = (float *)(fftRawImagPtr + j * blockIncrement),
//        };
//
//        const DSPSplitComplex smpBlock = {
//            .realp = (float *)(sampleFFTRealPtr + j * blockIncrement),
//            .imagp = (float *)(sampleFFTImagPtr + j * blockIncrement),
//        };
//
//        const CGPoint result = self->_correlationBlock(&refBlock, &smpBlock);
//
//        tipTiltsInSample[j]  = result;
//        printf("(%f,%f) \n", result.x, result.y);
////        [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:(i * arrayIncrement + j)];
//
////        NSLog(@"\n(%lu, %lu):  %lu, %lu  -  %lu, %lu",
////              i, j,
////              (uintptr_t)refBlock.realp, (uintptr_t)refBlock.imagp,
////              (uintptr_t)smpBlock.realp, (uintptr_t)smpBlock.imagp);
//    }
//
//    if (index < _numberOfSamples)
//        return;
//
////    FHG_NS_LOG(@"Tip Tilt Pairs are ready, ", NULL);
////    FHG_NS_LOG(@"TipTiltPairs: %@", _tipTiltValues);
////
////    for (size_t i = 0; i < _blocksPerROI * _numberOfSamples; ++i) {
////        printf("(%f, %f)\n", ((CGPoint *)(_tipTiltPairsArray.buf))[i].x,  ((CGPoint *)(_tipTiltPairsArray.buf))[i].y);
////    }
//}
//
//- (void)playOld
//{
//    // WAIT FOR ALLOCATIONS AND CONFIRM THAT ALL ALLOCATIONS ARE DONE
//    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
//
//    FHG_NS_ASSERT(_tempRawBuffer.buf             != NULL, "Temp is not allocated",           NULL);
//    FHG_NS_ASSERT(_allBlocksInAllFramesArray.buf != NULL, "BlocksArray is not allocated",    NULL);
//    FHG_NS_ASSERT(_gaussianMask.data             != NULL, "GaussianMask is not allocated",   NULL);
//
//    FHG_NS_LOG(@"Play started, creating blocks", NULL);
//
//
//    const CGImageRef formatImage      = [_imageGenerator copyCGImageAtTime:CMTimeMake(1, 10) actualTime:NULL error:nil];
//    const vImage_CGImageFormat format = {
//        .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(formatImage),
//        .bitsPerPixel     = (uint32_t)CGImageGetBitsPerPixel(formatImage),
//        .colorSpace       = CGImageGetColorSpace(formatImage),
//        .bitmapInfo       = CGImageGetBitmapInfo(formatImage),
//        .version          = 0,
//        .decode           = CGImageGetDecode(formatImage),
//        .renderingIntent  = CGImageGetRenderingIntent(formatImage),
//    };
//
//    CFRetain(format.colorSpace);
//
//    FHG_NS_LOG(@"Format info: bpC = %d, bpP = %d, CS = %@", format.bitsPerComponent, format.bitsPerPixel, CGColorSpaceCopyName(format.colorSpace));
//
//    //CGImageRef *const cgArray = (CGImageRef *)_cgImagesArray.buf;
//    dispatch_group_enter(_dispatchGroup);
//
//    [_imageGenerator generateCGImagesAsynchronouslyForTimes:_allSamplesTimes
//                                          completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image,
//                                                              CMTime actualTime,    AVAssetImageGeneratorResult result,
//                                                              NSError * _Nullable error) {
//                                              // IF IMAGE COULDN'T BE RETRIEVED
//                                              if (error || image == NULL)
//                                                  FHG_RAISE_EXCEPTION(@"GenerateCGImageException",
//                                                                      @"Image @ time %f couldn't be retrieved.\n%@"
//                                                                      "Image Address  =  %p,  Reason  =  %@\n"
//                                                                      "Error is: %@",
//                                                                      CMTimeGetSeconds(requestedTime),
//                                                                      (image == NULL) ? @"Image is Null\n" : @"",
//                                                                      image,
//                                                                      (result == AVAssetImageGeneratorSucceeded) ? @"Success" :
//                                                                      (result == AVAssetImageGeneratorFailed)    ? @"Failed"  :
//                                                                      @"Cancelled",
//                                                                      error);
//
//
//                                              CFRetain(image);
//
//                                              const NSUInteger index = self->_currentFrameIndex;
//                                              self->_currentFrameIndex += 1;
//
//                                              dispatch_async(self->_serialQueue, ^(void){
//                                                  [self createBlocksFrom:image at:index with:&format];
//                                                  [self createGaussianFrameAt:index];
//                                                  [self createFFTComplexAt:index];
//                                                  [self processFrameAtIndex:index];
//                                              });
//
//                                              if (self->_currentFrameIndex == self->_numRefAndSamples)
//                                                  dispatch_group_leave(self->_dispatchGroup);
//
//                                          }];
//
//    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
//
//    CFRelease(formatImage);
//    CFRelease(format.colorSpace);
//
//    FHG_NS_LOG(@"Blocks are ready", NULL);
//
//
//    //[self startProcessing];
//
//    // ONLY FOR DEBUGGING
//    do {
//        NSMutableArray *const stacks = [[NSMutableArray alloc] initWithCapacity:20];
//        UIStackView *const debugStackView = (UIStackView *)[_delegate debugView];
//
//        const vImage_CGImageFormat format = {
//            .bitsPerComponent = 8, .bitsPerPixel = 8,
//            .colorSpace = CGColorSpaceCreateDeviceGray(), //CGColorSpaceCreateDeviceGray(),
//            .bitmapInfo = (CGBitmapInfo)kCGImageByteOrderDefault, //kCGImageAlphaFirst | kCGBitmapByteOrder32Little, kCGBitmapFloatComponents
//            .version = 0, .decode = nil, .renderingIntent = kCGRenderingIntentDefault
//        };
//        vImage_Error err;
//        vImage_Buffer rawImage  = {NULL, _blockSide, _blockSide, _blockSide * sizeof(Pixel_F)};
//        void *const rawPtr      = _allBlocksInAllFramesArray.buf;
//        const size_t blkStride  = _allBlocksInAllFramesArray.size2D;
//        const size_t FrmStride  = _allBlocksInAllFramesArray.size3D;
//
//        printf("==> bs = %lu, BA = %lu, FS = %lu\n", _blockSidesPerROISide, _blocksPerROI, FrmStride);
//
//        for (size_t i = 0; i < 3; ++i) {
//
//            UIStackView *const test = [[UIStackView alloc] init];
//            [test setDistribution:UIStackViewDistributionFillEqually];
//            [test setSpacing:5.];
//
//            for (size_t j = 0; j < _blockSidesPerROISide; ++j) {
//                rawImage.data = rawPtr + blkStride * j + (i + 1) * FrmStride;
//
//                vImage_Buffer sample = fc_convert_floats_to_bytes(&rawImage, _tempRawBuffer.buf);
//                CGImageRef cgImg = vImageCreateCGImageFromBuffer(&sample, &format, nil, nil, kvImageNoFlags, &err);
//                if (err != kvImageNoError) FHG_RAISE_EXCEPTION(@"vImageErr", @"Error = %d", (int)err);
//
//                UIImageView *mainImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:cgImg]];
//                [test addArrangedSubview:mainImageView];
//            }
//
//            [stacks addObject:test];
//        }
//
//        [debugStackView setSpacing:10.];
//        for (UIStackView *const stack in stacks)
//            [debugStackView addArrangedSubview:stack];
//    } while (NO);
//}
//
//- (void)play
//{
////    [self allocAndCreateGaussianMask];
////    [self allocAndCreateKernels];
////    [self allocDFTUpscaleArray];
////    [self allocTipTiltArray];
////
////    [self selectCorrelationFunction];
//    FHG_NS_LOG(@"Play started, creating blocks", NULL);
//
//    const CMTime referenceTime = [(NSValue *)[_allSamplesTimes objectAtIndex:0] CMTimeValue];
//
//    const CGImageRef referenceImage  = [_imageGenerator copyCGImageAtTime:referenceTime actualTime:NULL error:nil];
//    const vImage_CGImageFormat referenceFormat = {
//        .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(referenceImage),
//        .bitsPerPixel     = (uint32_t)CGImageGetBitsPerPixel(referenceImage),
//        .colorSpace       = CGImageGetColorSpace(referenceImage),
//        .bitmapInfo       = CGImageGetBitmapInfo(referenceImage),
//        .version          = 0,
//        .decode           = CGImageGetDecode(referenceImage),
//        .renderingIntent  = CGImageGetRenderingIntent(referenceImage),
//    };
//
//    CFRetain(referenceFormat.colorSpace);
//
//    static const size_t kSizeOfPixel8888 = sizeof(Pixel_8888);
//    static const size_t kSizeOfFloat     = sizeof(float);
//
//    /**********************  STEP 1  ************************************/
//    const size_t frameStride      = self->_allBlocksInAllFramesArray.size3D;
//
//    const size_t height = (size_t)self->_roi.size.height;
//    const size_t width  = (size_t)self->_roi.size.width;
//
//    const size_t pointX = (size_t)self->_roi.origin.x;
//    const size_t pointY = (size_t)self->_roi.origin.y;
//
//    const size_t cgBytesPerRow = CGImageGetBytesPerRow(referenceImage);
//    const size_t startpos      = pointY * cgBytesPerRow + kSizeOfPixel8888 * pointX;
//
//    vImage_Error err;
//
//    /**********************  MEMORY: STEP 1  ************************************/
//    void *tempOne1AA = malloc(kSizeOfFloat * CGImageGetWidth(referenceImage) * CGImageGetHeight(referenceImage) * 2);
//    void *tempOne1AB = malloc(kSizeOfFloat * CGImageGetWidth(referenceImage) * CGImageGetHeight(referenceImage) * 2);
//    void *tempOne1A  = malloc(kSizeOfFloat * width * height * 2);
//    void *tempOne1B  = malloc(width * height * 2);
//    void *tempOne1C  = malloc(kSizeOfFloat * width * height * 2);
//
//    void *tempTwoOrdImag   = calloc(_blockArea * 2, kSizeOfFloat);
//    void *tempTwoFftReal   = malloc(_blockArea * 2 * sizeof(float));
//    void *tempTwoFftImag   = malloc(_blockArea * 2 * sizeof(float));
//    void *tempTwoTmpReal   = malloc(_blockArea * 2 * sizeof(float));
//    void *tempTwoTmpImag   = malloc(_blockArea * 2 * sizeof(float));
//
//    void *tempThreeRealA     = malloc(kSizeOfFloat * _blockArea * 8);
//    void *tempThreeRealB     = malloc(kSizeOfFloat * _blockArea * 8);
//    void *tempThreeRealC     = malloc(kSizeOfFloat * _blockArea * 8);
//
//    void *tempThreeImagA     = malloc(kSizeOfFloat * _blockArea * 8);
//    void *tempThreeImagB     = malloc(kSizeOfFloat * _blockArea * 8);
//    void *tempThreeImagC     = malloc(kSizeOfFloat * _blockArea * 8);
//
//    float **refFftBlocksReal = malloc(_blocksPerROI * sizeof(float *));
//    float **refFftBlocksImag = malloc(_blocksPerROI * sizeof(float *));
//
//    //FHG_NS_LOG(@"Format info: bpC = %d, bpP = %d, CS = %@", format.bitsPerComponent, format.bitsPerPixel, CGColorSpaceCopyName(format.colorSpace));
//
//
//    /**********************  STEP 1  ************************************/
//    /**********************  STEP 1A  ************************************/
//    vImage_Buffer inBuff = { tempOne1AA, CGImageGetHeight(referenceImage), CGImageGetWidth(referenceImage), cgBytesPerRow, };
//
//    err = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)&referenceFormat, NULL, referenceImage, kvImageNoAllocate);
//    NSAssert1(err == kvImageNoError, @"Error in creating vImage from CGImage =>  %ld", err);
//
//    vImage_Buffer roiBuff = {inBuff.data + startpos, height, width, inBuff.rowBytes };
//    vImage_Buffer croppedBufferBGRA = { tempOne1A, height, width, kSizeOfPixel8888 * width };
//
//    err = vImageScale_ARGB8888(&roiBuff, &croppedBufferBGRA, tempOne1AB, kvImageDoNotTile);
//    NSAssert1(err == kvImageNoError, @"Error in cropping vImage  =>  %ld", err);
//
//    /**********************  STEP 1B  ************************************/
//    vImage_Buffer croppedBufferROI = { tempOne1B, height, width, width };
//
//    err = vImageExtractChannel_ARGB8888(&croppedBufferBGRA, &croppedBufferROI, 0, kvImageNoFlags);
//    NSAssert1(err == kvImageNoError, @"Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
//
//    /**********************  STEP 1C  ************************************/
//    vImage_Buffer referenceRoi = { tempOne1C, height, width, sizeof(Pixel_F) * width };
//
//    err = vImageConvert_Planar8toPlanarF(&croppedBufferROI, &referenceRoi, 1.f, 0.f, kvImageNoFlags);
//    NSAssert1(err == kvImageNoError, @"Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
//
//    /**********************  STEP 1C  ************************************/
//    const float *const firstPixelInRoi = (float *)referenceRoi.data;
//    float *const frameBlockBuffer      = (float *)_allBlocksInAllFramesArray.buf;
//
//    size_t counter = 0;
//
//    for (size_t i = 0; i < self->_blockSidesPerROISide; ++i) {
//
//        const size_t iWidth = i * width;
//        const size_t iCount = i * self->_blockSidesPerROISide;
//
//        for (size_t j = 0; j < self->_blockSidesPerROISide; ++j) {
//            const size_t srcIndex = ( iWidth + j) * self->_blockSide;
//            const size_t dstIndex = ( iCount + j) * self->_blockArea;
//
//            const float *firstPixelInBlock = firstPixelInRoi  + srcIndex;
//            float       *rawBlock          = frameBlockBuffer + dstIndex;
//
//            vDSP_mmov(firstPixelInBlock, rawBlock, _blockSide, _blockSide, width, _blockSide);
//
//            /**********************  STEP 2  ************************************/
//            const vDSP_Length fftSideLength = fhgm_log_two(self->_blockSide);
//
//            refFftBlocksReal[counter] = malloc(_blockArea * kSizeOfFloat);
//            refFftBlocksImag[counter] = malloc(_blockArea * kSizeOfFloat);
//
//            const DSPSplitComplex ordBlock = { rawBlock,       tempTwoOrdImag };
//            const DSPSplitComplex fftBlock = { refFftBlocksReal[counter] , refFftBlocksImag[counter] };
//            const DSPSplitComplex tmpBlock = { tempTwoTmpReal, tempTwoTmpImag };
//
//            vDSP_fft2d_zopt(self->_fftSetup,
//                            &ordBlock,  1, 0, &fftBlock,  1, 0,
//                            &tmpBlock, fftSideLength, fftSideLength, kFFTDirection_Forward);
//
//            ++counter;
//        }
//    }
//
//    [self createFFTComplexAt:0];
//
//
//    __block size_t ttCounter = 0;
//
//
//    //CGImageRef *const cgArray = (CGImageRef *)_cgImagesArray.buf;
//    dispatch_group_enter(_dispatchGroup);
//
//    [_imageGenerator generateCGImagesAsynchronouslyForTimes:_allSamplesTimes
//                                          completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image,
//                                                              CMTime actualTime,    AVAssetImageGeneratorResult result,
//                                                              NSError * _Nullable error) {
//                                              // IF IMAGE COULDN'T BE RETRIEVED
//                                              if (error || image == NULL)
//                                                  FHG_RAISE_EXCEPTION(@"GenerateCGImageException",
//                                                                      @"Image @ time %f couldn't be retrieved.\n%@"
//                                                                      "Image Address  =  %p,  Reason  =  %@\n"
//                                                                      "Error is: %@",
//                                                                      CMTimeGetSeconds(requestedTime),
//                                                                      (image == NULL) ? @"Image is Null\n" : @"",
//                                                                      image,
//                                                                      (result == AVAssetImageGeneratorSucceeded) ? @"Success" :
//                                                                      (result == AVAssetImageGeneratorFailed)    ? @"Failed"  :
//                                                                      @"Cancelled",
//                                                                      error);
//
//                                              const NSUInteger index = self->_currentFrameIndex;
//                                              self->_currentFrameIndex += 1;
//
//                                              if (index == 0)
//                                                  return;
//
//                                              CFRetain(image);
//
//
//                                              dispatch_async(self->_serialQueue, ^(void){
//
//                                                  /**********************  STEP 1  ************************************/
//                                                  float *const frameBlockBuffer = (float *)(self->_allBlocksInAllFramesArray.buf + index * frameStride);
//                                                  vImage_Error err;
//
//
//                                                  /**********************  STEP 1A  ************************************/
//                                                  vImage_Buffer inBuff = { tempOne1AA, CGImageGetHeight(image), CGImageGetWidth(image), cgBytesPerRow, };
//
//                                                  err = vImageBuffer_InitWithCGImage(&inBuff, (vImage_CGImageFormat *)&referenceFormat, NULL, image, kvImageNoAllocate);
//                                                  NSAssert1(err == kvImageNoError, @"Error in creating vImage from CGImage =>  %ld", err);
//
//                                                  vImage_Buffer roiBuff = { inBuff.data + startpos, height, width, inBuff.rowBytes,};
//                                                  vImage_Buffer croppedBufferBGRA = { tempOne1A, height, width, kSizeOfPixel8888 * width };
//
//                                                  err = vImageScale_ARGB8888(&roiBuff, &croppedBufferBGRA, tempOne1AB, kvImageDoNotTile);
//                                                  NSAssert1(err == kvImageNoError, @"Error in cropping vImage  =>  %ld", err);
//                                                  CFRelease(image);
//
//                                                  /**********************  STEP 1B  ************************************/
//                                                  vImage_Buffer croppedBufferROI = { tempOne1B, height, width, sizeof(Pixel_8) * width };
//
//                                                  err = vImageExtractChannel_ARGB8888(&croppedBufferBGRA, &croppedBufferROI, 0, kvImageNoFlags);
//                                                  NSAssert1(err == kvImageNoError, @"Error in extracting channel Planar8 from vImage BGRX8888  =>  %ld", err);
//
//                                                  /**********************  STEP 1C  ************************************/
//                                                  vImage_Buffer sampleRoiBuffer = { tempOne1C, height, width, sizeof(Pixel_F) * width };
//
//                                                  err = vImageConvert_Planar8toPlanarF(&croppedBufferROI, &sampleRoiBuffer, 1.f, 0.f, kvImageNoFlags);
//                                                  NSAssert1(err == kvImageNoError, @"Error in converting vImage from Planar8 to PlanarF =>  %ld", err);
//
//                                                  /**********************  STEP 1D  ************************************/
//                                                  const float *const firstPixelInRoi = (float *)sampleRoiBuffer.data;
//
//                                                  size_t blockCounter = 0;
//
//                                                  printf("%lu == > A:  \n", index);
//                                                  for (size_t i = 0; i < self->_blockSidesPerROISide; ++i) {
//
//                                                      const size_t iWidth = i * width;
//                                                      const size_t iCount = i * self->_blockSidesPerROISide;
//
//                                                      for (size_t j = 0; j < self->_blockSidesPerROISide; ++j) {
//                                                          const size_t srcIndex = ( iWidth + j) * self->_blockSide;
//                                                          const size_t dstIndex = ( iCount + j) * self->_blockArea;
//
//                                                          const float *firstPixelInBlock = firstPixelInRoi  + srcIndex;
//                                                          float       *rawBlock          = frameBlockBuffer + dstIndex;
//
//                                                          vDSP_mmov(firstPixelInBlock, rawBlock,
//                                                                    self->_blockSide, self->_blockSide, width, self->_blockSide);
//
//                                                          /**********************  STEP 2  ************************************/
//                                                          const vDSP_Length fftSideLength = fhgm_log_two(self->_blockSide);
//
//                                                          const DSPSplitComplex ordBlock = { rawBlock,       tempTwoOrdImag };
//                                                          const DSPSplitComplex fftBlock = { tempTwoFftReal, tempTwoFftImag };
//                                                          const DSPSplitComplex tmpBlock = { tempTwoTmpReal, tempTwoTmpImag };
//
//                                                          vDSP_fft2d_zopt(self->_fftSetup,
//                                                                          &ordBlock,  1, 0, &fftBlock,  1, 0,
//                                                                          &tmpBlock, fftSideLength, fftSideLength, kFFTDirection_Forward);
//
//                                                         /**********************  STEP 3  ************************************/
//                                                          const DSPSplitComplex refBlock = { refFftBlocksReal[blockCounter], refFftBlocksImag[blockCounter] };
//                                                          const DSPSplitComplex smpBlock = fftBlock;
//
//                                                          const DSPSplitComplex tempA = { tempThreeRealA, tempThreeImagA };
//                                                          const DSPSplitComplex tempB = { tempThreeRealB, tempThreeImagB };
//                                                          const DSPSplitComplex tempC = { tempThreeRealC, tempThreeImagC };
//
//                                                          const CGPoint result =
//                                                          fhgm_spxc_correlate_two_blocks_sub_pixel(&refBlock, &smpBlock, &tempA,
//                                                                                                   self->_areaKernel.buf, &tempB,
//                                                                                                   fftSideLength, self->_fftSetup,
//                                                                                                   self->_upscaleFactor, &tempC);
//
//                                                          [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:ttCounter];
//
//                                                          printf("{%f, %f} ", result.x, result.y);
//                                                          ++ttCounter;
//                                                          ++blockCounter;
//
//                                                      }
//                                                  }
//
//
//                                                  /**********************  STEP OLD  ************************************/
//                                                  [self createFFTComplexAt:index];
//                                                  [self processFrameAtIndex:index];
//
//                                                  printf("B\n");
//
//
//                                                  /**********************  GENERIC_STEP  ************************************/
//                                                  if (index == self->_numRefAndSamples - 1)
//                                                      dispatch_group_leave(self->_dispatchGroup);
//                                              });
//                                          }];
//
//    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
//
//    CFRelease(referenceImage);
//    CFRelease(referenceFormat.colorSpace);
//
//    FHG_NS_LOG(@"Blocks are ready", NULL);
//
//    size_t i = 0;
//    for (NSValue *val in _tipTiltValues) {
//        CGPoint pt = *(CGPoint *)(_tipTiltPairsArray.buf + i * sizeof(CGPoint));
//        printf("%f, %f  ==  %f, %f\n", [val CGPointValue].x, [val CGPointValue].y, pt.x, pt.y);
//        ++i;
//    }
////    NSLog(@"%@", _tipTiltValues);
//
//    //[self startProcessing];
//
//    // ONLY FOR DEBUGGING
//
//}

#pragma mark - Public methods
- (void)setVideoUrl:(AVURLAsset *const)asset
{
    dispatch_async(_serialQueue, ^(void){
        self->_imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        
        [self->_imageGenerator setRequestedTimeToleranceBefore:CMTimeMake(1, 100)];
        [self->_imageGenerator setRequestedTimeToleranceAfter: CMTimeMake(25, 100)];
        
        NSLog(@"%f, %f", CMTimeGetSeconds(CMTimeMake(1, 100)), CMTimeGetSeconds(CMTimeMake(2, 100)));
    });
    
    FHG_NS_LOG(@"URL Set", NULL);
}

- (void)setExperimentData:(NSDictionary *const)dataDict
{
    _blockSide       =      [(NSNumber *)[dataDict valueForKey:FHGK_EXP_PARAM_BLOCK_SIZE]        unsignedIntegerValue];
    _upscaleFactor   =      [(NSNumber *)[dataDict valueForKey:FHGK_EXP_PARAM_SUBPIXEL_UPSCALE]  unsignedIntegerValue];
    _numberOfSamples = 10 * [(NSNumber *)[dataDict valueForKey:FHGK_EXP_PARAM_NUMBER_OF_SAMPLES] unsignedIntegerValue];
    
    _blockArea              = _blockSide * _blockSide;
    _numberOfSamplesPlusRef = _numberOfSamples + 1;
    
    
    const int32_t framesPerSecond = 30;
    const int64_t firstSampleTime = kFHGNumberOfSecondsToSkip * (int64_t)framesPerSecond;
    const int64_t lastSampleTime  = firstSampleTime + (int64_t)_numberOfSamplesPlusRef;
    
    for (int64_t sampleTime = firstSampleTime;  sampleTime < lastSampleTime; ++sampleTime )
        [_allSamplesTimes addObject:[NSValue valueWithCMTime:CMTimeMake(sampleTime, framesPerSecond)]];
    
    
    FHG_NS_LOG(@"Experiment Data Set. Side ==> %lu, Area ==> %lu", _blockSide, _blockArea);
}

- (void)setRoiFrame:(CGRect)rect
{
    _roi = rect;
    _roiSide = lroundf(_roi.size.width);
    
    _blockSidesPerROISide = _roiSide / _blockSide;
    _blocksPerROI         = (_roiSide * _roiSide) / _blockArea;
    
    
    FHG_NS_LOG(@"ROI Set. Side ==> %lu, SidePerROISide ==> %lu, BlkPerROI ==> %lu", _roiSide, _blockSidesPerROISide, _blocksPerROI);
}

//- (void)freeMemory
//{
//    dispatch_group_enter(_dispatchGroup);
//
//    dispatch_async(_concurrentQueue, ^(void){
//        free(self->_gaussianMask.data);
//
//        free(self->_tempRawBuffer.buf);
//
//        free(self->_allBlocksInAllFramesArray.buf);
//        free(self->_gaussianAllBlocksArray.buf);
//        free(self->_fftComplexRawBuffer.buf);
//
//        free(self->_sideKernel.buf);
//        free(self->_sideComplexKernel.buf);
//        free(self->_areaKernel.buf);
//
//        free(self->_dftUpscaleTempBuffer.buf);
//        free(self->_emptyBlockArea);
//
//        vDSP_destroy_fftsetup(self->_fftSetup);
//
//        self->_memoryFreed = YES;
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}

//#pragma mark - Setup methods
//- (void)selectCorrelationFunction
//{
//    const __weak typeof(self) weakSelf = self;
//    const NSUInteger logTwoOfBlockSide = (NSUInteger)fhgm_log_two(_blockSide);
//
//    switch (_upscaleFactor) {
//        case 2: {
//            _correlationBlock = ^CGPoint(const DSPSplitComplex *const restrict ref,
//                                         const DSPSplitComplex *const restrict smp) {
//
//                const typeof(self) strongSelf = weakSelf;
//
//                const DSPSplitComplex tempComplex = {
//                    .realp = (float *)(strongSelf->_tempRawBuffer.buf),
//                    .imagp = (float *)(strongSelf->_tempRawBuffer.buf + strongSelf->_tempRawBuffer.size2D),
//                };
//
//                const CGPoint result = fhgm_spxc_correlate_two_blocks_half_pixel(ref, smp,
//                                                                                 &tempComplex,
//                                                                                 strongSelf->_areaKernel.buf,
//                                                                                 logTwoOfBlockSide,
//                                                                                 strongSelf->_fftSetup);
//
//                return result;
//            };
//            break;
//        }
//
//        case 4:
//        case 8: {
//            _correlationBlock = ^CGPoint(const DSPSplitComplex *const restrict ref,
//                                         const DSPSplitComplex *const restrict smp) {
//                const typeof(self) strongSelf = weakSelf;
//
//                const DSPSplitComplex tempComplex = {
//                    .realp = (float *)(strongSelf->_tempRawBuffer.buf),
//                    .imagp = (float *)(strongSelf->_tempRawBuffer.buf + strongSelf->_tempRawBuffer.size2D),
//                };
//
//                const DSPSplitComplex tmpDftupsBlock = {
//                    .realp = strongSelf->_dftUpscaleTempBuffer.buf,
//                    .imagp = strongSelf->_dftUpscaleTempBuffer.buf + (strongSelf->_dftUpscaleTempBuffer.totalBytes / 2),
//                };
//
//                const DSPSplitComplex sideComplexKernel = {
//                    .realp = strongSelf->_sideComplexKernel.buf,
//                    .imagp = strongSelf->_sideComplexKernel.buf + (self->_sideComplexKernel.totalBytes / 2),
//                };
//
//                const CGPoint result = fhgm_spxc_correlate_two_blocks_sub_pixel(ref, smp, &tempComplex,
//                                                                                strongSelf->_areaKernel.buf,
//                                                                                &sideComplexKernel,
//                                                                                logTwoOfBlockSide,
//                                                                                strongSelf->_fftSetup,
//                                                                                strongSelf->_upscaleFactor,
//                                                                                &tmpDftupsBlock);
//                return result;
//            };
//            break;
//        }
//
//        case 1:
//        default: {
//            _correlationBlock = ^CGPoint(const DSPSplitComplex *const restrict ref,
//                                         const DSPSplitComplex *const restrict smp) {
//                const typeof(self) strongSelf = weakSelf;
//
//                const DSPSplitComplex tempComplex = {
//                    .realp = (float *)(strongSelf->_tempRawBuffer.buf),
//                    .imagp = (float *)(strongSelf->_tempRawBuffer.buf + strongSelf->_tempRawBuffer.size2D),
//                };
//
//                const CGPoint result = fhgm_spxc_correlate_two_blocks_no_scale(ref, smp,
//                                                                               &tempComplex,
//                                                                               strongSelf->_sideKernel.buf,
//                                                                               logTwoOfBlockSide);
//                return result;
//            };
//            break;
//        }
//    }
//}
//
//- (void)updateArraysStrides
//{
//    static const size_t kBytesInPixelF    = sizeof(Pixel_F);
//
//    const size_t bytesInOneBlock  = kBytesInPixelF  * _blockArea;
//    const size_t bytesInOneFrame  = bytesInOneBlock * _blocksPerROI;
//    //    const size_t bytesInAllFrames = bytesInOneFrame * (_numberOfSamples + 1);
//
//
//    _allBlocksInAllFramesArray.size2D = bytesInOneBlock;
//    _allBlocksInAllFramesArray.size3D = bytesInOneFrame;
//
//    _gaussianAllBlocksArray.size2D    = bytesInOneBlock;
//    _gaussianAllBlocksArray.size3D    = bytesInOneFrame;
//
//    _fftComplexRawBuffer.size2D       = bytesInOneBlock;
//    _fftComplexRawBuffer.size3D       = bytesInOneFrame;
//
//    _tipTiltPairsArray.size2D         = sizeof(CGPoint) * _blocksPerROI;
//
//    FHG_NS_LOG(@"Strides = %lu, %lu from %lu, %lu", bytesInOneBlock, bytesInOneFrame, _blockArea, _blocksPerROI);
//}
//
//#pragma mark - Micro memory methods
//- (void)allocMemory
//{
//    [self allocFFT];
//
//    [self allocTemp];
//    [self allocAllBlocksAndGaussianAndFFTComplexArray];
//
//    _memoryFreed     = NO;
//}
//
//- (void)allocFFT
//{
//    dispatch_group_enter(_dispatchGroup);
//
//    dispatch_async(_concurrentQueue, ^(void){
//        if (self->_fftSetup != 0)
//            return;
//
//        const vDSP_Length len = fhgm_log_two(kAIMMaxBlockArea) + 1 + 2; // FOR COMPLEX AND FOR FTPAD
//
//        self->_fftSetup = vDSP_create_fftsetup(len, kFFTRadix2);
//
//        FHG_NS_ASSERT(self->_fftSetup != 0, @"Error: _fftSetup is NULL", NULL);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}
//
//- (void)allocTemp
//{
//    dispatch_group_enter(_dispatchGroup);
//
//    dispatch_async(_concurrentQueue, ^(void) {
//        if (self->_tempRawBuffer.buf != NULL)
//            return;
//
//        vImage_Buffer roiBuffer = {
//            .data     = NULL,
//            .height   = (vImagePixelCount)kFHGMaximumVideoHeight,
//            .width    = (vImagePixelCount)kFHGMaximimVideoWidth,
//            .rowBytes = sizeof(Pixel_8) * kFHGMaximimVideoWidth,
//        };
//
//        vImage_Buffer tempImageBuffer = {
//            .data       = NULL,
//            .height     = (vImagePixelCount)kAIMMaxBlockSide,
//            .width      = (vImagePixelCount)kAIMMaxBlockSide,
//            .rowBytes   = sizeof(Pixel_8888) * kAIMMaxBlockSide,
//        };
//
//        const size_t tempBuffSizeFloor = (size_t)vImageScale_PlanarF(&roiBuffer, &tempImageBuffer, NULL, kvImageGetTempBufferSize);
//        const size_t originalTempBuffSize = sizeof(Pixel_8888) * kFHGMaximimVideoWidth * kFHGMaximumVideoHeight;
//
//        const size_t newTempBuffSize   = originalTempBuffSize > tempBuffSizeFloor ? originalTempBuffSize : tempBuffSizeFloor;
//        const size_t finalTempBuffSize = 2 * newTempBuffSize + 1024;
//
//        self->_tempRawBuffer = (FHGMRawBuffer) {
//            .buf        = malloc(finalTempBuffSize),
//            .totalBytes = finalTempBuffSize,
//            .size1D     = 1,
//            .size2D     = newTempBuffSize,
//            .size3D     = 0,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_tempRawBuffer.buf != NULL, "Error: tempBuffer is NULL", NULL);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}
//
//- (void)allocAllBlocksAndGaussianAndFFTComplexArray
//{
//    static const size_t kBytesInPixelF    = sizeof(Pixel_F);
//    //    static const size_t kBytesInOneBlock  = kBytesInPixelF   * kAIMMinBlockSide * kAIMMinBlockSide;
//    static const size_t kBytesInOneFrame  = kBytesInPixelF * kAIMMaxROISide * kAIMMaxROISide;
//    static const size_t kBytesInAllFrames = kBytesInOneFrame * kFHGMaximumCountOfFrames;
//
//    /*
//     *       Frame side
//     *      -------------
//     *      | * * | * * |   BlockSize
//     *      | * * | * * |
//     *      ------------- ...... * total frames
//     *      | * * | * * |
//     *      | * * | * * |
//     *      -------------
//     *
//     *
//     *      Each * (Pixel): sizeof(Pixel_F)                     [bytes]
//     *      // each Block:     sizeof(Pixel_F)  * blockArea         [BlockAreaBytes]
//     *      each Frame:     pixel * maxFrameSize   [            FrameBytes]
//     *      All buffer:     total frames * FrameBytes
//     *
//     *      Each pixel:  Float (Pixel_F)        [Bytes]
//     *      Each Block:  blockArea              [Pixels]
//     *      Each Frame:  FrameSide / BlockSide [Blocks]
//     *
//     *      Pixel k @:
//     *          arr.buf + k * arr.size1D
//     *
//     *      Block j @:
//     *          arr.buf + arr.size2D * j
//     *
//     *      Frame i @:
//     *          arr.buf + arr.size3D * j
//     *
//     *      Pixel k of Block J of Frame i @:
//     *          arr.buf + i * arr.size3D + j * arr.size2D + k * arr.size1D
//     *
//     *      Don't forget to cast the pointer to float AFTER the calculation
//     *
//     *
//     *
//     *
//     */
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        if (self->_allBlocksInAllFramesArray.buf != NULL)
//            return;
//
//        self->_allBlocksInAllFramesArray = (FHGMRawBuffer) {
//            .buf        = malloc(kBytesInAllFrames + 1024), // For alignment
//            .totalBytes = kBytesInAllFrames,
//            .size1D     = kBytesInPixelF,
//            .size2D     = kBytesInPixelF * kAIMMaxBlockSide, // Will be changed later, whatever
//            .size3D     = kBytesInOneFrame,                  // Will be changed later, whatever
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_allBlocksInAllFramesArray.buf != NULL, "Error: _allBlocksInAllFramesArray is NULL", NULL);
//        FHG_ALIGN_PTR(self->_allBlocksInAllFramesArray.buf);
//
//        FHG_NS_LOG(@"Allocated rawBlockBuffer %p: %lu, %lu, %lu, %lu",
//                   self->_allBlocksInAllFramesArray.buf,
//                   self->_allBlocksInAllFramesArray.totalBytes,
//                   self->_allBlocksInAllFramesArray.size1D,
//                   self->_allBlocksInAllFramesArray.size2D,
//                   self->_allBlocksInAllFramesArray.size3D);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        if (self->_gaussianAllBlocksArray.buf != NULL)
//            return;
//
//        self->_gaussianAllBlocksArray = (FHGMRawBuffer) {
//            .buf        = malloc(kBytesInAllFrames + 1024),
//            .totalBytes = kBytesInAllFrames,
//            .size1D     = kBytesInPixelF,
//            .size2D     = kBytesInPixelF * kAIMMaxBlockSide,
//            .size3D     = kBytesInOneFrame,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_gaussianAllBlocksArray.buf != NULL, "Error: _gaussianAllBlocksArray is NULL", NULL);
//        FHG_ALIGN_PTR(self->_gaussianAllBlocksArray.buf);
//
//        FHG_NS_LOG(@"Allocated _gaussianAllBlocksArray %p: %lu, %lu, %lu, %lu",
//                   self->_gaussianAllBlocksArray.buf,
//                   self->_gaussianAllBlocksArray.totalBytes,
//                   self->_gaussianAllBlocksArray.size1D,
//                   self->_gaussianAllBlocksArray.size2D,
//                   self->_gaussianAllBlocksArray.size3D);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//
//    // SINCE IT IS COMPLEX, MULTIPLY BY 2 AND ADD 4D
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        if (self->_fftComplexRawBuffer.buf != NULL)
//            return;
//
//        // Same for everything, but we use 2 blocks instead of one for complex!
//        self->_fftComplexRawBuffer = (FHGMRawBuffer) {
//            .buf        = malloc(2 * kBytesInAllFrames + 1024),
//            .totalBytes = 2 * kBytesInAllFrames,
//            .size1D     = kBytesInPixelF,           // 1 PIXEL
//            .size2D     = kBytesInPixelF * kAIMMaxBlockSide,         // 1 BLOCK
//            .size3D     = kBytesInOneFrame,         // 1 FRAME
//            .size4D     = kBytesInAllFrames,        // FULL RAW, REAL OR IMAG
//        };
//
//        FHG_NS_ASSERT(self->_fftComplexRawBuffer.buf != NULL, "Error: _fftComplexRawBuffer is NULL", NULL);
//        FHG_ALIGN_PTR(self->_fftComplexRawBuffer.buf);
//
//        FHG_NS_LOG(@"Allocated _fftComplexRawBuffer %p: %lu, %lu, %lu, %lu",
//                   self->_fftComplexRawBuffer.buf,
//                   self->_fftComplexRawBuffer.totalBytes,
//                   self->_fftComplexRawBuffer.size1D,
//                   self->_fftComplexRawBuffer.size2D,
//                   self->_fftComplexRawBuffer.size3D);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}
//
//- (void)allocAndCreateGaussianMask
//{
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        free(self->_gaussianMask.data);
//        self->_gaussianMask     = fhgm_gm_create_gaussian_mask_float(self->_blockSide);
//
//        FHG_NS_ASSERT(self->_gaussianMask.data     != NULL, "Error: _gaussianMask is NULL", NULL);
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        free(self->_emptyBlockArea);
//        self->_emptyBlockArea = calloc(sizeof(float), kAIMMaxBlockArea);
//
//        FHG_NS_ASSERT(self->_emptyBlockArea != NULL, "Error: _emptyBlockArea is NULL", NULL);
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}
//
//- (void)allocAndCreateKernels
//{
//    static const size_t kBytesInPixelF    = sizeof(Pixel_F);
//    const size_t bytesInSideKernel        = _blockSide * kBytesInPixelF;
//    const size_t bytesInAreaKernel        = _blockSide * kBytesInPixelF * 2; //_blockArea * kBytesInPixelF;
//
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_serialQueue, ^(void) {
//        free(self->_areaKernel.buf);
//
//        self->_areaKernel = (FHGMRawBuffer) {
//            .buf        = malloc(bytesInAreaKernel + 64),
//            .totalBytes = bytesInAreaKernel,
//            .size1D     = kBytesInPixelF,
//            .size2D     = bytesInSideKernel,
//            .size3D     = 0,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_areaKernel.buf != NULL, "Error: _areaKernel is NULL", NULL);
//        FHG_ALIGN_PTR(self->_areaKernel.buf);
//
//        free(self->_sideKernel.buf);
//        self->_sideKernel = (FHGMRawBuffer) {
//            .buf        = malloc(bytesInSideKernel + 64),
//            .totalBytes = bytesInSideKernel,
//            .size1D     = kBytesInPixelF,
//            .size2D     = 0,
//            .size3D     = 0,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_sideKernel.buf != NULL, "Error: _sideKernel is NULL", NULL);
//        FHG_ALIGN_PTR(self->_sideKernel.buf);
//
//        free(self->_sideComplexKernel.buf);
//        self->_sideComplexKernel = (FHGMRawBuffer) {
//            .buf        = malloc(2 * bytesInSideKernel + 64),
//            .totalBytes = 2 * bytesInSideKernel,
//            .size1D     = kBytesInPixelF,
//            .size2D     = bytesInSideKernel,
//            .size3D     = 0,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_sideComplexKernel.buf != NULL, "Error: _sideComplexKernel is NULL", NULL);
//        FHG_ALIGN_PTR(self->_sideComplexKernel.buf);
//
//        const DSPSplitComplex complexKernel = {
//            .realp = (float *)(self->_sideComplexKernel.buf),
//            .imagp = (float *)(self->_sideComplexKernel.buf + self->_sideComplexKernel.size2D),
//        };
//
//        fhgm_spxc_create_kernels(self->_sideKernel.buf, self->_areaKernel.buf, self->_blockSide);
//        fhgm_spxc_create_complex_kernel(&complexKernel, self->_blockSide, self->_upscaleFactor, self->_tempRawBuffer.buf);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}
//
//- (void)allocDFTUpscaleArray
//{
//    /*
//     *  SIZE OF POINTERS IN DFTUPS_TMP_BLOCK SHOULD BE EACH:
//     *      IF usfac1p5 is SCALING_FACTOR * 1.5, THEN EACH POINTER:
//     *      2 * USFAC1P5^2  +  2 * USFAC1P5  +  2 * USFAC1P5 * BLOCKSIZE
//     *      WHERE:
//     *          - 2 * USFAC1P5^2 ARE THE OUTPUT BLOCK & A TEMP OUTPUT BLOCK
//     *          - 2 * USFAC1P5 ARE THE NOC AND NOR
//     *          - 2 * USFAC1P5 * BLOCKSIZE ARE 2 MATRICES HOLDING NOC * NC OR NOR * NR
//     *
//     *  IN HERE, MULTIPLY THE ALLOCATION BY 2,
//     *  AND PUT THE STRIDE EQUALS TO HALF DISTANCE
//     *  STRIDE CAN BE USED TO SEPARATE REAL AND COMPLEX PLANES
//     *
//     *
//     */
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        free(self->_dftUpscaleTempBuffer.buf);
//
//        const size_t upscaleFactor1p5 = (size_t)((self->_upscaleFactor * 15) / 10);
//        const size_t upscaleFactor1p5Squared = upscaleFactor1p5 * upscaleFactor1p5;
//
//        const size_t elementsCount = 2 * upscaleFactor1p5Squared + 2 * upscaleFactor1p5 + 2 * upscaleFactor1p5 * self->_blockSide;
//
//        self->_dftUpscaleTempBuffer = (FHGMRawBuffer) {
//            .buf        = malloc(2 * sizeof(Pixel_F) * elementsCount),
//            .totalBytes = 2 * sizeof(Pixel_F) * elementsCount,
//            .size1D     = 2 * upscaleFactor1p5Squared,
//            .size2D     = 2 * upscaleFactor1p5,
//            .size3D     = 2 * upscaleFactor1p5 * self->_blockSide,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_dftUpscaleTempBuffer.buf != NULL, @"Error: _dftUpscalingBuffer is NULL", NULL);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}
//
//- (void)allocTipTiltArray
//{
//    static const size_t kSizeOfCGPoint = sizeof(CGPoint);
//
//    dispatch_group_enter(_dispatchGroup);
//    dispatch_async(_concurrentQueue, ^(void) {
//        const size_t bytesPerFrame = kSizeOfCGPoint * kAIMMaxROISide * kAIMMaxROISide / (kAIMMinBlockSide * kAIMMinBlockSide);
//        const size_t totalBytes    = bytesPerFrame  * kFHGMaximumCountOfSamples;    // Not total frames
//
//        self->_tipTiltValues = [NSMutableArray arrayWithCapacity:(totalBytes / kSizeOfCGPoint)];
//
//        /*
//         *
//         *  PER BLOCK, WE HAVE ONE CGPOINT
//         *      SO TOTAL BYTES IS SIZEOF(CGPOINT) * _BLOCKS IN ONE FRAME * NUMBER OF SAMPLES
//         *
//         *  NOTE, NUMBER OF SAMPLES IS WITHOUT REFERENCE, NO XCORR FOR REFERNCE !!
//         *
//         *
//         *
//         */
//        free(self->_tipTiltPairsArray.buf);
//        self->_tipTiltPairsArray = (FHGMRawBuffer) {
//            .buf        = malloc(totalBytes + 128), // For alignment
//            .totalBytes = totalBytes,
//            .size1D     = kSizeOfCGPoint,
//            .size2D     = bytesPerFrame,
//            .size3D     = 0,
//            .size4D     = 0,
//        };
//
//        FHG_NS_ASSERT(self->_tipTiltPairsArray.buf != NULL, "Error: _tipTiltPairsArray is NULL", NULL);
//        FHG_ALIGN_PTR(self->_tipTiltPairsArray.buf);
//
//        dispatch_group_leave(self->_dispatchGroup);
//    });
//}


@end
