//
//  UIViewController+UIViewController_FHGViewAddition.h
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../Views/views_common.h"

#define FHG_SHOW_ERROR_POPUP(POPUP_MSG, CONSOLE_MSG, ...) do { \
    UIAlertController *const alert = [UIAlertController alertControllerWithTitle:@"Error" \
        message:POPUP_MSG preferredStyle:UIAlertControllerStyleAlert]; \
    [alert addAction: \
        [UIAlertAction actionWithTitle:@"OK"  style:UIAlertActionStyleDefault \
            handler:^(UIAlertAction *action) { \
                NSLog(@"[%s:%d] " CONSOLE_MSG, __FILENAME__, __LINE__, __VA_ARGS__); \
            } ]]; \
    [self presentViewController:alert animated:YES completion:nil]; \
} while (NO)


NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (UIViewControllerFHGViewAddition)

- (void)fhg_addMainSubView:(UIView<FHGViewsProtocol> *const)subView;

@end


NS_INLINE CGRect
fhgc_calculateFinalRoi(const CGSize viewSize, const CGSize videoSize, const CGRect roiFrame)
{
    const CGFloat videoHeight  = (CGFloat)videoSize.height;
    const CGFloat videoWidth   = (CGFloat)videoSize.width;
    
    const CGFloat scaledHeight = viewSize.height;
    const CGFloat scaledWidth  = viewSize.width;
    
    const CGFloat ratioForX    = videoWidth  / scaledWidth;
    const CGFloat ratioForY    = videoHeight / scaledHeight;
    
    
    const NSInteger frameSide   = (NSInteger)lround(roiFrame.size.width * ratioForX);   // Actual size in video pixels
    
    const NSInteger rem = frameSide % 128;
    const NSInteger roundedFrameSide = frameSide <= 128 ? 128 :
    ((rem >= 64) ? frameSide - rem + 128 : frameSide - rem);
    
    
    const CGRect roi = CGRectMake(roiFrame.origin.x    * ratioForX,
                                  roiFrame.origin.y    * ratioForY,
                                  (CGFloat)roundedFrameSide,
                                  (CGFloat)roundedFrameSide); // HERE ratio for x to get a square.
    
    return roi;
}

NS_ASSUME_NONNULL_END
