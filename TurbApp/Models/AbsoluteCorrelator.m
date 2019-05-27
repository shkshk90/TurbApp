//
//  AbsoluteCorrelator.m
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

@import AVFoundation;
@import Accelerate;
@import CoreGraphics;

#import "AbsoluteCorrelator.h"
#import "ModelsResources.h"
#import "AbsoluteCorrelator_private.h"
#import "GaussianMask.h"
#import "SubpixelCrossCorrelator.h"
#import "../common.h"

// Test new buffers technique
#define NEW_BUFFERS 1
#define NOTIMPLEMENTED 1

#pragma mark - Implementation & Private members
@implementation FHGAbsoluteCorrelator {

// Experiment-related data
@private CGSize                      _videoSize;
@private CGRect                      _roi;
    
@private NSUInteger                  _upscaleFactor;
@private NSUInteger                  _numberOfSamples;
    
@private NSUInteger                  _blockSide;
@private NSUInteger                  _blockArea;

@private NSUInteger                  _roiSide;
@private NSUInteger                  _blocksPerROI;
@private NSUInteger                  _blockSidesPerROISide;
    
// vImages
@private vImage_Buffer               _gaussianMask;

    
// Buffers
@private FHGMRawBuffer               _cvpbFramesArray;              // FOR CVPIXELBUFFERS
@private FHGMRawBuffer               _tempRawBuffer;                // GENERAL TEMP BUFFER
@private FHGMRawBuffer               _allBlocksInAllFramesArray;    // ALL BLOCKS IN ALL FRAMES RAW BUFFER
@private FHGMRawBuffer               _gaussianAllBlocksArray;       // ALL BLOCKS IN ALL FRAMES MUL GAUSSIAN RAW BUFFER
@private FHGMRawBuffer               _fftComplexRawBuffer;
@private FHGMRawBuffer               _sideKernel;
@private FHGMRawBuffer               _sideComplexKernel;
@private FHGMRawBuffer               _areaKernel;
@private FHGMRawBuffer               _dftUpscaleTempBuffer;
@private FHGMRawBuffer               _tipTiltPairsArray;

@private float                      *_emptyBlockArea;
 
// FFT
@private FFTSetup                    _fftSetup;
    
    
// Frame retrieval members
@private AVURLAsset                 *_videoURL;
@private CADisplayLink              *_displayLink;
    
@private AVPlayer                   *_player;
@private AVPlayerItem               *_playerItem;
@private AVPlayerItemVideoOutput    *_playerItemVideoOutput;
    
// Dispatch Queues
@private dispatch_queue_t           _serialQueue;
@private dispatch_queue_t           _concurrentQueue;
@private dispatch_group_t           _dispatchGroup;    // For Syncing
    
// Memory-related variables
@private BOOL                       _memoryFreed;
@private BOOL                       _experimentDataIsSet;
    
    
// Special variables
@private FHGMCorrelationBlock       _correlationBlock;
}

#pragma mark - Setup
- (instancetype)init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    
    _memoryFreed         = NO;
    
    _experimentDataIsSet = NO;
    
    _displayLink = ^{
        CADisplayLink *dl = [CADisplayLink displayLinkWithTarget:self selector:@selector(retrieveFrames:)];
        
        [dl addToRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode]; //NSRunLoopCommonModes
        [dl setPaused:YES];
        
        return dl;
    }();
    
    _serialQueue     = dispatch_queue_create(SERIAL_QUEUE_LABEL, DISPATCH_QUEUE_SERIAL);
//    _concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _concurrentQueue = dispatch_queue_create(CONCURRENT_QUEUE_LABEL, DISPATCH_QUEUE_CONCURRENT);
    _dispatchGroup   = dispatch_group_create();
    
    [self allocMemory];
    
    return self;
}

- (void)dealloc
{
    free(_tipTiltPairsArray.buf);
    
    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
    if (_memoryFreed == NO) {
        [self freeMemory];
        dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    }
}

