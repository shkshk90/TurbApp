//
//  AlbumsViewCell.h
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface FHGAlbumsViewCell : UITableViewCell

@property (strong) PHFetchResult     *assetsFetchResults;
@property (strong) PHAssetCollection *assetCollection;

//The textViews
@property (strong, nonatomic) UILabel *mainLabel;
@property (strong, nonatomic) UILabel *detailLabel;

//The labels
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *infoLabel;
//The imageView
@property (strong, nonatomic) UIImageView *imageView1;
@property (strong, nonatomic) UIImageView *imageView2;
@property (strong, nonatomic) UIImageView *imageView3;
//Video additional information
@property (strong, nonatomic) UIImageView *videoIcon;
@property (strong, nonatomic) UIImageView *slowMoIcon;
@property (strong, nonatomic) UIView* gradientView;
@property (strong, nonatomic) CAGradientLayer *gradient;
//Selection overlay

- (void)setVideoLayout:(BOOL)isVideo;

@end

NS_ASSUME_NONNULL_END
