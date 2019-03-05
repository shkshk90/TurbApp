//
//  FirstScreenView.m
//  TurbApp
//
//  Created by Samuel Aysser on 03.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "FirstScreenView.h"
#import "../common.h"
#import "views_resources.h"
#import "FirstScreen_common.h"




#pragma mark - Implementation
@implementation FHGFirstScreenView {

@private CGRect           _bounds;
@private UILayoutGuide   *_guide;

@private UIImageView     *_backgroundImageView;
@private UIStackView     *_mainStackView;
    
@private UIButton        *_recordButton;
@private UIButton        *_videoButton;
    
}

#pragma mark - Super Methods
- (id)initWithContentView:(UIView *const)superView
{
    self = [super init] ?: nil;
    
    if (self == nil)
        return nil;
    
    _guide  = superView.safeAreaLayoutGuide;
    _bounds = [UIScreen mainScreen].bounds;
    
    _backgroundImageView = [[UIImageView alloc] init];
    _mainStackView       = [[UIStackView alloc] init];
    
    _recordButton        = [UIButton buttonWithType:UIButtonTypeSystem];
    _videoButton         = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [self setupButton:_videoButton  withTag:FHGTagFSVVideoButton];
    [self setupButton:_recordButton withTag:FHGTagFSVRecordButton];
    
    
    [_mainStackView setSpacing:5.];
    [_mainStackView setAxis:UILayoutConstraintAxisVertical];
    [_mainStackView setDistribution:UIStackViewDistributionFillEqually];
    
    [_mainStackView addArrangedSubview:_recordButton];
    [_mainStackView addArrangedSubview:_videoButton];
    
    [superView addSubview:_backgroundImageView];
    [superView addSubview:_mainStackView];
    
    [self setupConstraits];
    
    return self;
}

- (UIView *)viewWithTag:(const NSInteger)tag
{
    switch ((FHGTagFirstScreen)tag) {
        case FHGTagFSVImageView     : return _backgroundImageView;
        case FHGTagFSVStackView     : return _mainStackView;
        case FHGTagFSVVideoButton   : return _videoButton;
        case FHGTagFSVRecordButton  : return _recordButton;
        default : FHG_TAG_NOT_HANDLED;
    }
}

- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector
{
    [_videoButton addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
    [_recordButton addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
}

#pragma mark - Setup views methods
- (void)setupImageView
{
    [_backgroundImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //
    [[_backgroundImageView.leadingAnchor constraintEqualToAnchor:_guide.leadingAnchor] setActive:YES];
    [[_backgroundImageView.trailingAnchor constraintEqualToAnchor:_guide.trailingAnchor] setActive:YES];
    [[_backgroundImageView.topAnchor constraintEqualToAnchor:_guide.topAnchor] setActive:YES];
    [[_backgroundImageView.bottomAnchor constraintEqualToAnchor:_guide.bottomAnchor] setActive:YES];
    
    [_backgroundImageView setImage:[UIImage imageNamed:FSV_IMAGEVIEW_RES]];
    [_backgroundImageView setAlpha:0.8];
    
    [_backgroundImageView setOpaque:YES];
    
    [_backgroundImageView setTag:(NSInteger)FHGTagFSVImageView];
}

- (void)setupMainStackView
{
    const CGFloat verticalSpacing    = fhgv_getPercentageOfScreenHeight(_bounds, kFSVVerticalPercentage);
    const CGFloat horizontalSpacing  = fhgv_getPercentageOfScreenWidth( _bounds, kFSVHorizontalPercentage);
    
    [_mainStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[_mainStackView.leadingAnchor constraintEqualToAnchor:_guide.leadingAnchor constant:horizontalSpacing] setActive:YES];
    [[_mainStackView.trailingAnchor constraintEqualToAnchor:_guide.trailingAnchor constant:-horizontalSpacing] setActive:YES];
    [[_mainStackView.topAnchor constraintEqualToAnchor:_guide.topAnchor constant:verticalSpacing] setActive:YES];
    [[_mainStackView.bottomAnchor constraintEqualToAnchor:_guide.bottomAnchor constant:-verticalSpacing] setActive:YES];
    
    [_mainStackView setSpacing:verticalSpacing];
    [_mainStackView setDistribution:UIStackViewDistributionFillEqually];
    
    [_mainStackView setOpaque:YES];
    
    [_mainStackView setTag:(NSInteger)FHGTagFSVStackView];
    [_mainStackView setBackgroundColor:[UIColor redColor]];
}

- (void)setupButton:(UIButton *)button withTag:(const FHGTagFirstScreen)tag
{
    const CGFloat fontSize            = (CGFloat)fhgv_getPercentageOfScreenHeight(_bounds, 5);
    
    const CGFloat leftInsetForImage   = (CGFloat)fhgv_getPercentageOfScreenWidth(_bounds, 3);
    const CGFloat rightInsetForImage  = (CGFloat)fhgv_getPercentageOfScreenWidth(_bounds, 15);
    const CGFloat leftInsetForText    = (CGFloat)fhgv_getPercentageOfScreenWidth(_bounds, 24);
    
    UIImage  *image;
    UIColor  *color;
    NSString *text;
    
    switch (tag) {
        case FHGTagFSVRecordButton:
            image = [UIImage imageNamed:FSV_RECORDBTN_IMG_RES];
            color = [UIColor redColor];
            text  = FSV_RECORDBTN_TXT_RES;
            break;
            
        case FHGTagFSVVideoButton:
            image = [UIImage imageNamed:FSV_VIDEOBTN_IMG_RES];
            color = [UIColor blueColor];
            text  = FSV_VIDEOBTN_TXT_RES;
            break;
            
        default: FHG_TAG_NOT_HANDLED;
    }
    
    const UIEdgeInsets imageInsets = UIEdgeInsetsMake(0., leftInsetForImage, 0., rightInsetForImage);
    const UIEdgeInsets titleInsets = UIEdgeInsetsMake(0., leftInsetForText, 0., 0.);
    
    [button setTag:tag];
    
    [button setImageEdgeInsets:imageInsets];
    [button setTitleEdgeInsets:titleInsets];
    
    
    [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [button setContentVerticalAlignment:UIControlContentVerticalAlignmentFill];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentFill];
    
    [button setImage:image forState:UIControlStateNormal];
    
    
    [button.titleLabel setFont:[UIFont fontWithName:@"AppleSDGothicNeo-SemiBold" size:fontSize]];
    [button setTitle:text forState:UIControlStateNormal];
    
    
    [button.layer setCornerRadius:50.];
    [button.layer setMasksToBounds:NO];
    [button.layer setBorderWidth:1.];
    [button.layer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [button.layer setShouldRasterize:YES];
    [button.layer setRasterizationScale:[[UIScreen mainScreen] scale]];
    
    [button setBackgroundColor:[UIColor blackColor]];
    [button setTintColor:[UIColor greenColor]];
    
    [button setOpaque:YES];
    [button setShowsTouchWhenHighlighted:YES];
    
    [button setEnabled:YES];
    [button setUserInteractionEnabled:YES];
}

- (void)setupConstraits
{
    [self setupImageView];
    [self setupMainStackView];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
