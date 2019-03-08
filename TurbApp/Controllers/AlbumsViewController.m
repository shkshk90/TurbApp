//
//  AlbumsViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 06.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

@import Photos;

#import "MediaPickerController.h"
#import "AlbumsViewController.h"
#import "GridViewController.h"
#import "../Views/AlbumsViewCell.h"
#import "../Views/GridViewCell.h"
//#import "../../Views/MediaPickerView/AlbumsViewCell.h"
//#import "../../Views/MediaPickerView/GridViewCell.h"

const CGSize kPopoverContentSize    = {480, 720};
const int    kAlbumRowHeight        = 90;
const int    kAlbumLeftToImageSpace = 10;
const int    kAlbumImageToTextSpace = 21;
const float  kAlbumGradientHeight   = 20.0f;
const CGSize kAlbumThumbnailSize1   = {70.0f , 70.0f};
const CGSize kAlbumThumbnailSize2   = {66.0f , 66.0f};
const CGSize kAlbumThumbnailSize3   = {62.0f , 62.0f};

@interface FHGAlbumsViewController () <PHPhotoLibraryChangeObserver>

@property (weak, nonatomic)   FHGMediaPickerController *picker;

//@property (strong, nonatomic) NSArray *collectionsFetchResults;
//@property (strong, nonatomic) NSArray *collectionsLocalizedTitles;
//@property (strong, nonatomic) NSArray *collectionsFetchResultsAssets;
//@property (strong, nonatomic) NSArray *collectionsFetchResultsTitles;
//@property (weak, nonatomic)   FHGMediaPickerController *picker;
//@property (strong, nonatomic) PHCachingImageManager     *imageManager;

@end

@implementation FHGAlbumsViewController {
@private NSArray *_collectionsFetchResults;
@private NSArray *_collectionsLocalizedTitles;
@private NSArray *_collectionsFetchResultsAssets;
@private NSArray *_collectionsFetchResultsTitles;
@private PHCachingImageManager     *_imageManager;
}

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.preferredContentSize = kPopoverContentSize;
    }
    
    return self;
}

static NSString * const AllPhotosReuseIdentifier = @"AllPhotosCell";
static NSString * const CollectionCellReuseIdentifier = @"CollectionCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = _picker.pickerBackgroundColor;
    
    _imageManager = [[PHCachingImageManager alloc] init];
    
    // Table view aspect
    self.tableView.rowHeight = kAlbumRowHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Buttons
    //NSDictionary* barButtonItemAttributes = @{NSFontAttributeName: [UIFont fontWithName:_picker.pickerFontName size:_picker.pickerFontHeaderSize]};
    
    NSString *cancelTitle = @"Cancel"; //NSLocalizedStringFromTableInBundle(@"picker.navigation.cancel-button",  @"FHGMediaPicker", [NSBundle bundleForClass:FHGMediaPickerController.class], @"Cancel");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:cancelTitle
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self.picker
                                                                            action:@selector(dismiss:)];
    
    // Bottom toolbar
    self.toolbarItems = self.picker.toolbarItems;
    
    // Title
    self.title = @"Videos";
    
    // Fetch PHAssetCollections:
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    _collectionsFetchResults = @[topLevelUserCollections, smartAlbums];
    _collectionsLocalizedTitles = @[@"Collections", @"Albums", @"Albums", @"Smart albums", @"FHGMediaPicker2", @"??xy"];
    //@[NSLocalizedStringFromTableInBundle(@"picker.table.user-albums-header",  @"FHGMediaPicker", [NSBundle bundleForClass:FHGMediaPickerController.class], @"Albums"), NSLocalizedStringFromTableInBundle(@"picker.table.smart-albums-header",  @"FHGMediaPicker", [NSBundle bundleForClass:FHGMediaPickerController.class], @"Smart Albums")];
    
    [self updateFetchResults];
    
    // Register for changes
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //    [self.tableView reloadData];
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    //[self.tableView layoutSubviews];
    //    [self.tableView reloadData];
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.picker.pickerStatusBarStyle;
}

- (void)selectAllAlbumsCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

