//
//  ViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "FirstScreenViewController.h"
#import "../common.h"
#import "../Views/FirstScreenView.h"

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
    
    _firstScreenView = [[FHGFirstScreenView alloc] initWithContentView:self.view];
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
    switch (sender.tag) {
        case FHGFirstScreenRecordButton:
            NSLog(@"Ying");
            break;
        case FHGFirstScreenVideoButton:
            NSLog(@"Yang");
            break;
    }
}




@end
