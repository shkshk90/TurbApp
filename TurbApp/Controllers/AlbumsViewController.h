//
//  AlbumsViewController.h
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern const CGSize  kPopoverContentSize;
extern const int     kAlbumRowHeight;
extern const int     kAlbumLeftToImageSpace;
extern const int     kAlbumImageToTextSpace;
extern const float   kAlbumGradientHeight;
extern const CGSize  kAlbumThumbnailSize1;
extern const CGSize  kAlbumThumbnailSize2;
extern const CGSize  kAlbumThumbnailSize3;

//static CGSize const kPopoverContentSize = {480, 720};
//static int kAlbumRowHeight = 90;
//static int kAlbumLeftToImageSpace = 10;
//static int kAlbumImageToTextSpace = 21;
//static float const kAlbumGradientHeight = 20.0f;
//static CGSize const kAlbumThumbnailSize1 = {70.0f , 70.0f};
//static CGSize const kAlbumThumbnailSize2 = {66.0f , 66.0f};
//static CGSize const kAlbumThumbnailSize3 = {62.0f , 62.0f};

@interface FHGAlbumsViewController : UITableViewController

- (void)selectAllAlbumsCell;

@end

NS_ASSUME_NONNULL_END