-(void)updateFetchResults
{
    //What I do here is fetch both the albums list and the assets of each album.
    //This way I have acces to the number of items in each album, I can load the 3
    //thumbnails directly and I can pass the fetched result to the gridViewController.
    
    _collectionsFetchResultsAssets = nil;
    _collectionsFetchResultsTitles = nil;
    
    //Fetch PHAssetCollections:
    PHFetchResult *topLevelUserCollections = [_collectionsFetchResults objectAtIndex:0];
    PHFetchResult *smartAlbums = [_collectionsFetchResults objectAtIndex:1];
    
    //All album: Sorted by descending creation date.
    NSMutableArray *allFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *allFetchResultLabel = [[NSMutableArray alloc] init];
    {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
        [allFetchResultArray addObject:assetsFetchResult];
        [allFetchResultLabel addObject:@"All videos"];
    }
    
    //User albums:
    NSMutableArray *userFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *userFetchResultLabel = [[NSMutableArray alloc] init];
    for(PHCollection *collection in topLevelUserCollections)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Albums collections are allways PHAssetCollectionType=1 & PHAssetCollectionSubtype=2
            
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            [userFetchResultArray addObject:assetsFetchResult];
            [userFetchResultLabel addObject:collection.localizedTitle];
        }
    }
    
    
    //Smart albums: Sorted by descending creation date.
    NSMutableArray *smartFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *smartFetchResultLabel = [[NSMutableArray alloc] init];
    for(PHCollection *collection in smartAlbums)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Smart collections are PHAssetCollectionType=2;
            if(self.picker.smartCollections && [self.picker.smartCollections containsObject:@(assetCollection.assetCollectionSubtype)])
            {
                PHFetchOptions *options = [[PHFetchOptions alloc] init];
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                
                PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                if(assetsFetchResult.count>0)
                {
                    [smartFetchResultArray addObject:assetsFetchResult];
                    [smartFetchResultLabel addObject:collection.localizedTitle];
                }
            }
        }
    }
    
    _collectionsFetchResultsAssets= @[allFetchResultArray,userFetchResultArray,smartFetchResultArray];
    _collectionsFetchResultsTitles= @[allFetchResultLabel,userFetchResultLabel,smartFetchResultLabel];
}


#pragma mark - Accessors

- (FHGMediaPickerController *)picker
{
    return (FHGMediaPickerController *)self.navigationController.parentViewController;
}


