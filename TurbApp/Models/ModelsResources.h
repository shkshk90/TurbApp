//
//  ModelsResources.h
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef ModelsResources_h
#define ModelsResources_h

#import <Foundation/Foundation.h>

#define CONCURRENT_QUEUE_LABEL "io.sam.absolute-correlator-concurrent-queue"
#define SERIAL_QUEUE_LABEL     "io.sam.absolute-correlator-serial-queue"



// EVERYTHING IS IN BYTES
typedef struct fhg_data_buffer {
    // RAW BUFFER POINTER
    void    *buf;
    
    // VALUE GIVEN TO MALLOC, ALL BYTES ALLOCATED FOR BUFFER
    NSUInteger  totalBytes;
    
    // TYPE IS THE SINGLE ELEMENT, e.g. char/ float ... etc.
    // IT IS THE INCREMENT FOR SINGLE ELEMENT IN 1D ARRAY
    NSUInteger  size1D;
    
    /*
     *  EACH LEN IS IN BYTES !!
     *      2D LEN OF A SINGLE ELEMENT, IF 2D, THIS IS THE INCREMENT
     *      3D LEN OF A SINGLE ELEMENT, IF 3D, THIS IS THE INCREMENT
     *      4D LEN OF A SINGLE ELEMENT, IF 4D, THIS IS THE INCREMENT
     */
    NSUInteger  size2D;
    NSUInteger  size3D;
    NSUInteger  size4D;
} FHGMRawBuffer;

static const NSUInteger kAIMMinBlockSide      = 16;
static const NSUInteger kAIMMaxBlockSide      = 128;
static const NSUInteger kAIMMaxBlockArea      = kAIMMaxBlockSide * kAIMMaxBlockSide;
static const NSUInteger kAIMMaxROISide        = 640;   // Max Allowed Height




NS_INLINE NSUInteger
fhgm_log_two(const NSUInteger length)
{
    const uint32_t length32      = (uint32_t)length;
    const uint32_t leadingZeroes = __builtin_clz(length32);
    
    const NSUInteger log2len    = (NSUInteger)(31 - leadingZeroes);
    
    return log2len;
}

#endif /* ModelsResources_h */
