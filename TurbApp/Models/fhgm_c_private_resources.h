//
//  fhgm_c_private_resources.h
//  TurbApp
//
//  Created by Samuel Aysser on 08.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef fhgm_c_private_resources_h
#define fhgm_c_private_resources_h

#ifndef NDEBUG
 #define VIMAGE_FLAG kvImagePrintDiagnosticsToConsole
#else
 #define VIMAGE_FLAG kvImageNoFlags
#endif

#define FHGM_CPR_ASSERT(COND, MSJ, ...) do { \
    if (!(COND)) { \
        printf("[%s:%d %s]: " MSJ "\n", __FILE__, __LINE__, __FUNCTION__, __VA_ARGS__); \
        assert(false); \
    } \
} while (0);

#endif /* fhgm_c_private_resources_h */
