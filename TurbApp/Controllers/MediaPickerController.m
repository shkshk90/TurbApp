//
//  MediaPickerViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

@import Photos;

#import "MediaPickerController.h"
#import "AlbumsViewController.h"

@interface FHGMediaPickerController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
@private NSString *_pickerBoldFontName;
    
@private UIColor  *_toolbarTintColor;
@private UIColor  *_toolbarTextColor;
@private UIColor  *_toolbarBarTintColor;
    
@private UIColor  *_navigationBarBackgroundColor;
@private UIColor  *_navigationBarTextColor;
@private UIColor  *_navigationBarTintColor;
    
@private UIAlertController *_alertController;
    
@private BOOL    _aVideoIsSelected;
}
//
//@property (strong, nonatomic) NSString *pickerBoldFontName;
//
//@property (strong, nonatomic) UIColor  *toolbarTintColor;
//@property (strong, nonatomic) UIColor  *toolbarTextColor;
//@property (strong, nonatomic) UIColor  *toolbarBarTintColor;
//
//@property (strong, nonatomic) UIColor  *navigationBarBackgroundColor;
//@property (strong, nonatomic) UIColor  *navigationBarTextColor;
//@property (strong, nonatomic) UIColor  *navigationBarTintColor;
//
//@property (strong, nonatomic) UIAlertController *alertController;
//
//@property (readonly, nonatomic) BOOL    aVideoIsSelected;




@end

@implementation FHGMediaPickerController

- (instancetype)init
{
    if (self = [super init]) {
        _aVideoIsSelected = NO;
        
        _colsInPortrait = 3;
        _colsInLandscape = 5;
        _minimumInteritemSpacing = 2.0;
        
        _smartCollections = @[@(PHAssetCollectionSubtypeSmartAlbumFavorites),
                              @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                              @(PHAssetCollectionSubtypeSmartAlbumVideos),
                              @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
                              @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
                              @(PHAssetCollectionSubtypeSmartAlbumBursts),
                              @(PHAssetCollectionSubtypeSmartAlbumPanoramas)];
        // If you don't want to show smart collections, just put _customSmartCollections to nil;
        //_customSmartCollections=nil;
        
        // Which media types will display
        _mediaTypes = @[@(PHAssetMediaTypeVideo)];
        
        self.preferredContentSize = kPopoverContentSize;
        
        // UI Customisation
        _pickerBackgroundColor = [UIColor whiteColor];
        _pickerTextColor = [UIColor darkTextColor];
        _pickerFontName = @"HelveticaNeue";
        _pickerBoldFontName = @"HelveticaNeue-Bold";
        _pickerFontNormalSize = 14.0f;
        _pickerFontHeaderSize = 17.0f;
        
        _navigationBarBackgroundColor = [UIColor whiteColor];
        _navigationBarTextColor = [UIColor darkTextColor];
        _navigationBarTintColor = nil; //[UIColor blueColor];
        
        _toolbarBarTintColor = [UIColor whiteColor];
        _toolbarTextColor = [UIColor darkTextColor];
        _toolbarTintColor = [UIColor darkTextColor];
        
        _pickerStatusBarStyle = UIStatusBarStyleDefault;
        
        _alertController = nil; // TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
        
        [self setupNavigationController];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Ensure nav and toolbar customisations are set. Defaults are in place, but the user may have changed them
    self.view.backgroundColor = _pickerBackgroundColor;
    
    _navigationController.toolbar.translucent = YES;
    _navigationController.toolbar.barTintColor = _toolbarBarTintColor;
    _navigationController.toolbar.tintColor = _toolbarTintColor;
    //    NSLog(@"%d", [_navigationController.toolbar.subviews count]);
    //    [(UIView*)[_navigationController.toolbar.subviews objectAtIndex:0] setAlpha:0.75f];  // URGH - I know!
    
    _navigationController.navigationBar.backgroundColor = _navigationBarBackgroundColor;
    _navigationController.navigationBar.tintColor = _navigationBarTintColor;
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName : _navigationBarTextColor};
    _navigationController.navigationBar.titleTextAttributes = attributes;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _pickerStatusBarStyle;
}


#pragma mark - Setup Navigation Controller

- (void)setupNavigationController
{
    FHGAlbumsViewController *albumsViewController = [[FHGAlbumsViewController alloc] init];
    _navigationController = [[UINavigationController alloc] initWithRootViewController:albumsViewController];
    _navigationController.delegate = self;
    
    _navigationController.navigationBar.translucent = YES;
    [_navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    _navigationController.navigationBar.shadowImage = [UIImage new];
    
    [_navigationController willMoveToParentViewController:self];
    [_navigationController.view setFrame:self.view.frame];
    [self.view addSubview:_navigationController.view];
    [self addChildViewController:_navigationController];
    [_navigationController didMoveToParentViewController:self];
}



#pragma mark - Select / Deselect Asset

- (void)selectAsset:(PHAsset *)asset
{
    //[self.selectedAssets insertObject:asset atIndex:self.selectedAssets.count];
    _videoAsset = asset;
    
    [self finishPickingAssets:self];
    
    if (!_aVideoIsSelected) {
        _aVideoIsSelected = YES;
        [self updateDoneButton];
    }
}

- (void)deselectAsset:(PHAsset *)asset
{
    _aVideoIsSelected = NO;
    [self updateDoneButton];
}

- (void)updateDoneButton
{
    UINavigationController *nav = (UINavigationController *)self.childViewControllers[0];
    for (UIViewController *viewController in nav.viewControllers) {
        viewController.navigationItem.rightBarButtonItem.enabled = _aVideoIsSelected;
    }
}


#pragma mark - User finish Actions

- (void)dismiss:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)]) {
        [self.delegate assetsPickerControllerDidCancel:self];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)finishPickingAssets:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssets:)]) {
        [self.delegate assetsPickerController:self didFinishPickingAssets:self.videoAsset];
    }
}


#pragma mark - Toolbar Items

- (NSDictionary *)toolbarTitleTextAttributes {
    return @{NSForegroundColorAttributeName : _toolbarTextColor,
             NSFontAttributeName : [UIFont fontWithName:_pickerFontName size:_pickerFontHeaderSize]};
}

- (UIBarButtonItem *)titleButtonItem
{
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithTitle:nil
                                                              style:UIBarButtonItemStylePlain
                                                             target:nil
                                                             action:nil];
    
    NSDictionary *attributes = [self toolbarTitleTextAttributes];
    [title setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [title setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    [title setEnabled:NO];
    
    return title;
}

- (UIBarButtonItem *)spaceButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (NSArray *)toolbarItems
{
    UIBarButtonItem *title  = [self titleButtonItem];
    UIBarButtonItem *space  = [self spaceButtonItem];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    [items addObject:space];
    [items addObject:title];
    [items addObject:space];
    
    return [NSArray arrayWithArray:items];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
