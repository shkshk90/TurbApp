//
//  StorageMeasurementViewController.m
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "StorageMeasurementViewController.h"
#import "../Views/StorageMeasurementView.h"
#import "../Views/StorageMeasurement_common.h"
#import "../common.h"

#pragma mark - Interface
@interface FHGStorageMeasurementViewController ()

@end

#pragma mark - Implementation and Members
@implementation FHGStorageMeasurementViewController {
@private FHGStorageMeasurementView *_contentView;
}

#pragma mark - View methods
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _contentView = [[FHGStorageMeasurementView alloc] initWithContentView:self.view];
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
