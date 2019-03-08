//
//  StorageMeasurementViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

@import Photos;

#import "StorageMeasurementViewController.h"
#import "ExperimentParametersViewController.h"
#import "RoiGestureHandler.h"
#import "MediaPickerController.h"
#import "../Views/StorageMeasurementView.h"
#import "../Views/StorageMeasurement_common.h"
#import "../common.h"
#import "UIViewController+UIViewController_FHGViewAddition.h"

#pragma mark - Interface
@interface FHGStorageMeasurementViewController () <FHGMediaPickerControllerDelegate, FHGProtocolExperimentParametersDelegate>

@end

#pragma mark - Implementation and Members
@implementation FHGStorageMeasurementViewController {
    
@private FHGStorageMeasurementView  *_contentView;
@private FHGRoiGestureHandler       *_gesturesHandler;
    
@private UITapGestureRecognizer     *_stepTwoTapGesture;
@private AVURLAsset                 *_videoURL;
    
@private dispatch_group_t            _dispatchGroup;
    
}

@synthesize experimentDataDict = _experimentDataDict;

#pragma mark - View methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureNavigation];
    
    _contentView = [[FHGStorageMeasurementView alloc] init];
    [self fhg_addMainSubView:_contentView];
    
    [_contentView setButtonsTarget:self withSelector:@selector(buttonsAction:)];
    
    
    _gesturesHandler =  [[FHGRoiGestureHandler alloc] initWithView:[_contentView viewWithTag:FHGTagSMVPreview] forROI:[_contentView roiLayer]];
    [_gesturesHandler enableTapOnlywithTarget:self action:@selector(pickVideoFromGallery)];
    
    [[_contentView roiLayer] setHidden:YES];
    
    
    _stepTwoTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchSettings)];
    [_stepTwoTapGesture setEnabled:NO];
    
    _dispatchGroup = dispatch_group_create();
}

#pragma mark - Navigatian methods
- (void)configureNavigation
{
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    [self.navigationItem setTitle:@"Parameters"];
    
    UIBarButtonItem *const barButton = [[UIBarButtonItem alloc]
                                        initWithImage:[[FHGStorageMeasurementView goBackImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(cancel)];

    
    const CGFloat imageSideInset = CGRectGetWidth( [UIScreen mainScreen].bounds) * 0.0625;
    
    [self.navigationItem setLeftBarButtonItem:barButton];
    [self.navigationItem.leftBarButtonItem setImageInsets:UIEdgeInsetsMake(0., -imageSideInset, 0., imageSideInset)];
}

- (IBAction)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Button Actions
- (IBAction)pickVideoFromGallery
{
    FHGMediaPickerController *const videoPicker = [[FHGMediaPickerController alloc] init];
    [videoPicker setDelegate:self];
    
    [self presentViewController:videoPicker animated:YES completion:nil];
}

- (IBAction)launchSettings
{
    FHGExperimentParametersViewController *const nextController  = [[FHGExperimentParametersViewController alloc] init];
    [nextController setDelegate:self];
    
    UINavigationController *const navigationController = [[UINavigationController alloc] initWithRootViewController:nextController];
    
    [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
    [navigationController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)buttonsAction:(UIButton *)sender
{
    const FHGTagStorageMeasurementButtonTags tag = (FHGTagStorageMeasurementButtonTags)sender.tag;
    
    switch (tag) {
        case FHGTagSMVResetButton :
            [self pickVideoFromGallery];
            
            return;
            
        case FHGTagSMVSettingsButton :
            [self launchSettings];
            
            NSLog(@"Settings");
            return;
            
        case FHGTagSMVLaunchButton :
            NSLog(@"Launch");
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
}

#pragma mark - MediaPickerDelegate Methods
- (IBAction)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)assetsPickerController:(FHGMediaPickerController *)picker didFinishPickingAssets:(PHAsset *)asset
{
    __block AVURLAsset *selectedVideoURL;
    
    PHVideoRequestOptions *const options = [[PHVideoRequestOptions alloc] init];
    [options setVersion:PHVideoRequestOptionsVersionOriginal];
    
    dispatch_group_enter(_dispatchGroup);
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        if ([asset isKindOfClass:[AVURLAsset class]])
            selectedVideoURL = (AVURLAsset *)asset; //[(AVURLAsset *)asset URL];
            //self->_videoURL = [(AVURLAsset *)asset URL];
        
        dispatch_group_leave(self->_dispatchGroup);
    }];
    
    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([self checkSelectedVideo:selectedVideoURL])
        [self updateViewToStepTwo:selectedVideoURL];
}

#pragma mark - Step One methods
- (BOOL)checkSelectedVideo:(AVURLAsset *const)selectedVideoURL
{
    if (selectedVideoURL == nil)
        return NO;
    
    // Check if resource is reachable
    NSError  *err = nil;
    if ([[selectedVideoURL URL] checkResourceIsReachableAndReturnError:&err] == NO) {
        FHG_SHOW_ERROR_POPUP(@"There was an error selecting video.",
                             @"Error in selecting video: %@.", [err localizedDescription]);
        return NO;
    }
    NSLog(@"Video is reachable.");
    
    // Check if track contains video
    if ([selectedVideoURL tracksWithMediaCharacteristic:AVMediaCharacteristicVisual] == nil) {
        FHG_SHOW_ERROR_POPUP(@"Selected file is not a video.",
                             @"Media is not a video: %@",
                             [[selectedVideoURL availableMediaCharacteristicsWithMediaSelectionOptions]
                              description]);
        return NO;
    }
    NSLog(@"File contains a video");
    
    // Check if duration is enough
    if (CMTimeGetSeconds([selectedVideoURL duration]) < kFHGMinimumNumberOfSeconds) {
        NSString *const popupMessage = [NSString stringWithFormat:@"Video is too short.\nPlease select a video longer than %.f seconds.",
                                        kFHGMinimumNumberOfSeconds];
        FHG_SHOW_ERROR_POPUP(popupMessage,
                             @"Error: video is too short: %f.",
                             CMTimeGetSeconds([selectedVideoURL duration]));
        return NO;
    }
    NSLog(@"Video is longer than %f seconds.", kFHGMinimumNumberOfSeconds);
    
    return YES;
}

- (UIImage *)getFirstFrameImage:(AVURLAsset *const)selectedVideoURL
{
    __block UIImage *firstFrame = nil;
    __block NSError *err        = nil;
    
    // Get first frame
    dispatch_group_enter(_dispatchGroup);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        AVAssetImageGenerator *const imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:selectedVideoURL];
        
        [imageGenerator setAppliesPreferredTrackTransform:YES];
        
        NSError *err;
        
        const CGImageRef previewImage = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(1., 10) actualTime:NULL error:&err];
        firstFrame = [UIImage imageWithCGImage:previewImage];
        
        CGImageRelease(previewImage);
        
        
        dispatch_group_leave(self->_dispatchGroup);
    });
    
    dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
    if (err != nil) {
        FHG_SHOW_ERROR_POPUP(@"Couldn't create preview image", @"Error is %@", [err localizedDescription]);
        firstFrame =  nil;
    }
    
    return firstFrame;
}