#pragma mark - Main Processing Routines
- (void)startProcessing
{
    NSMutableArray *const stacks = [[NSMutableArray alloc] initWithCapacity:20];
    UIStackView *const debugStackView = (UIStackView *)[_delegate debugView];
    
    
    const vImage_CGImageFormat format = {
        .bitsPerComponent = 8, .bitsPerPixel = 8,
        .colorSpace = CGColorSpaceCreateDeviceGray(), //CGColorSpaceCreateDeviceGray(),
        .bitmapInfo = (CGBitmapInfo)kCGImageByteOrderDefault, //kCGImageAlphaFirst | kCGBitmapByteOrder32Little, kCGBitmapFloatComponents
        .version = 0, .decode = nil, .renderingIntent = kCGRenderingIntentDefault
    };
    vImage_Error err;
    vImage_Buffer rawImage  = {NULL, _blockSide, _blockSide, _blockSide * sizeof(Pixel_F)};
    void *const rawPtr      = _allBlocksInAllFramesArray.buf;
    const size_t blkStride  = _allBlocksInAllFramesArray.size2D;
    const size_t FrmStride  = _allBlocksInAllFramesArray.size3D;
    
    printf("==> bs = %lu, BA = %lu, FS = %lu\n", _blockSidesPerROISide, _blocksPerROI, FrmStride);
    
    for (size_t i = 0; i < 3; ++i) {
        
        UIStackView *const test = [[UIStackView alloc] init];
        [test setDistribution:UIStackViewDistributionFillEqually];
        [test setSpacing:5.];
        
        for (size_t j = 0; j < _blockSidesPerROISide; ++j) {
            rawImage.data = rawPtr + blkStride * j + (i + 40) * FrmStride;
            
            vImage_Buffer sample = fc_convert_floats_to_bytes(&rawImage, _tempRawBuffer.buf);
            CGImageRef cgImg = vImageCreateCGImageFromBuffer(&sample, &format, nil, nil, kvImageNoFlags, &err);
            if (err != kvImageNoError) FHG_RAISE_EXCEPTION(@"vImageErr", @"Error = %d", (int)err);
        
            UIImageView *mainImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:cgImg]];
            [test addArrangedSubview:mainImageView];
        }
        
        [stacks addObject:test];
    }
    
    [debugStackView setSpacing:10.];
    for (UIStackView *const stack in stacks)
         [debugStackView addArrangedSubview:stack];
    
    return;
    
    
    const size_t blockIncrement = _fftComplexRawBuffer.size2D;
    const size_t frameIncrement = _fftComplexRawBuffer.size3D;

    
    void  *const tipTiltPtr     = _tipTiltPairsArray.buf;
    const size_t tipTiltInc     = _tipTiltPairsArray.size2D;
    const size_t arrayIncrement = _tipTiltPairsArray.size2D / _tipTiltPairsArray.size1D;
    
    void *const fftRawRealPtr = _fftComplexRawBuffer.buf;
    void *const fftRawImagPtr = _fftComplexRawBuffer.buf + _fftComplexRawBuffer.size4D;
    
    dispatch_group_enter(_dispatchGroup);
    // WE USE SERIAL QUEUES BECAUSE WE MAKE USE OF THE TEMP BUFFERS
    dispatch_apply(_numberOfSamples, _serialQueue, ^(size_t i) {
        
        dispatch_group_enter(self->_dispatchGroup);
        
        const size_t sampleIndex = i + 1;
        
        void *const  sampleFFTRealPtr = fftRawRealPtr + sampleIndex * frameIncrement;
        void *const  sampleFFTImagPtr = fftRawImagPtr + sampleIndex * frameIncrement;
        
        
        // TipTilt has no reference, and no block inc.
        CGPoint *const tipTiltsInSample = (CGPoint *)(tipTiltPtr + i * tipTiltInc);

        // Process all blocks in frame i
        for (size_t j = 0; j < self->_blocksPerROI; ++j) {
            
            const DSPSplitComplex refBlock = {
                .realp = (float *)(fftRawRealPtr + j * blockIncrement),
                .imagp = (float *)(fftRawImagPtr + j * blockIncrement),
            };
            
            const DSPSplitComplex smpBlock = {
                .realp = (float *)(sampleFFTRealPtr + j * blockIncrement),
                .imagp = (float *)(sampleFFTImagPtr + j * blockIncrement),
            };
            
            const CGPoint result = self->_correlationBlock(&refBlock, &smpBlock);
            
            tipTiltsInSample[j]  = result;
            [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:(i * arrayIncrement + j)];
        }
        
        dispatch_group_leave(self->_dispatchGroup);
        if (self->_numberOfSamples - i == 1)
            dispatch_group_leave(self->_dispatchGroup);
    });
    
    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
    FHG_NS_LOG(@"Tip Tilt Pairs are ready, ", NULL);
    FHG_NS_LOG(@"TipTiltPairs: %@", _tipTiltValues);
    
//    for (size_t i = 0; i < _blocksPerROI * _numberOfSamples; ++i) {
//        printf("(%f, %f)\n", ((CGPoint *)(_tipTiltPairsArray.buf))[i].x,  ((CGPoint *)(_tipTiltPairsArray.buf))[i].y);
//    }
}

- (void)createRawFrameAt:(const NSUInteger)index
{
    CVPixelBufferRef *const framePixelBuffer = (CVPixelBufferRef *)_cvpbFramesArray.buf; //(_cvpbFramesArray.buf + index * _cvpbFramesArray.size1D);
    const size_t frameStride      = _allBlocksInAllFramesArray.size3D;
    float *const frameBlockBuffer = (float *)(_allBlocksInAllFramesArray.buf + index * frameStride);
    
//    printf("Converting pixelBuf @ %p\n", CVPixelBufferGetBaseAddress(framePixelBuffer[index]));
    
    create_raw_blocks_from_pixels(framePixelBuffer[index],
                                  frameBlockBuffer,
                                  _blockSide,
                                  _blockSidesPerROISide,
                                  _roi,
                                  &_tempRawBuffer);
}

- (void)createGaussianFrameAt:(const NSUInteger)index
{
    const size_t frameStride = _allBlocksInAllFramesArray.size3D;
    const size_t blockStride = _allBlocksInAllFramesArray.size2D;
    
    for (size_t j = 0; j < _blocksPerROI; ++j) {
        const vImage_Buffer block = {
            .data     = _allBlocksInAllFramesArray.buf + index * frameStride + j * blockStride,
            .width    = _blockSide,
            .height   = _blockSide,
            .rowBytes = _blockSide * sizeof(Pixel_F),
        };
        
        float *const gaussianBlock = (float *)(_gaussianAllBlocksArray.buf + index * frameStride + j * blockStride);
        
        fhgm_gm_multiply_block_by_gaussian_fill(&block, &_gaussianMask, _blockSide, gaussianBlock);
    }
}

