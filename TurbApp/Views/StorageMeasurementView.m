//
//  StorageMeasurement.m
//  TurbApp
//
//  Created by Samuel Aysser on 05.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "StorageMeasurementView.h"
#import "../common.h"
#import "StorageMeasurement_common.h"
#import "views_common.h"
#import "views_resources.h"

#pragma mark - Private Members
@implementation FHGStorageMeasurementView {
@private UILayoutGuide  *_guide;
    
@private UIScrollView   *_mainScrollView;
@private UIStackView    *_mainStackView;
    
@private UIStackView    *_stepOneStackView;
@private UILabel        *_stepOneLabel;
@private UIButton       *_reselectButton;
@private UIImageView    *_previewImageView;
@private CALayer        *_roiLayer;
    
@private UIStackView    *_stepTwoStackView;
@private UILabel        *_stepTwoLabel;
@private UIButton       *_settingsButton;
    
@private UILabel        *_stepThreeLabel;
@private UIButton       *_launchButton;
    

    
}

#pragma mark - Protocol methods
- (id)initWithContentView:(UIView *const)superView
{
    self = [super init] ?: nil;
    
    if (self == nil)
        return nil;
    
    _guide  = superView.safeAreaLayoutGuide;
    
    [self initAllViews];
    
    [superView addSubview:self];
    
    
    [self setupViews];
    [self buildMainView];
    [self setupAllConstraints];
    
    return self;
}

- (UIView *)viewWithTag:(const NSInteger)tag
{
    switch ((FHGTagStorageMeasurementSteps)tag) {
        case FHGTagSMVStepOne:   return _stepOneLabel;
        case FHGTagSMVStepTwo:   return _stepTwoLabel;
        case FHGTagSMVStepThree: return _stepThreeLabel;
    }
    
    switch ((FHGTagStorageMeasurementButtonTags)tag) {
        case FHGTagSMVResetButton:    return _reselectButton;
        case FHGTagSMVSettingsButton: return _settingsButton;
        case FHGTagSMVLaunchButton:   return _launchButton;
    }
    
    switch ((FHGTagStorageMeasurementViewsTags)tag) {
        case FHGTagSMVPreview: return _previewImageView;
    }
    
    FHG_TAG_NOT_HANDLED;
}

- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector
{
    [_reselectButton addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
    [_settingsButton addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
    [_launchButton   addTarget:target action:selector forControlEvents:UIControlEventTouchDown];
}

#pragma mark - Public methods
- (CALayer *)roiLayer
{
    return _roiLayer;
}

#pragma mark - Init methods
- (void)initAllViews
{
    _mainScrollView         = [[UIScrollView alloc] init];
    _mainStackView          = [[UIStackView  alloc] init];
    
    _stepOneStackView       = [[UIStackView alloc] init];
    _stepOneLabel           = [[UILabel     alloc] init];
    _reselectButton         =  [UIButton    buttonWithType:UIButtonTypeSystem];
    _previewImageView       = [[UIImageView alloc] init];
    _roiLayer               =  [CALayer layer];
    
    _stepTwoStackView       = [[UIStackView alloc] init];
    _stepTwoLabel           = [[UILabel     alloc] init];
    _settingsButton         =  [UIButton    buttonWithType:UIButtonTypeSystem];
    
    _stepThreeLabel         = [[UILabel     alloc] init];
    _launchButton           =  [UIButton    buttonWithType:UIButtonTypeSystem];
    
    
    
    
    [_mainScrollView setOpaque:YES];
    [_mainStackView  setOpaque:YES];
    
    [_stepOneStackView      setOpaque:YES];
    [_stepOneLabel          setOpaque:YES];
    [_reselectButton        setOpaque:YES];
    [_previewImageView      setOpaque:YES];
    
    [_stepTwoStackView      setOpaque:YES];
    [_stepTwoLabel          setOpaque:YES];
    [_settingsButton        setOpaque:YES];
    
    [_stepThreeLabel        setOpaque:YES];
    [_launchButton          setOpaque:YES];
}

#pragma mark - General Setup methods
- (void)setupViews
{
    const CGFloat viewSpacing   = FHGV_SCREEN_WIDTH(kSMVViewSpacingPercentage);
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    [_mainScrollView setBackgroundColor:[UIColor whiteColor]];
    
    [_mainStackView setAxis:UILayoutConstraintAxisVertical];
    [_mainStackView setSpacing:viewSpacing];
    
    
    [_stepOneStackView setSpacing:viewSpacing];
    [_stepOneStackView setAxis:UILayoutConstraintAxisHorizontal];
    [_stepOneStackView setDistribution:UIStackViewDistributionEqualSpacing];
    
    [_stepTwoStackView setSpacing:viewSpacing];
    [_stepTwoStackView setAxis:UILayoutConstraintAxisHorizontal];
    [_stepTwoStackView setDistribution:UIStackViewDistributionEqualSpacing];
    
    [_launchButton setContentVerticalAlignment:UIControlContentVerticalAlignmentFill];
    [_launchButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentFill];
    
    
    [self configureLabel:_stepOneLabel   withTag:FHGTagSMVStepOne];
    [self configureLabel:_stepTwoLabel   withTag:FHGTagSMVStepTwo];
    [self configureLabel:_stepThreeLabel withTag:FHGTagSMVStepThree];
    
    [self configureButton:_reselectButton withTag:FHGTagSMVResetButton];
    [self configureButton:_settingsButton withTag:FHGTagSMVSettingsButton];
    [self configureButton:_launchButton   withTag:FHGTagSMVLaunchButton];
    
    [self configurePreview];
    [self configureRoiLayer];
}

- (void)buildMainView
{
    [self addSubview:_mainScrollView];
    [_mainScrollView addSubview:_mainStackView];
    
    [_mainStackView addArrangedSubview:_stepOneStackView];
    [_mainStackView addArrangedSubview:_previewImageView];
    
    [_mainStackView addArrangedSubview:_stepTwoStackView];
    
    [_mainStackView addArrangedSubview:_stepThreeLabel];
    [_mainStackView addArrangedSubview:_launchButton];
    
    
    [_stepOneStackView addArrangedSubview:_stepOneLabel];
    [_stepOneStackView addArrangedSubview:_reselectButton];
    
    
    [_stepTwoStackView addArrangedSubview:_stepTwoLabel];
    [_stepTwoStackView addArrangedSubview:_settingsButton];
    
    [_previewImageView.layer addSublayer:_roiLayer];
}

-(void)setupAllConstraints
{
    [self setupMainViewConstraints];
    [self setupScrollViewConstraints];
    [self setupMainStackViewConstraints];
    [self setupSmallStackViewsConstraints];
    [self setupPreviewConstraints];
    [self setupButtonsConstraints];
}


#pragma mark - Specific Setup methods
- (void)configureLabel:(UILabel *const)label withTag:(const FHGTagStorageMeasurementSteps)tag
{
    NSString *labelText;
    UIColor  *textColor;
    
    switch (tag) {
        case FHGTagSMVStepOne:
            labelText = SMV_STEP1_TXT_RES;
            textColor = [UIColor blackColor];
            break;
            
        case FHGTagSMVStepTwo:
            labelText = SMV_STEP2_TXT_RES;
            textColor = [UIColor grayColor];
            break;
            
        case FHGTagSMVStepThree:
            labelText = SMV_STEP3_TXT_RES;
            textColor = [UIColor grayColor];
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    [label setText:labelText];
    [label setTextColor:textColor];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setFont:[UIFont fontWithName:SMV_LABELS_FONT_RES size:[UIFont systemFontSize] + 3.]];
    
    [label setTag:tag];
}

- (void)configurePreview
{
    [_previewImageView setImage:[[UIImage imageNamed:SMV_PREVIEW_IMG_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    
    [_previewImageView setClipsToBounds:YES];
    [_previewImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [_previewImageView setTintColor:[UIColor greenColor]];
    [_previewImageView setBackgroundColor:[UIColor darkGrayColor]];
    
    
    [_previewImageView setTag:FHGTagSMVPreview];
}

- (void)configureButton:(UIButton *const)button withTag:(const FHGTagStorageMeasurementButtonTags)tag
{
    UIImage *icon;
    UIColor *color;
    
    BOOL    enabled;
    BOOL    hidden;
    
    switch(tag) {
        case FHGTagSMVResetButton:
            icon    = [[UIImage imageNamed:SMV_RESTART_ICN_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            color   = [UIColor blueColor];
            
            enabled = NO;
            hidden  = YES;
            
            break;
            
        case FHGTagSMVSettingsButton:
            icon    = [[UIImage imageNamed:SMV_SETTINGS_ICN_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            color   = [UIColor redColor];
            
            enabled = NO;
            hidden  = NO;
            
            break;
            
        case FHGTagSMVLaunchButton:
            icon    = [[UIImage imageNamed:SMV_LAUNCH_ICN_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            color   = [UIColor orangeColor];
            
            enabled = NO;
            hidden  = NO;
            
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    hidden = NO;
    [button setTag:tag];
    
    [button setHidden:hidden];
    [button setEnabled:enabled];
    
    [button setTintColor:color];
    [button setImage:icon forState:UIControlStateNormal];
}

- (void)configureRoiLayer
{
    const CGRect bounds  = [UIScreen mainScreen].bounds;
    
    const CGFloat roiX   = (CGRectGetWidth(bounds)  / 2.) - 25.;
    const CGFloat roiY   = (CGRectGetHeight(bounds) / 2.) - 25.;
    
    [_roiLayer setHidden:YES];
    [_roiLayer setBorderWidth:2.];
    [_roiLayer setDrawsAsynchronously:YES];
    [_roiLayer setFrame:CGRectMake(roiX, roiY, 50., 50.)];
    [_roiLayer setBorderColor:[UIColor orangeColor].CGColor];
    
}

#pragma mark - Specific Constraint methods
- (void)setupMainViewConstraints
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[self.leadingAnchor  constraintEqualToAnchor:_guide.leadingAnchor]  setActive:YES];
    [[self.trailingAnchor constraintEqualToAnchor:_guide.trailingAnchor] setActive:YES];
    [[self.topAnchor      constraintEqualToAnchor:_guide.topAnchor]      setActive:YES];
    [[self.bottomAnchor   constraintEqualToAnchor:_guide.bottomAnchor]   setActive:YES];
}

- (void)setupScrollViewConstraints
{
    [_mainScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[_mainScrollView.leadingAnchor  constraintEqualToAnchor:self.leadingAnchor constant:10.] setActive:YES];
    [[_mainScrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]             setActive:YES];
    [[_mainScrollView.topAnchor      constraintEqualToAnchor:self.topAnchor]                  setActive:YES];
    [[_mainScrollView.bottomAnchor   constraintEqualToAnchor:self.bottomAnchor]               setActive:YES];
}

- (void)setupMainStackViewConstraints
{
    const CGFloat topSpacing    = FHGV_SCREEN_HEIGHT(kSMVTopSpacingPercentage);
    const CGFloat bottomSpacing = FHGV_SCREEN_HEIGHT(kSMVBottomSpacingPercentage);
    const CGFloat rightSpacing  = FHGV_SCREEN_WIDTH(kSMVRightSpacingPercentage);
    
    
    [_mainStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[_mainStackView.leadingAnchor constraintEqualToAnchor:_mainScrollView.leadingAnchor] setActive:YES];
    [[_mainStackView.trailingAnchor constraintEqualToAnchor:_mainScrollView.trailingAnchor constant:rightSpacing] setActive:YES];
    [[_mainStackView.topAnchor constraintEqualToAnchor:_mainScrollView.topAnchor constant:topSpacing] setActive:YES];
    [[_mainStackView.bottomAnchor constraintEqualToAnchor:_mainScrollView.bottomAnchor constant:-bottomSpacing] setActive:YES];
    [[_mainStackView.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
}

- (void)setupSmallStackViewsConstraints
{
    const CGFloat rightSpacing  =  FHGV_SCREEN_WIDTH(kEPVRightSpacingPercentage);
    
    [_stepOneStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_stepOneStackView.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
    
    [_stepTwoStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_stepTwoStackView.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
}

- (void)setupPreviewConstraints
{
    [_previewImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_previewImageView.widthAnchor constraintEqualToAnchor:_mainStackView.widthAnchor] setActive:YES];
    
    [_previewImageView addConstraint:[NSLayoutConstraint
                                    constraintWithItem:_previewImageView
                                    attribute:NSLayoutAttributeHeight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:_previewImageView
                                    attribute:NSLayoutAttributeWidth
                                    multiplier:9./16. // (CGRectGetHeight(_previewImageView.frame) / CGRectGetWidth(_previewImageView.frame))
                                    constant:1.]];
    
}

- (void)setupButtonsConstraints
{
    [_reselectButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_settingsButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_launchButton   setTranslatesAutoresizingMaskIntoConstraints:NO];
    
//    [_reselectButton addConstraint:[NSLayoutConstraint
//                                      constraintWithItem:_reselectButton
//                                      attribute:NSLayoutAttributeHeight
//                                      relatedBy:NSLayoutRelationEqual
//                                      toItem:_reselectButton
//                                      attribute:NSLayoutAttributeWidth
//                                      multiplier:1.
//                                      constant:1.]];
    [_settingsButton addConstraint:[NSLayoutConstraint
                                    constraintWithItem:_settingsButton
                                    attribute:NSLayoutAttributeHeight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:_settingsButton
                                    attribute:NSLayoutAttributeWidth
                                    multiplier:1.
                                    constant:1.]];
    
    [_launchButton addConstraint:[NSLayoutConstraint
                                    constraintWithItem:_launchButton
                                    attribute:NSLayoutAttributeHeight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:_launchButton
                                    attribute:NSLayoutAttributeWidth
                                    multiplier:1.
                                    constant:1.]];

    
    const CGFloat Cn2Spacing = FHGV_SCREEN_WIDTH(kSMVCn2SpacingPercentage);
    
    [self addConstraint:[NSLayoutConstraint
                                  constraintWithItem:_launchButton
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:_mainStackView
                                  attribute:NSLayoutAttributeLeft
                                  multiplier:1.
                                  constant:Cn2Spacing]];
    [self addConstraint:[NSLayoutConstraint
                         constraintWithItem:_launchButton
                         attribute:NSLayoutAttributeRight
                         relatedBy:NSLayoutRelationEqual
                         toItem:_mainStackView
                         attribute:NSLayoutAttributeRight
                         multiplier:1.
                         constant:-Cn2Spacing]];
//    [_launchButton.widthAnchor constraintEqualToAnchor:_mainStackView.widthAnchor constant:-200.];
//    [self addConstraint:[NSLayoutConstraint
//                          constraintWithItem:_launchButton
//                          attribute:NSLayoutAttributeWidth
//                          relatedBy:NSLayoutRelationEqual
//                          toItem:_mainStackView
//                          attribute:NSLayoutAttributeWidth
//                          multiplier:0.5
//                          constant:1.]];
//    [self addConstraint:[NSLayoutConstraint
//                         constraintWithItem:_launchButton
//                         attribute:NSLayoutAttributeLeft
//                         relatedBy:NSLayoutRelationEqual
//                         toItem:_mainStackView
//                         attribute:NSLayoutAttributeLeft
//                         multiplier:1.
//                         constant:30.]];
    
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