- (void)updateViewToStepTwo:(AVURLAsset *const)selectedVideoURL
{
    UIImage *const firstFrame = [self getFirstFrameImage:selectedVideoURL];
    
    if (firstFrame == nil)
        return;
    
    _videoURL  = selectedVideoURL;
    _videoSize = [self getVideoSizeFromAsset:selectedVideoURL];
    
    UIImageView *const previewImageView = (UIImageView *)[_contentView viewWithTag:FHGTagSMVPreview];
    
    [previewImageView setImage:firstFrame];
    
    if ([_contentView roiLayer].hidden == NO)
        return;
    
    UIButton *const reselectButton = (UIButton *)[_contentView viewWithTag:FHGTagSMVResetButton];
    UILabel  *const stepTwoLabel   =  (UILabel *)[_contentView viewWithTag:FHGTagSMVStepTwo];
    UIButton *const settingsButton = (UIButton *)[_contentView viewWithTag:FHGTagSMVSettingsButton];
    
    [reselectButton setHidden:NO];
    [reselectButton setEnabled:YES];
    
    [stepTwoLabel setUserInteractionEnabled:YES];
    [stepTwoLabel setTextColor:[UIColor blackColor]];
    [stepTwoLabel addGestureRecognizer:_stepTwoTapGesture];
    
    
    [settingsButton setEnabled:YES];
    [settingsButton setTintColor:[UIColor redColor]];
    
    [_contentView showRoiLayer];
    [_stepTwoTapGesture setEnabled:YES];
    [_gesturesHandler enableAllGestures];
}