- (void)createFFTComplexAt:(const NSUInteger)index
{
    const size_t blockIncrement     = _allBlocksInAllFramesArray.size2D;
    const size_t frameIncrement     = _allBlocksInAllFramesArray.size3D;
    
    const vDSP_Length fftSideLength = fhgm_log_two(_blockSide);
    
#if CHECK_HERE == 0
#endif
    void  *const inputPtr        = _allBlocksInAllFramesArray.buf; //_gaussianAllBlocksArray.buf;
    void  *const complexRealPtr  = _fftComplexRawBuffer.buf;
    void  *const complexImagPtr  = _fftComplexRawBuffer.buf + _fftComplexRawBuffer.size4D;
    
    const DSPSplitComplex tempComplex = {
        .realp = (float *)(_tempRawBuffer.buf),
        .imagp = (float *)(_tempRawBuffer.buf + _tempRawBuffer.size2D),
    };
    
    // Pointer to start of Frame index
    void *const inputRefFramePtr   = inputPtr       + index * frameIncrement;
    void *const refFftRealFramePtr = complexRealPtr + index * frameIncrement;
    void *const refFftImagFramePtr = complexImagPtr + index * frameIncrement;
    
    
    // Process all blocks in frame index
    for (size_t j = 0; j < _blocksPerROI; ++j) {
        // Pointer to start of Block j of Frame 0
        void *const inputRefBlockPtr   = inputRefFramePtr   + j * blockIncrement;
        void *const refFftRealBlockPtr = refFftRealFramePtr + j * blockIncrement;
        void *const refFftImagBlockPtr = refFftImagFramePtr + j * blockIncrement;
        
        const DSPSplitComplex refGausBlock = {
            .realp = (float *)inputRefBlockPtr,
            .imagp = _emptyBlockArea,
        };
        
        const DSPSplitComplex refFftBlock = {
            .realp = (float *)refFftRealBlockPtr,
            .imagp = (float *)refFftImagBlockPtr,
        };
        
        vDSP_fft2d_zopt(_fftSetup,
                        &refGausBlock, 1, 0,
                        &refFftBlock,  1, 0,
                        &tempComplex,
                        fftSideLength, fftSideLength,
                        kFFTDirection_Forward);
    }
    
}

- (void)processFrameAtIndex:(const NSUInteger)index
{
    if (index == 0)
        return;
    
    const size_t blockIncrement = _fftComplexRawBuffer.size2D;
    const size_t frameIncrement = _fftComplexRawBuffer.size3D;
    
    
    void  *const tipTiltPtr     = _tipTiltPairsArray.buf;
    const size_t tipTiltInc     = _tipTiltPairsArray.size2D;
    const size_t arrayIncrement = _tipTiltPairsArray.size2D / _tipTiltPairsArray.size1D;
    
    void *const fftRawRealPtr = _fftComplexRawBuffer.buf;
    void *const fftRawImagPtr = _fftComplexRawBuffer.buf + _fftComplexRawBuffer.size4D;
    
        
    const size_t i = index - 1;
    const size_t sampleIndex = index;
    
    void *const  sampleFFTRealPtr = fftRawRealPtr + sampleIndex * frameIncrement;
    void *const  sampleFFTImagPtr = fftRawImagPtr + sampleIndex * frameIncrement;
    
    
    // TipTilt has no reference, and no block inc.
    CGPoint *const tipTiltsInSample = (CGPoint *)(tipTiltPtr + i * tipTiltInc);
    
    // Process all blocks in frame i
    for (size_t j = 0; j < self->_blocksPerROI; ++j) {
        
        const DSPSplitComplex refBlock = {
            .realp = (float *)(fftRawRealPtr + j * blockIncrement),
            .imagp = (float *)(fftRawImagPtr + j * blockIncrement),
        };
        
        const DSPSplitComplex smpBlock = {
            .realp = (float *)(sampleFFTRealPtr + j * blockIncrement),
            .imagp = (float *)(sampleFFTImagPtr + j * blockIncrement),
        };
        
        const CGPoint result = self->_correlationBlock(&refBlock, &smpBlock);
        
        tipTiltsInSample[j]  = result;
        [self->_tipTiltValues insertObject:[NSValue valueWithCGPoint:result] atIndex:(i * arrayIncrement + j)];
    }

    if (index != _numberOfSamples)
        return;
    
    FHG_NS_LOG(@"Tip Tilt Pairs are ready, ", NULL);
    FHG_NS_LOG(@"TipTiltPairs: %@", _tipTiltValues);
    
    //    for (size_t i = 0; i < _blocksPerROI * _numberOfSamples; ++i) {
    //        printf("(%f, %f)\n", ((CGPoint *)(_tipTiltPairsArray.buf))[i].x,  ((CGPoint *)(_tipTiltPairsArray.buf))[i].y);
    //    }
}

