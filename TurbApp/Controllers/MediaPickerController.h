//
//  MediaPickerViewController.h
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;
@protocol FHGMediaPickerControllerDelegate;

@interface FHGMediaPickerController : UIViewController

@property (nonatomic, weak) id <FHGMediaPickerControllerDelegate> delegate;

@property (strong, nonatomic) UIColor                   *pickerTextColor;
@property (strong, nonatomic) UINavigationController    *navigationController;
@property (strong, nonatomic) NSArray                   *smartCollections;
@property (strong, nonatomic) NSArray                   *mediaTypes;
@property (strong, nonatomic) UIColor                   *pickerBackgroundColor;
@property (strong, nonatomic) NSString                  *pickerFontName;

@property (readonly, nonatomic) CGFloat                 pickerFontNormalSize;
@property (readonly, nonatomic) CGFloat                 pickerFontHeaderSize;
@property (readonly, nonatomic) UIStatusBarStyle        pickerStatusBarStyle;

@property (nonatomic) NSInteger colsInPortrait;
@property (nonatomic) NSInteger colsInLandscape;
@property (nonatomic) CGFloat   minimumInteritemSpacing;

@property (strong, nonatomic) PHAsset                   *videoAsset;

/**
 *  Managing Asset Selection
 */
- (void)selectAsset:(PHAsset *)asset;
- (void)deselectAsset:(PHAsset *)asset;

/**
 *  User finish Actions
 */
- (void)dismiss:(id)sender;
- (void)finishPickingAssets:(id)sender;

@end



@protocol FHGMediaPickerControllerDelegate <NSObject>
/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset An array containing picked PHAssets objects.
 */

- (void)assetsPickerController:(FHGMediaPickerController *)picker didFinishPickingAssets:(PHAsset *)asset;


@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *  @param picker The controller object managing the assets picker interface.
 */
- (void)assetsPickerControllerDidCancel:(FHGMediaPickerController *)picker;

@end

NS_ASSUME_NONNULL_END