- (CGSize)getVideoSizeFromAsset:(AVURLAsset *const)URL
{
    __block CGSize dimensions;
    
    dispatch_group_enter(_dispatchGroup);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        dimensions = [[[URL tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
        dispatch_group_leave(self->_dispatchGroup);
        
        FHG_NS_LOG(@"Video Size: x = %f, y = %f", dimensions.width, dimensions.height);
    });
    
    dispatch_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    
    return dimensions;
}

#pragma mark - Step Two Methods
- (void)updateViewToSTepThree
{
    UILabel  *const stepThreeLabel = (UILabel  *)[_contentView viewWithTag:FHGTagSMVStepThree];
    UIButton *const settingsButton = (UIButton *)[_contentView viewWithTag:FHGTagSMVSettingsButton];
    UIButton *const launchButton   = (UIButton *)[_contentView viewWithTag:FHGTagSMVLaunchButton];
    
    [stepThreeLabel setTextColor:[UIColor blackColor]];
    
    [settingsButton setTintColor:[UIColor greenColor]];
    [launchButton setEnabled:YES];
}

#pragma mark - Experiment Data Dictionary methods
- (void)setExperimentDataDict:(NSDictionary *)dict
{
    _experimentDataDict = dict;
    
    FHG_NS_LOG(@"%@", dict);
    if (dict != nil && [dict count] > 0)
        [self updateViewToSTepThree];
    else
        NSLog(@"Meeeeh");
}
    
////    UIImageView *const previewImageView = (UIImageView *)[_contentView viewWithTag:FHGTagSMVPreview];
////    CALayer     *const roiLayer         = [_contentView roiLayer];
//
//    const BOOL videoIsOk = [self updateImageView];
//
//    if ([_contentView roiLayer].hidden == NO)
//        return;
//
//    UIButton *const reselectButton = (UIButton *)[_contentView viewWithTag:FHGTagSMVResetButton];
//    UILabel  *const stepTwoLabel   =  (UILabel *)[_contentView viewWithTag:FHGTagSMVStepTwo];
//    UIButton *const settingsButton = (UIButton *)[_contentView viewWithTag:FHGTagSMVSettingsButton];
//
//    [reselectButton setHidden:NO];
//    [reselectButton setEnabled:YES];
//
//    [stepTwoLabel setBackgroundColor:[UIColor blackColor]];
//
//    [settingsButton setEnabled:YES];
//    [settingsButton setBackgroundColor:[UIColor redColor]];
//
//    [_gesturesHandler enableAllGestures];
//    [_contentView showRoiLayerInsideFrame];
//}

//- (BOOL)updateImageView
//{
//    NSLog(@"[%s:%d]" @"HI", __FILENAME__, __LINE__);
////    FHG_SHOW_ERROR_POPUP(@"Testing the Macro", @"Macro works");
//
//    UIImageView *const previewImageView = (UIImageView *)[_contentView viewWithTag:FHGTagSMVPreview];
//
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//        AVAssetImageGenerator *const imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self->_videoURL];
//
//        [imageGenerator setAppliesPreferredTrackTransform:YES];
//
//        NSError *err;
//
//        const CGImageRef previewImage = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(1., 10) actualTime:NULL error:&err];
//        UIImage *const firstFrame = [UIImage imageWithCGImage:previewImage];
//
//        CGImageRelease(previewImage);
//
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            if (err != nil) {
//                FHG_SHOW_ERROR_POPUP(@"Couldn't create preview image", @"Error is %@", [err localizedDescription]);
//            }
//            else {
//                [previewImageView setImage:firstFrame];
//            }
//        });
//    });
//
//
//
//
//
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_videoURL options:nil];
//    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
//
//    imageGenerator.appliesPreferredTrackTransform = YES;
//
//    CGImageRef firstFrameCGImage = [imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil];
//    UIImage *firstFrame = [UIImage imageWithCGImage:firstFrameCGImage];
//
//    if (firstFrame == Nil || firstFrameCGImage == NULL)
//        [NSException raise:@"FirstFrameIsNullException" format:@"First frame is null."];
//
//    CGImageRelease(firstFrameCGImage);
//
//
//    if (_hasNoVideo) {
//        //  TODO
//        _hasNoVideo = NO;
//
//        _reselectButton.hidden = NO;
//        _reselectButton.enabled = YES;
//
//        NSArray *viewsToRemove = [_videoImageView subviews];
//        for (UIView *subView in viewsToRemove)
//            [subView removeFromSuperview];
//
//        [_videoImageView.layer addSublayer:_roiLayer];
//        //        [_videoImageView setUserInteractionEnabled:NO];
//        //        [_videoImageView addGestureRecognizer:_tapGestureRecognizer];
//        //        [_videoImageView addGestureRecognizer:_pinchGestureRecognizer];
//
//        [_tapGestureRecognizer removeTarget:self action:@selector(selectVideoFromPhotoLibrary:)];
//        [_tapGestureRecognizer addTarget:self action:@selector(changeRoiLocation:)];
//
//        [_pinchGestureRecognizer setEnabled:YES];
//        [_panGestureRecognizer setEnabled:YES];
//    }
//
//    [_videoImageView setImage:firstFrame];
//    _metadataOfVideo      = [self countVideoFrames:asset];
//
//    [_valuesButton setTintColor:[UIColor redColor]];
//    _experimentDataDictionary = @{};
//
//}

//- (IBAction) cnSquaredButtonClicked:(UIButton *)sender
//{
//    const CGRect roi = calculateFinalRoi(_videoImageView.frame.size, _metadataOfVideo.size, _roiLayer.frame);
//    
//    [_cnSquaredButton setEnabled:NO];
//    
//    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
//    [_videoSelectorStackView addArrangedSubview:progressView];
//    
//    
//    FHGCoreProcessor *processor = [[FHGCoreProcessor alloc] init];
//    
//    [processor setRoiFrame:roi];
//    [processor setVideoMetadata:&_metadataOfVideo];
//    // For Testing
//    _experimentDataDictionary = @{
//                                  @"Distance" : [NSNumber numberWithDouble:1.],
//                                  @"Aperture" : [NSNumber numberWithDouble:1.],
//                                  
//                                  @"Pixels"   : [NSNumber numberWithInteger:1],
//                                  @"Meters"   : [NSNumber numberWithDouble:1.],
//                                  
//                                  @"Block"    : [NSNumber numberWithInteger:128],
//                                  @"Frame"    : [NSNumber numberWithInteger:100],
//                                  
//                                  @"Count"    : [NSNumber numberWithLong:50],
//                                  @"Start"    : [NSNumber numberWithLong:10],
//                                  };
//    [processor setExperimentData:_experimentDataDictionary];
//    
//    [processor setVideoUrl:_videoURL];
//    
//#if TEST_IMAGE == 1
//    [processor setControllerStackView:_videoSelectorStackView];
//    //    UIStackView *blockStack = [[UIStackView alloc] init];
//    ////        initWithArrangedSubviews:@[
//    ////      [[UIImageView alloc] initWithImage:nil],
//    ////      [[UIImageView alloc] initWithImage:nil],
//    ////      [[UIImageView alloc] initWithImage:nil],
//    ////      [[UIImageView alloc] initWithImage:nil],
//    ////      [[UIImageView alloc] initWithImage:nil],
//    ////      [[UIImageView alloc] initWithImage:nil],
//    ////      [[UIImageView alloc] initWithImage:nil]
//    ////      ]];
//    //
//    //    [blockStack setSpacing:5.];
//    ////    [blockStack setDistribution:UIStackViewDistributionFillEqually];
//    ////    [blockStack setAxis:UILayoutConstraintAxisVertical];
//    //
//    //    UIImageView *newView = [[UIImageView alloc] initWithImage:nil];
//    //    [_videoSelectorStackView addArrangedSubview:newView];
//    //    [_videoSelectorStackView addArrangedSubview:blockStack];
//    //
//    //    [processor setCroppedImageView:newView];
//    //    [processor setCroppedStackView:blockStack];
//#endif
//    [processor play];
//    
//    
//    //[self performSegueWithIdentifier:@"FHGProgressSegue" sender:sender];
//    
//    
//    
//#if TEST_ROI == 1
//    //    const CGFloat videoHeight = (CGFloat)_metadataOfVideo.height;
//    //    const CGFloat videoWidth  = (CGFloat)_metadataOfVideo.width;
//    //
//    //    const CGFloat imageViewHeight = _videoImageView.frame.size.height;
//    //    const CGFloat imageViewWidth  = _videoImageView.frame.size.width;
//    //
//    //    const CGFloat ratioForX = videoWidth / imageViewWidth;
//    //    const CGFloat ratioForY = videoHeight / imageViewHeight;
//    //
//    //    //    NSLog(@"%f, %f", _videoImageView.image.size.height, _videoImageView.image.size.width);
//    //
//    //    const CGRect roi = CGRectMake(_roiLayer.frame.origin.x    * ratioForX,
//    //                                  _roiLayer.frame.origin.y    * ratioForY,
//    //                                  _roiLayer.frame.size.width  * ratioForX,
//    //                                  _roiLayer.frame.size.height * ratioForX); // HERE ratio for x to get a square.
//    
//    //    NSLog(@"%f, %f", ratioForX, ratioForX);
//    NSLog(@"%f, %f, %f, %f", roi.origin.x, roi.origin.y, roi.size.width, roi.size.height);
//    
//    
//    CGImageRef imageRef = CGImageCreateWithImageInRect([_videoImageView.image CGImage], roi);
//    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
//    CGImageRelease(imageRef);
//    
//    UIImageView *newView = [[UIImageView alloc] initWithImage:cropped];
//    
//    [_videoSelectorStackView addArrangedSubview:newView];
//    
//    NSLog(@"I:  %f, %f", newView.image.size.height, newView.image.size.width);
//    NSLog(@"F:  %f, %f", newView.frame.size.height, newView.frame.size.width);
//    
//    
//    
//    //    NSLog(@"%f, %f,   %f, %f,   %f, %f,   %f, %f",
//    //          _videoImageView.frame.size.height, _videoImageView.frame.size.width,
//    //          height, width,
//    //          _videoImageView.frame.size.height / height,
//    //          _videoImageView.frame.size.width  / width,
//    //          _videoImageView.frame.size.height / width,
//    //          _videoImageView.frame.size.width  / height);
//    
//#endif // TEST_ROI
//}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