#pragma mark - CADisplay methods
- (void)retrieveFrames:(CADisplayLink *)sender
{
    static size_t currentFrameIndex = 0;

    const CFTimeInterval nextVSync  = sender.timestamp + sender.duration;
    const CMTime currentTime        = [_playerItemVideoOutput itemTimeForHostTime:nextVSync];
//FUCK:
    CVPixelBufferRef *const framePixelBuffer = (CVPixelBufferRef *)_cvpbFramesArray.buf; //(_cvpbFramesArray.buf + currentFrameIndex * _cvpbFramesArray.size1D);
    
    if ([_playerItemVideoOutput hasNewPixelBufferForItemTime:currentTime]) {
//        FHG_NS_LOG(@"Player status is = %ld, (%ld, %ld, %ld)", _player.status, AVPlayerTimeControlStatusPaused, AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate, AVPlayerTimeControlStatusPlaying);
//        if (_player.status == 1)
//            FHG_NS_LOG(@"%@", [_player reasonForWaitingToPlay]);
        //FHG_NS_LOG(@"Player Item time = %f", CMTimeGetSeconds(_playerItem.currentTime));
        framePixelBuffer[currentFrameIndex] = [_playerItemVideoOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
        
        if (framePixelBuffer[currentFrameIndex]) {
            CVPixelBufferLockBaseAddress(framePixelBuffer[currentFrameIndex], kCVPixelBufferLock_ReadOnly);
            printf("PixelBuf @ %p\n", CVPixelBufferGetBaseAddress(framePixelBuffer[currentFrameIndex]));
            
            const size_t index       = currentFrameIndex;
            
            dispatch_group_enter(_dispatchGroup);
            
            // We use Serial queues because we use tempBuffer
            dispatch_async(_serialQueue, ^(void){
                [self createRawFrameAt:index];
//                [self createGaussianFrameAt:index];
//                [self createFFTComplexAt:index];
//                [self processFrameAtIndex:index];
                
                dispatch_group_leave(self->_dispatchGroup);
            });
            
            ++currentFrameIndex;
//            dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
            
        }
    }

    if (currentFrameIndex > _numberOfSamples)
        [self endPlaying];
}

- (void)play
{
    FHG_NS_ASSERT(_tempRawBuffer.buf             != NULL, "Temp is not allocated",         NULL);
    FHG_NS_ASSERT(_allBlocksInAllFramesArray.buf != NULL, "BlocksArray is not allocated",  NULL);
    FHG_NS_ASSERT(_gaussianMask.data             != NULL, "GaussianMask is not allocated", NULL);
    
    
    [_player seekToTime:CMTimeMakeWithSeconds(kFHGNumberOfSecondsToSkip, 1)];
    
//    [_player play];
    [_player playImmediatelyAtRate:1.f];
    [_displayLink setPaused:NO];
    
    FHG_NS_LOG(@"Started CADisplayLink", NULL);
    FHG_NS_LOG(@"Player status is = %ld", _player.status);
    //FHG_NS_ASSERT(_player.status == AVPlayerTimeControlStatusPlaying, @"_player's status is not playing!", NULL);
}

- (void)endPlaying
{
    [_player pause];
    
    [_displayLink setPaused:YES];
    [_displayLink removeFromRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
    [_displayLink invalidate];
    
    //FHG_NS_ASSERT(_player.status == AVPlayerTimeControlStatusPaused, @"_player's status is not paused!", NULL);
    FHG_NS_LOG(@"Player Item time = %f", CMTimeGetSeconds(_playerItem.currentTime));
    
    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    return;
    
    FHG_NS_LOG(@"FFT Done, displayLink killed", NULL);
    
    [self startProcessing];
}

#pragma mark - Public methods
- (void)setVideoUrl:(AVURLAsset *const)asset
{
    dispatch_async(_concurrentQueue, ^(void){
        self->_playerItemVideoOutput = ^{
            NSDictionary *opt = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                 //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                                                            forKey: (id)kCVPixelBufferPixelFormatTypeKey];
            
            return [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:opt];
        }();
        
        [self->_playerItemVideoOutput setSuppressesPlayerRendering:YES];
        
        self->_playerItem = ^{
            NSArray  *assetKeys = @[@"playable", @"readable"];
            
            return [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:assetKeys];
        }();
        
        [self->_playerItem addOutput:self->_playerItemVideoOutput];
        self->_player = [[AVPlayer alloc] initWithPlayerItem:self->_playerItem];
        
        [self->_player setMuted:YES];
        [self->_player pause];
    });
    
    FHG_NS_LOG(@"URL Set", NULL);
}

- (void)setExperimentData:(NSDictionary *const)dataDict
{
    _blockSide       = [(NSNumber *)[dataDict valueForKey:FHGK_EXP_PARAM_BLOCK_SIZE]        unsignedIntegerValue];
    _blockArea       = _blockSide * _blockSide;
    
    _upscaleFactor   = [(NSNumber *)[dataDict valueForKey:FHGK_EXP_PARAM_SUBPIXEL_UPSCALE]  unsignedIntegerValue];
    _numberOfSamples = 10 * [(NSNumber *)[dataDict valueForKey:FHGK_EXP_PARAM_NUMBER_OF_SAMPLES] unsignedIntegerValue];
#ifdef CHECK
#endif
    
    
    [self allocAndCreateGaussianMask];
    [self allocAndCreateKernels];
    [self allocDFTUpscaleArray];
    [self allocTipTiltArray];
    
    [self selectCorrelationBlock];
    // _progress = [NSProgress progressWithTotalUnitCount:(int64_t)_totalSamplesCount];
    
    _memoryFreed      = NO;
    
    FHG_NS_LOG(@"Experiment Data Set. Side ==> %lu, Area ==> %lu", _blockSide, _blockArea);
}

- (void)setRoiFrame:(CGRect)rect
{
    _roi = rect;
    _roiSide = lroundf(_roi.size.width);
    
    _blockSidesPerROISide = _roiSide / _blockSide;
    _blocksPerROI = (_roiSide * _roiSide) / _blockArea;
    
    [self updateArraysStrides];
    
    FHG_NS_LOG(@"ROI Set. Side ==> %lu, SidePerROISide ==> %lu, BlkPerROI ==> %lu", _roiSide, _blockSidesPerROISide, _blocksPerROI);
}

- (void)freeMemory
{
    dispatch_group_enter(_dispatchGroup);
    
    dispatch_async(_concurrentQueue, ^(void){
        free(self->_gaussianMask.data);
        
        free(self->_cvpbFramesArray.buf);
        free(self->_tempRawBuffer.buf);
        
        free(self->_allBlocksInAllFramesArray.buf);
        free(self->_gaussianAllBlocksArray.buf);
        free(self->_fftComplexRawBuffer.buf);
        
        free(self->_sideKernel.buf);
        free(self->_sideComplexKernel.buf);
        free(self->_areaKernel.buf);
        
        free(self->_dftUpscaleTempBuffer.buf);        
        free(self->_emptyBlockArea);
        
        vDSP_destroy_fftsetup(self->_fftSetup);
        
        self->_memoryFreed = YES;
        
        dispatch_group_leave(self->_dispatchGroup);
    });
}

#pragma mark - Setup methods
- (void)selectCorrelationBlock
{
    const __weak typeof(self) weakSelf = self;
    const NSUInteger logTwoOfBlockSide = (NSUInteger)fhgm_log_two(_blockSide);
    
    switch (_upscaleFactor) {
        case 2: {
            _correlationBlock = ^CGPoint(const DSPSplitComplex *const restrict ref,
                                         const DSPSplitComplex *const restrict smp) {
                
                const typeof(self) strongSelf = weakSelf;
                
                const DSPSplitComplex tempComplex = {
                    .realp = (float *)(strongSelf->_tempRawBuffer.buf),
                    .imagp = (float *)(strongSelf->_tempRawBuffer.buf + strongSelf->_tempRawBuffer.size2D),
                };
                
                const CGPoint result = fhgm_spxc_correlate_two_blocks_half_pixel(ref, smp,
                                                                                 &tempComplex,
                                                                                 strongSelf->_areaKernel.buf,
                                                                                 logTwoOfBlockSide,
                                                                                 strongSelf->_fftSetup);
                
                return result;
            };
            break;
        }
            
        case 4:
        case 8: {
            _correlationBlock = ^CGPoint(const DSPSplitComplex *const restrict ref,
                                         const DSPSplitComplex *const restrict smp) {
                const typeof(self) strongSelf = weakSelf;
                
                const DSPSplitComplex tempComplex = {
                    .realp = (float *)(strongSelf->_tempRawBuffer.buf),
                    .imagp = (float *)(strongSelf->_tempRawBuffer.buf + strongSelf->_tempRawBuffer.size2D),
                };
                
                const DSPSplitComplex tmpDftupsBlock = {
                    .realp = strongSelf->_dftUpscaleTempBuffer.buf,
                    .imagp = strongSelf->_dftUpscaleTempBuffer.buf + (strongSelf->_dftUpscaleTempBuffer.totalBytes / 2),
                };
                
                const DSPSplitComplex sideComplexKernel = {
                    .realp = strongSelf->_sideComplexKernel.buf,
                    .imagp = strongSelf->_sideComplexKernel.buf + (self->_sideComplexKernel.totalBytes / 2),
                };
                
                const CGPoint result = fhgm_spxc_correlate_two_blocks_sub_pixel(ref, smp, &tempComplex,
                                                                  strongSelf->_areaKernel.buf,
                                                                  &sideComplexKernel,
                                                                  logTwoOfBlockSide,
                                                                  strongSelf->_fftSetup,
                                                                  strongSelf->_upscaleFactor,
                                                                  &tmpDftupsBlock);
                return result;
            };
            break;
        }
            
        case 1:
        default: {
                _correlationBlock = ^CGPoint(const DSPSplitComplex *const restrict ref,
                                    const DSPSplitComplex *const restrict smp) {
                    const typeof(self) strongSelf = weakSelf;
                    
                    const DSPSplitComplex tempComplex = {
                        .realp = (float *)(strongSelf->_tempRawBuffer.buf),
                        .imagp = (float *)(strongSelf->_tempRawBuffer.buf + strongSelf->_tempRawBuffer.size2D),
                    };
                    
                    const CGPoint result = fhgm_spxc_correlate_two_blocks_no_scale(ref, smp,
                                                                                   &tempComplex,
                                                                                   strongSelf->_sideKernel.buf,
                                                                                   logTwoOfBlockSide);
                    return result;
                };
                break;
        }
    }
}

- (void)updateArraysStrides
{
    static const size_t kBytesInPixelF    = sizeof(Pixel_F);
    
    const size_t bytesInOneBlock  = kBytesInPixelF  * _blockArea;
    const size_t bytesInOneFrame  = bytesInOneBlock * _blocksPerROI;
    //    const size_t bytesInAllFrames = bytesInOneFrame * (_numberOfSamples + 1);
    
    
    _allBlocksInAllFramesArray.size2D = bytesInOneBlock;
    _allBlocksInAllFramesArray.size3D = bytesInOneFrame;
    
    _gaussianAllBlocksArray.size2D    = bytesInOneBlock;
    _gaussianAllBlocksArray.size3D    = bytesInOneFrame;
    
    _fftComplexRawBuffer.size2D       = bytesInOneBlock;
    _fftComplexRawBuffer.size3D       = bytesInOneFrame;
    
    _tipTiltPairsArray.size2D         = sizeof(CGPoint) * _blocksPerROI;
    
    FHG_NS_LOG(@"Strides = %lu, %lu from %lu, %lu", bytesInOneBlock, bytesInOneFrame, _blockArea, _blocksPerROI);
}

#pragma mark - Micro memory methods
- (void)allocMemory
{
    [self allocFFT];
    [self allocCVArray];
    [self allocTemp];
    [self allocAllBlocksAndGaussianAndFFTComplexArray];
    
    _memoryFreed     = NO;
}

- (void)allocFFT
{
    dispatch_async(_concurrentQueue, ^(void){
        if (self->_fftSetup != 0)
            return;
        
        const vDSP_Length len = fhgm_log_two(kAIMMaxBlockArea) + 1 + 2; // FOR COMPLEX AND FOR FTPAD
        
        self->_fftSetup = vDSP_create_fftsetup(len, kFFTRadix2);
        
        FHG_NS_ASSERT(self->_fftSetup != 0, @"Error: _fftSetup is NULL", NULL);
    });
}

- (void)allocCVArray
{
    dispatch_async(_concurrentQueue, ^(void){
        if (self->_cvpbFramesArray.buf != NULL)
            return;
        
        self->_cvpbFramesArray = (FHGMRawBuffer) {
            .buf        = malloc(sizeof(CVPixelBufferRef) * kFHGMaximumCountOfFrames),
            .totalBytes = sizeof(CVPixelBufferRef) * kFHGMaximumCountOfFrames,
            .size1D     = sizeof(CVPixelBufferRef),
            .size2D     = 0,
            .size3D     = 0,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_cvpbFramesArray.buf != 0, @"Error: _cvpbFramesArray is NULL", NULL);
    });
}

- (void)allocTemp
{
    dispatch_async(_concurrentQueue, ^(void) {
        if (self->_tempRawBuffer.buf != NULL)
            return;
        
        vImage_Buffer roiBuffer = {
            .data     = NULL,
            .height   = (vImagePixelCount)kFHGMaximumVideoHeight,
            .width    = (vImagePixelCount)kFHGMaximimVideoWidth,
            .rowBytes = sizeof(Pixel_8) * kFHGMaximimVideoWidth,
        };
        
        vImage_Buffer tempImageBuffer = {
            .data       = NULL,
            .height     = (vImagePixelCount)kAIMMaxBlockSide,
            .width      = (vImagePixelCount)kAIMMaxBlockSide,
            .rowBytes   = sizeof(Pixel_8888) * kAIMMaxBlockSide,
        };
        
        const size_t tempBuffSizeFloor = (size_t)vImageScale_PlanarF(&roiBuffer, &tempImageBuffer, NULL, kvImageGetTempBufferSize);
        const size_t originalTempBuffSize = sizeof(Pixel_8888) * kFHGMaximimVideoWidth * kFHGMaximumVideoHeight;
        
        const size_t newTempBuffSize   = originalTempBuffSize > tempBuffSizeFloor ? originalTempBuffSize : tempBuffSizeFloor;
        const size_t finalTempBuffSize = 2 * newTempBuffSize + 1024;
        
        self->_tempRawBuffer = (FHGMRawBuffer) {
            .buf        = malloc(finalTempBuffSize),
            .totalBytes = finalTempBuffSize,
            .size1D     = 1,
            .size2D     = newTempBuffSize,
            .size3D     = 0,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_tempRawBuffer.buf != NULL, "Error: tempBuffer is NULL", NULL);
    });
}

- (void)allocAllBlocksAndGaussianAndFFTComplexArray
{
    static const size_t kBytesInPixelF    = sizeof(Pixel_F);
//    static const size_t kBytesInOneBlock  = kBytesInPixelF   * kAIMMinBlockSide * kAIMMinBlockSide;
    static const size_t kBytesInOneFrame  = kBytesInPixelF * kAIMMaxROISide * kAIMMaxROISide;
    static const size_t kBytesInAllFrames = kBytesInOneFrame * kFHGMaximumCountOfFrames;
    
    /*
     *       Frame side
     *      -------------
     *      | * * | * * |   BlockSize
     *      | * * | * * |
     *      ------------- ...... * total frames
     *      | * * | * * |
     *      | * * | * * |
     *      -------------
     *
     *
     *      Each * (Pixel): sizeof(Pixel_F)                     [bytes]
     *      // each Block:     sizeof(Pixel_F)  * blockArea         [BlockAreaBytes]
     *      each Frame:     pixel * maxFrameSize   [            FrameBytes]
     *      All buffer:     total frames * FrameBytes
     *
     *      Each pixel:  Float (Pixel_F)        [Bytes]
     *      Each Block:  blockArea              [Pixels]
     *      Each Frame:  FrameSide / BlockSide [Blocks]
     *
     *      Pixel k @:
     *          arr.buf + k * arr.size1D
     *
     *      Block j @:
     *          arr.buf + arr.size2D * j
     *
     *      Frame i @:
     *          arr.buf + arr.size3D * j
     *
     *      Pixel k of Block J of Frame i @:
     *          arr.buf + i * arr.size3D + j * arr.size2D + k * arr.size1D
     *
     *      Don't forget to cast the pointer to float AFTER the calculation
     *
     *
     *
     *
     */
    dispatch_async(_concurrentQueue, ^(void) {
        if (self->_allBlocksInAllFramesArray.buf != NULL)
            return;
        
        self->_allBlocksInAllFramesArray = (FHGMRawBuffer) {
            .buf        = malloc(kBytesInAllFrames + 1024), // For alignment
            .totalBytes = kBytesInAllFrames,
            .size1D     = kBytesInPixelF,
            .size2D     = kBytesInPixelF * kAIMMaxBlockSide, // Will be changed later, whatever
            .size3D     = kBytesInOneFrame,                  // Will be changed later, whatever
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_allBlocksInAllFramesArray.buf != NULL, "Error: _allBlocksInAllFramesArray is NULL", NULL);
        FHG_ALIGN_PTR(self->_allBlocksInAllFramesArray.buf);
        
        FHG_NS_LOG(@"Allocated rawBlockBuffer %p: %lu, %lu, %lu, %lu",
                   self->_allBlocksInAllFramesArray.buf,
                   self->_allBlocksInAllFramesArray.totalBytes,
                   self->_allBlocksInAllFramesArray.size1D,
                   self->_allBlocksInAllFramesArray.size2D,
                   self->_allBlocksInAllFramesArray.size3D);
    });
    
    dispatch_async(_concurrentQueue, ^(void) {
        if (self->_gaussianAllBlocksArray.buf != NULL)
            return;
        
        self->_gaussianAllBlocksArray = (FHGMRawBuffer) {
            .buf        = malloc(kBytesInAllFrames + 1024),
            .totalBytes = kBytesInAllFrames,
            .size1D     = kBytesInPixelF,
            .size2D     = kBytesInPixelF * kAIMMaxBlockSide,
            .size3D     = kBytesInOneFrame,
            .size4D     = 0,
        };
    
        FHG_NS_ASSERT(self->_gaussianAllBlocksArray.buf != NULL, "Error: _gaussianAllBlocksArray is NULL", NULL);
        FHG_ALIGN_PTR(self->_gaussianAllBlocksArray.buf);
        
        FHG_NS_LOG(@"Allocated _gaussianAllBlocksArray %p: %lu, %lu, %lu, %lu",
                   self->_gaussianAllBlocksArray.buf,
                   self->_gaussianAllBlocksArray.totalBytes,
                   self->_gaussianAllBlocksArray.size1D,
                   self->_gaussianAllBlocksArray.size2D,
                   self->_gaussianAllBlocksArray.size3D);
    });
    
    // SINCE IT IS COMPLEX, MULTIPLY BY 2 AND ADD 4D
    dispatch_async(_concurrentQueue, ^(void) {
        if (self->_fftComplexRawBuffer.buf != NULL)
            return;
        
        // Same for everything, but we use 2 blocks instead of one for complex!
        self->_fftComplexRawBuffer = (FHGMRawBuffer) {
            .buf        = malloc(2 * kBytesInAllFrames + 1024),
            .totalBytes = 2 * kBytesInAllFrames,
            .size1D     = kBytesInPixelF,           // 1 PIXEL
            .size2D     = kBytesInPixelF * kAIMMaxBlockSide,         // 1 BLOCK
            .size3D     = kBytesInOneFrame,         // 1 FRAME
            .size4D     = kBytesInAllFrames,        // FULL RAW, REAL OR IMAG
        };
        
        FHG_NS_ASSERT(self->_fftComplexRawBuffer.buf != NULL, "Error: _fftComplexRawBuffer is NULL", NULL);
        FHG_ALIGN_PTR(self->_fftComplexRawBuffer.buf);
        
        FHG_NS_LOG(@"Allocated _fftComplexRawBuffer %p: %lu, %lu, %lu, %lu",
                   self->_fftComplexRawBuffer.buf,
                   self->_fftComplexRawBuffer.totalBytes,
                   self->_fftComplexRawBuffer.size1D,
                   self->_fftComplexRawBuffer.size2D,
                   self->_fftComplexRawBuffer.size3D);
    });
}

- (void)allocAndCreateGaussianMask
{
    dispatch_async(_concurrentQueue, ^(void) {
        free(self->_gaussianMask.data);
        self->_gaussianMask     = fhgm_gm_create_gaussian_mask_float(self->_blockSide);
        
        FHG_NS_ASSERT(self->_gaussianMask.data     != NULL, "Error: _gaussianMask is NULL", NULL);
    });
    
    dispatch_async(_concurrentQueue, ^(void) {
        free(self->_emptyBlockArea);
        self->_emptyBlockArea = calloc(sizeof(float), kAIMMaxBlockArea);
        
        FHG_NS_ASSERT(self->_emptyBlockArea != NULL, "Error: _emptyBlockArea is NULL", NULL);
    });
}

- (void)allocAndCreateKernels
{
    static const size_t kBytesInPixelF    = sizeof(Pixel_F);
    const size_t bytesInSideKernel        = _blockSide * kBytesInPixelF;
    const size_t bytesInAreaKernel        = _blockArea * kBytesInPixelF;
    
    dispatch_async(_serialQueue, ^(void) {
        free(self->_areaKernel.buf);
        self->_areaKernel = (FHGMRawBuffer) {
            .buf        = malloc(bytesInAreaKernel + 64),
            .totalBytes = bytesInAreaKernel,
            .size1D     = kBytesInPixelF,
            .size2D     = bytesInSideKernel,
            .size3D     = 0,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_areaKernel.buf != NULL, "Error: _areaKernel is NULL", NULL);
        FHG_ALIGN_PTR(self->_areaKernel.buf);
        
     });
    
    dispatch_async(_serialQueue, ^(void) {
        free(self->_sideKernel.buf);
        self->_sideKernel = (FHGMRawBuffer) {
            .buf        = malloc(bytesInSideKernel + 64),
            .totalBytes = bytesInSideKernel,
            .size1D     = kBytesInPixelF,
            .size2D     = 0,
            .size3D     = 0,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_sideKernel.buf != NULL, "Error: _sideKernel is NULL", NULL);
        FHG_ALIGN_PTR(self->_sideKernel.buf);
        
    });
    
    dispatch_async(_serialQueue, ^(void) {
        free(self->_sideComplexKernel.buf);
        self->_sideComplexKernel = (FHGMRawBuffer) {
            .buf        = malloc(2 * bytesInSideKernel + 64),
            .totalBytes = 2 * bytesInSideKernel,
            .size1D     = kBytesInPixelF,
            .size2D     = bytesInSideKernel,
            .size3D     = 0,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_sideComplexKernel.buf != NULL, "Error: _sideComplexKernel is NULL", NULL);
        FHG_ALIGN_PTR(self->_sideComplexKernel.buf);
        
    });
    
    dispatch_async(_serialQueue, ^(void){
        const DSPSplitComplex complexKernel = {
            .realp = (float *)(self->_sideComplexKernel.buf),
            .imagp = (float *)(self->_sideComplexKernel.buf + self->_sideComplexKernel.size2D),
        };
        
        fhgm_spxc_create_kernels(self->_sideKernel.buf, self->_areaKernel.buf, self->_blockSide);
        fhgm_spxc_create_complex_kernel(&complexKernel, self->_blockSide, self->_upscaleFactor, self->_tempRawBuffer.buf);
    });
}

- (void)allocDFTUpscaleArray
{
    /*
     *  SIZE OF POINTERS IN DFTUPS_TMP_BLOCK SHOULD BE EACH:
     *      IF usfac1p5 is SCALING_FACTOR * 1.5, THEN EACH POINTER:
     *      2 * USFAC1P5^2  +  2 * USFAC1P5  +  2 * USFAC1P5 * BLOCKSIZE
     *      WHERE:
     *          - 2 * USFAC1P5^2 ARE THE OUTPUT BLOCK & A TEMP OUTPUT BLOCK
     *          - 2 * USFAC1P5 ARE THE NOC AND NOR
     *          - 2 * USFAC1P5 * BLOCKSIZE ARE 2 MATRICES HOLDING NOC * NC OR NOR * NR
     *
     *  IN HERE, MULTIPLY THE ALLOCATION BY 2,
     *  AND PUT THE STRIDE EQUALS TO HALF DISTANCE
     *  STRIDE CAN BE USED TO SEPARATE REAL AND COMPLEX PLANES
     *
     *
     */
    
    dispatch_async(_concurrentQueue, ^(void) {
        free(self->_dftUpscaleTempBuffer.buf);
        
        const size_t upscaleFactor1p5 = (size_t)((self->_upscaleFactor * 15) / 10);
        const size_t upscaleFactor1p5Squared = upscaleFactor1p5 * upscaleFactor1p5;
        
        const size_t elementsCount = 2 * upscaleFactor1p5Squared + 2 * upscaleFactor1p5 + 2 * upscaleFactor1p5 * self->_blockSide;
        
        self->_dftUpscaleTempBuffer = (FHGMRawBuffer) {
            .buf        = malloc(2 * sizeof(Pixel_F) * elementsCount),
            .totalBytes = 2 * sizeof(Pixel_F) * elementsCount,
            .size1D     = 2 * upscaleFactor1p5Squared,
            .size2D     = 2 * upscaleFactor1p5,
            .size3D     = 2 * upscaleFactor1p5 * self->_blockSide,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_dftUpscaleTempBuffer.buf != NULL, @"Error: _dftUpscalingBuffer is NULL", NULL);
    });
}

- (void)allocTipTiltArray
{
    static const size_t kSizeOfCGPoint = sizeof(CGPoint);
    
    dispatch_async(_concurrentQueue, ^(void) {
        const size_t bytesPerFrame = kSizeOfCGPoint * kAIMMaxROISide * kAIMMaxROISide / (kAIMMinBlockSide * kAIMMinBlockSide);
        const size_t totalBytes    = bytesPerFrame  * kFHGMaximumCountOfSamples;    // Not total frames
        
        self->_tipTiltValues = [NSMutableArray arrayWithCapacity:(totalBytes / kSizeOfCGPoint)];
        
        /*
         *
         *  PER BLOCK, WE HAVE ONE CGPOINT
         *      SO TOTAL BYTES IS SIZEOF(CGPOINT) * _BLOCKS IN ONE FRAME * NUMBER OF SAMPLES
         *
         *  NOTE, NUMBER OF SAMPLES IS WITHOUT REFERENCE, NO XCORR FOR REFERNCE !!
         *
         *
         *
         */
        free(self->_tipTiltPairsArray.buf);
        self->_tipTiltPairsArray = (FHGMRawBuffer) {
            .buf        = malloc(totalBytes + 128), // For alignment
            .totalBytes = totalBytes,
            .size1D     = kSizeOfCGPoint,
            .size2D     = bytesPerFrame,
            .size3D     = 0,
            .size4D     = 0,
        };
        
        FHG_NS_ASSERT(self->_tipTiltPairsArray.buf != NULL, "Error: _tipTiltPairsArray is NULL", NULL);
        FHG_ALIGN_PTR(self->_tipTiltPairsArray.buf);
    });
}


@end