#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _collectionsFetchResultsAssets.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    PHFetchResult *fetchResult = _collectionsFetchResultsAssets[section];
    return fetchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const CellIdentifier = @"Cell";
    
    FHGAlbumsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FHGAlbumsViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    // Set the label
    cell.mainLabel.font = [UIFont fontWithName:self.picker.pickerFontName size:self.picker.pickerFontHeaderSize];
    cell.mainLabel.text = (_collectionsFetchResultsTitles[indexPath.section])[indexPath.row];
    cell.mainLabel.textColor = self.picker.pickerTextColor;
    
    // Retrieve the pre-fetched assets for this album:
    PHFetchResult *assetsFetchResult = (_collectionsFetchResultsAssets[indexPath.section])[indexPath.row];
    
    // Display the number of assets
    cell.detailLabel.font = [UIFont fontWithName:self.picker.pickerFontName size:self.picker.pickerFontNormalSize];
    cell.detailLabel.text = [self tableCellSubtitle:assetsFetchResult];
    cell.detailLabel.textColor = [UIColor grayColor];
    
    // Set the 3 images (if exists):
    if ([assetsFetchResult count] > 0) {
        CGFloat scale = [UIScreen mainScreen].scale;
        
        //Compute the thumbnail pixel size:
        CGSize tableCellThumbnailSize1 = CGSizeMake(kAlbumThumbnailSize1.width*scale, kAlbumThumbnailSize1.height*scale);
        PHAsset *asset = assetsFetchResult[0];
        [cell setVideoLayout:(asset.mediaType==PHAssetMediaTypeVideo)];
        [_imageManager requestImageForAsset:asset
                                 targetSize:tableCellThumbnailSize1
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if (cell.tag == currentTag) {
                                      cell.imageView1.image = result;
                                  }
                              }];
        
        // Second & third images:
        // TODO: Only preload the 3pixels height visible frame!
        if ([assetsFetchResult count] > 1) {
            //Compute the thumbnail pixel size:
            CGSize tableCellThumbnailSize2 = CGSizeMake(kAlbumThumbnailSize2.width*scale, kAlbumThumbnailSize2.height*scale);
            PHAsset *asset = assetsFetchResult[1];
            [_imageManager requestImageForAsset:asset
                                     targetSize:tableCellThumbnailSize2
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      if (cell.tag == currentTag) {
                                          cell.imageView2.image = result;
                                      }
                                  }];
        } else {
            cell.imageView2.image = nil;
        }
        
        if ([assetsFetchResult count] > 2) {
            CGSize tableCellThumbnailSize3 = CGSizeMake(kAlbumThumbnailSize3.width*scale, kAlbumThumbnailSize3.height*scale);
            PHAsset *asset = assetsFetchResult[2];
            [_imageManager requestImageForAsset:asset
                                     targetSize:tableCellThumbnailSize3
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      if (cell.tag == currentTag) {
                                          cell.imageView3.image = result;
                                      }
                                  }];
        } else {
            cell.imageView3.image = nil;
        }
    } else {
        [cell setVideoLayout:NO];
        cell.imageView3.image = [UIImage imageNamed:@"PickerEmptyFolder"];
        cell.imageView2.image = [UIImage imageNamed:@"PickerEmptyFolder"];
        cell.imageView1.image = [UIImage imageNamed:@"PickerEmptyFolder"];
    }
    
    [cell setNeedsLayout];
    //    [cell layoutSubviews];
    [cell layoutIfNeeded];
    
    [cell needsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Init the GMGridViewController
    FHGGridViewController *gridViewController = [[FHGGridViewController alloc] initWithPicker:[self picker]];
    // Set the title
    gridViewController.title = cell.textLabel.text;
    // Use the prefetched assets!
    gridViewController.assetsFetchResults = [[_collectionsFetchResultsAssets objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    // Remove selection so it looks better on slide in
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    // Push GMGridViewController
    [self.navigationController pushViewController:gridViewController animated:YES];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.contentView.backgroundColor = [UIColor clearColor];
    header.backgroundView.backgroundColor = [UIColor clearColor];
    
    // Default is a bold font, but keep this styled as a normal font
    header.textLabel.font = [UIFont fontWithName:self.picker.pickerFontName size:self.picker.pickerFontNormalSize];
    header.textLabel.textColor = self.picker.pickerTextColor;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //Tip: Returning nil hides the section header!
    
    NSString *title = nil;
    if (section > 0) {
        // Only show title for non-empty sections:
        PHFetchResult *fetchResult = _collectionsFetchResultsAssets[section];
        if (fetchResult.count > 0) {
            title = _collectionsLocalizedTitles[section - 1];
        }
    }
    return title;
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *updatedCollectionsFetchResults = nil;
        
        for (PHFetchResult *collectionsFetchResult in self->_collectionsFetchResults) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            if (changeDetails) {
                if (!updatedCollectionsFetchResults) {
                    updatedCollectionsFetchResults = [self->_collectionsFetchResults mutableCopy];
                }
                [updatedCollectionsFetchResults replaceObjectAtIndex:[self->_collectionsFetchResults indexOfObject:collectionsFetchResult] withObject:[changeDetails fetchResultAfterChanges]];
            }
        }
        
        // This only affects to changes in albums level (add/remove/edit album)
        if (updatedCollectionsFetchResults) {
            self->_collectionsFetchResults = updatedCollectionsFetchResults;
        }
        
        // However, we want to update if photos are added, so the counts of items & thumbnails are updated too.
        // Maybe some checks could be done here , but for now is OKey.
        [self updateFetchResults];
        [self.tableView reloadData];
        
    });
}



#pragma mark - Cell Subtitle

- (NSString *)tableCellSubtitle:(PHFetchResult*)assetsFetchResult
{
    // Just return the number of assets. Album app does this:
    return [NSString stringWithFormat:@"%ld", (long)[assetsFetchResult count]];
}


//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
