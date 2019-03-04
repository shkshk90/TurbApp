//
//  views_common.h
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#ifndef views_common_h
#define views_common_h

#define FHG_TAG_NOT_HANDLED do { \
[NSException raise:@"TagNotHandledException" \
format:@"[%s:%d %s]: Tag is not handled", \
__FILENAME__, __LINE__, __FUNCTION__]; \
} while(NO);

@protocol FHGViewsProtocol <NSObject>

- (id)initWithContentView:(UIView *const)superView;
- (UIView *)viewWithTag:(const NSInteger)tag;
- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector;

@end

#endif /* views_common_h */
