//
//  ViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "FirstScreenViewController.h"
#import "CameraMeasurementViewController.h"
#import "StorageMeasurementViewController.h"

#import "../common.h"
#import "../Views/FirstScreenView.h"
#import "../Views/FirstScreen_common.h"
#import "UIViewController+UIViewController_FHGViewAddition.h"


#pragma mark - Interface
@interface FHGFirstScreenViewController ()

@end

#pragma mark - Implementation
@implementation FHGFirstScreenViewController {
@private FHGFirstScreenView     *_firstScreenView;
}

#pragma mark - Super methods
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Hello from %s", __FILENAME__);
    
    // Do any additional setup after loading the view, typically from a nib.
    [self configureNavigation];
    
    //_firstScreenView = [[FHGFirstScreenView alloc] initWithContentView:self.view];
    _firstScreenView = [[FHGFirstScreenView alloc] init];
    
    [self fhg_addMainSubView:_firstScreenView];
    [_firstScreenView setButtonsTarget:self withSelector:@selector(routeView:)];
}

#pragma mark - Navigation
- (void)configureNavigation
{
    [self.navigationItem setTitle:@"TurbApp"];
}

#pragma mark - IBActions
- (IBAction)routeView:(UIButton *)sender
{
    UIViewController *nextController;
    switch (sender.tag) {
        case FHGTagFSVRecordButton:
            nextController = [[FHGCameraMeasurementViewController alloc] init];
            
            break;
            
        case FHGTagFSVVideoButton:
            nextController = [[FHGStorageMeasurementViewController alloc] init];
            
            break;
    }
    
    UINavigationController *const navigationController = [[UINavigationController alloc] initWithRootViewController:nextController];
    
    [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
    [navigationController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}




@end
