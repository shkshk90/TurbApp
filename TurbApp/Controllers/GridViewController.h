//
//  GridViewController.h
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FHGMediaPickerController;

@interface FHGGridViewController : UICollectionViewController

@property (strong) PHFetchResult *assetsFetchResults;

-(instancetype)initWithPicker:(FHGMediaPickerController *)picker;

@end

NS_ASSUME_NONNULL_END
