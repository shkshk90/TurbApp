//
//  AllOps.h
//  TurbApp
//
//  Created by Samuel Aysser on 22.04.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef AllOps_h
#define AllOps_h

#include <stdio.h>
#include <stdint.h>

struct FhgData;
typedef struct CGRect CGRect;
typedef struct CGImage *CGImageRef;
typedef struct vImage_CGImageFormat vImage_CGImageFormat;


void fhgPreOpsCreateCGFormat(vImage_CGImageFormat *const restrict format);
void fhgPreOpsCreateData(struct FhgData *const restrict data, const uint32_t blockSide,   const uint32_t numberOfFrames,
                         const  CGRect  *const restrict roi,  const uint32_t frameHeight, const uint32_t frameWidth);

void fhgPreOpsAllocTemp(void **buffer, const struct FhgData *const restrict data);
void fhgPreOpsAllocBlockBuffer(void **buffer, const struct FhgData *const restrict data);


void fhgOpsConvertFullFrameToBlocks(const restrict CGImageRef fullFrame,
                                    const vImage_CGImageFormat *const restrict format,
                                    const struct FhgData *const restrict data,
                                    void *const restrict blocksBuffer,
                                    void *const restrict tempBuffer);

#endif /* AllOps_h */
