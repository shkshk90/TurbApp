//
//  ExperimentParametersView.m
//  TurbApp
//
//  Created by Samuel Aysser on 04.03.19.
//  Copyright © 2019 Fraunhofer. All rights reserved.
//

#import "ExperimentParametersView.h"
#import "views_resources.h"
#import "../common.h"
#import "ExperimentParameters_common.h"


#pragma mark - Implementation & private members
@implementation FHGExperimentParametersView {
    
@private UILayoutGuide                  *_guide;
    
@private UIScrollView                   *_mainScrollView;
@private UIStackView                    *_mainStackView;

@private UILabel                        *_distanceLabel;
@private UITextField                    *_distanceTextField;
    
@private UILabel                        *_apertureLabel;
@private UITextField                    *_apertureTextField;
    
@private UILabel                        *_lengthLabel;
@private UISegmentedControl             *_lengthSegmentedControl;
@private UIStackView                    *_lengthStackView;
@private UITextField                    *_lengthTextField;
@private UIImageView                    *_lengthImageView;
    
@private UILabel                        *_blockLabel;
@private UISegmentedControl             *_blockSegmentedControl;
    
@private UIStackView                    *_samplesLabelStackView;
@private UILabel                        *_samplesLabel;
@private UILabel                        *_samplesCount;
@private UISlider                       *_samplesSlider;
    
@private UIImage                        *_widthImage;
@private UIImage                        *_heightImage;
}

#pragma mark - Protocol methods
- (id)initWithContentView:(UIView *const)superView
{
    self = [super init] ?: nil;
    
    if (self == nil)
        return nil;
    
    _guide  = superView.safeAreaLayoutGuide;
    
    [self initAllViews];
    [self initVariables];
    
    [superView addSubview:self];
    
    
    [self setupViews];
    [self buildMainView];
    [self setupAllConstraints];
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    [self initAllViews];
    [self initVariables];
    
    return self;
}

- (void)createMainViewWithSafeLayoutGuide:(UILayoutGuide *const)guide
{
    _guide = guide;
    
    [self setupViews];
    [self buildMainView];
    [self setupAllConstraints];
}

- (UIView *)viewWithTag:(const NSInteger)tag
{
    switch ((FHGTagExperimentParametersViews)tag) {
        case FHGTagEPVViewMainScrollView: return _mainScrollView;
        case FHGTagEPVViewSamplesSlider:  return _samplesSlider;
    }
    
    switch ((FHGTagExperimentParametersTextField)tag) {
        case FHGTagEPVTextFieldDistance:     return _distanceTextField;
        case FHGTagEPVTextFieldAperture:     return _apertureTextField;
        case FHGTagEPVTextFieldLength:       return _lengthTextField;
        case FHGTagEPVTextFieldSamplesCount: return _samplesCount;
    }
    
    switch ((FHGTagExperimentParametersSegmentedControl)tag) {
        case FHGTagEPVSegControlLength:     return _lengthSegmentedControl;
        case FHGTagEPVSegControlBlockSize:  return _blockSegmentedControl;
    }

    FHG_TAG_NOT_HANDLED;
}

- (void)setButtonsTarget:(UIViewController *const)target withSelector:(const SEL)selector
{
    [_blockSegmentedControl  addTarget:target action:selector forControlEvents:UIControlEventValueChanged];
    [_lengthSegmentedControl addTarget:target action:selector forControlEvents:UIControlEventValueChanged];
}

- (void)setTextFieldDelegateAndTarget:(UIViewController<UITextFieldDelegate> *const)target withSelector:(const SEL)selector
{
    [_distanceTextField setDelegate:target];
    [_apertureTextField setDelegate:target];
    [_lengthTextField   setDelegate:target];
    
    [_distanceTextField addTarget:target action:selector forControlEvents:UIControlEventEditingChanged];
    [_apertureTextField addTarget:target action:selector forControlEvents:UIControlEventEditingChanged];
    [_lengthTextField   addTarget:target action:selector forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - Public methods
- (void)changeLengthViewsToWidth:(const NSInteger)lengthOfScene
{
    switch ((FHGTagExperimentParametersLengthOfScene)lengthOfScene) {
        case FHGTagEPVSceneWidth:
            [_lengthImageView setImage:_widthImage];
            [_lengthTextField setPlaceholder:EPV_PHLDR_WDTH_RES];
            
            break;
            
        case FHGTagEPVSceneHeight:
            [_lengthImageView setImage:_heightImage];
            [_lengthTextField setPlaceholder:EPV_PHLDR_HOCH_RES];
            
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
}


- (void)fillTextField:(const NSInteger)tag withData:(const CGFloat)value
{
    switch ((FHGTagExperimentParametersTextField)tag) {
        case FHGTagEPVTextFieldDistance:
            [_distanceTextField setText:[NSString stringWithFormat:@"%.4g", value]];
            break;
            
        case FHGTagEPVTextFieldAperture:
            [_apertureTextField setText:[NSString stringWithFormat:@"%.4g", value]];
            break;
            
        case FHGTagEPVTextFieldLength:
            [_lengthTextField   setText:[NSString stringWithFormat:@"%.4g", value]];
            break;
            
        case FHGTagEPVTextFieldSamplesCount:
            [_samplesSlider setValue:value];
            [_samplesSlider sendActionsForControlEvents:UIControlEventValueChanged];
            break;
        
        default:
            FHG_TAG_NOT_HANDLED;
    }
}

- (void)updateSegmentedControl:(const NSInteger)tag withValue:(const NSInteger)value
{
    switch ((FHGTagExperimentParametersSegmentedControl)tag) {
        case FHGTagEPVSegControlLength:
            [_lengthSegmentedControl setSelectedSegmentIndex:value];
            [_lengthSegmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
            break;
            
        case FHGTagEPVSegControlBlockSize:
            [_blockSegmentedControl setSelectedSegmentIndex:fhgv_indexForBlockSize(value)];
            [_blockSegmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
            break;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
}

- (void)setSliderTarget:(UIViewController *const)target withSelector:(const SEL)action
{
    [_samplesSlider addTarget:target action:action forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Init methods
- (void)initVariables
{
    _widthImage             = [UIImage imageNamed:EPV_WIDTH_IMG_RES];
    _heightImage            = [UIImage imageNamed:EPV_HEIGHT_IMG_RES];
}

- (void)initAllViews
{
    _mainScrollView         = [[UIScrollView alloc] init];
    _mainStackView          = [[UIStackView  alloc] init];
    
    _distanceLabel          = [[UILabel      alloc] init];
    _distanceTextField      = [[UITextField  alloc] init];
    
    _apertureLabel          = [[UILabel      alloc] init];
    _apertureTextField      = [[UITextField  alloc] init];
    
    _lengthLabel            = [[UILabel     alloc] init];;
    _lengthSegmentedControl = [[UISegmentedControl alloc] init];
    _lengthStackView        = [[UIStackView alloc] init];
    _lengthTextField        = [[UITextField alloc] init];
    _lengthImageView        = [[UIImageView alloc] init];
    
    _blockLabel             = [[UILabel            alloc] init];;
    _blockSegmentedControl  = [[UISegmentedControl alloc] init];
    
    _samplesLabelStackView  = [[UIStackView alloc] init];
    _samplesLabel           = [[UILabel     alloc] init];
    _samplesCount           = [[UILabel     alloc] init];
    
    _samplesSlider          = [[UISlider    alloc] init];
    
    
    [_mainScrollView setOpaque:YES];
    [_mainStackView  setOpaque:YES];
    
    [_distanceLabel     setOpaque:YES];
    [_distanceTextField setOpaque:YES];
    
    [_apertureLabel     setOpaque:YES];
    [_apertureTextField setOpaque:YES];
    
    [_lengthLabel           setOpaque:YES];
    [_lengthSegmentedControl setOpaque:YES];
    [_lengthStackView       setOpaque:YES];
    [_lengthTextField       setOpaque:YES];
    [_lengthImageView       setOpaque:YES];
     
    [_blockLabel            setOpaque:YES];
    [_blockSegmentedControl setOpaque:YES];
    
    [_samplesLabelStackView setOpaque:YES];
    [_samplesLabel          setOpaque:YES];
    [_samplesCount          setOpaque:YES];
    
    [_samplesSlider          setOpaque:YES];
}

#pragma mark - General Setup methods
- (void)setupViews
{
    const CGFloat viewSpacing   = FHGV_SCREEN_WIDTH(kEPVViewSpacingPercentage);
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    [_mainScrollView setBackgroundColor:[UIColor whiteColor]];
    

    [_mainStackView setAxis:UILayoutConstraintAxisVertical];
    [_mainStackView setSpacing:viewSpacing];
  
    
    [_lengthStackView setAxis:UILayoutConstraintAxisHorizontal];
    [_lengthStackView setSpacing:viewSpacing];
    
    [_lengthImageView setImage:_widthImage];
    
    
    
    [self configureLabel:_distanceLabel withTag:FHGTagEPVTextFieldDistance];
    [self configureLabel:_apertureLabel withTag:FHGTagEPVTextFieldAperture];
    [self configureLabel:_lengthLabel   withTag:FHGTagEPVTextFieldLength];
    [self configureLabel:_blockLabel    withTag:FHGTagEPVSegControlBlockSize];
    [self configureLabel:_samplesLabel withTag:FHGTagEPVTextFieldSamplesCount];
    
    [self configureTextField:_distanceTextField withTag:FHGTagEPVTextFieldDistance];
    [self configureTextField:_apertureTextField withTag:FHGTagEPVTextFieldAperture];
    [self configureTextField:_lengthTextField   withTag:FHGTagEPVTextFieldLength];
    
    [self configureSegmentedControl:_lengthSegmentedControl withTag:FHGTagEPVSegControlLength];
    [self configureSegmentedControl:_blockSegmentedControl  withTag:FHGTagEPVSegControlBlockSize];
    
    [self configureSliderWithTag:FHGTagEPVViewSamplesSlider];
}

- (void)buildMainView
{
    [self addSubview:_mainScrollView];
    [_mainScrollView addSubview:_mainStackView];
    
    [_mainStackView addArrangedSubview:_distanceLabel];
    [_mainStackView addArrangedSubview:_distanceTextField];
    
    [_mainStackView addArrangedSubview:_apertureLabel];
    [_mainStackView addArrangedSubview:_apertureTextField];
    
    [_mainStackView addArrangedSubview:_lengthLabel];
    [_mainStackView addArrangedSubview:_lengthSegmentedControl];
    [_mainStackView addArrangedSubview:_lengthStackView];
    
    [_mainStackView addArrangedSubview:_blockLabel];
    [_mainStackView addArrangedSubview:_blockSegmentedControl];
    
    [_mainStackView addArrangedSubview:_samplesLabelStackView];
    [_mainStackView addArrangedSubview:_samplesSlider];
    
    
    [_lengthStackView addArrangedSubview:_lengthTextField];
    [_lengthStackView addArrangedSubview:_lengthImageView];
    
    [_samplesLabelStackView addArrangedSubview:_samplesLabel];
    [_samplesLabelStackView addArrangedSubview:_samplesCount];
    
    
}

-(void)setupAllConstraints
{
    [self setupMainViewConstraints];
    [self setupScrollViewConstraints];
    [self setupMainStackViewConstraints];
    [self setupLengthViewsConstraints];
    [self setupSampleConstraints];
}

#pragma mark - Specific Setup methods
- (void)configureLabel:(UILabel *const)label withTag:(const NSInteger)tag
{
    NSString *labelText;
    
    switch (tag) {
        case FHGTagEPVTextFieldDistance:
            labelText = EPV_LABEL_DIST_RES;
            break;
            
        case FHGTagEPVTextFieldAperture:
            labelText = EPV_LABEL_APRT_RES;
            break;
            
        case FHGTagEPVTextFieldLength:
            labelText = EPV_LABEL_LENG_RES;
            break;
            
        case FHGTagEPVTextFieldSamplesCount:
            labelText = EBV_LABEL_SMPL_RES;
            break;
            
        case FHGTagEPVSegControlBlockSize:
            labelText = EPV_LABEL_BLKS_RES;
            break;
            
        case FHGTagEPVSegControlLength:
            return;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    [label setText:labelText];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setFont:[UIFont fontWithName:@"AppleSDGothicNeo-Medium" size:[UIFont systemFontSize] + 3.]];
}

- (void)configureTextField:(UITextField *const)field withTag:(const FHGTagExperimentParametersTextField)tag
{
    NSString *placeholderText;
    
    switch (tag) {
        case FHGTagEPVTextFieldDistance:
            placeholderText = EPV_PHLDR_DIST_RES;
            break;
            
        case FHGTagEPVTextFieldAperture:
            placeholderText = EPV_PHLDR_APRT_RES;
            break;
            
        case FHGTagEPVTextFieldLength:
            placeholderText = EPV_PHLDR_WDTH_RES;
            break;
            
        case FHGTagEPVTextFieldSamplesCount:
            return;
            
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    [field setTag:(NSInteger)tag];
    
    [field setPlaceholder:placeholderText];
    [field setTextAlignment:NSTextAlignmentLeft];
    
    [field setKeyboardType:UIKeyboardTypeDecimalPad];
    [field setBorderStyle:UITextBorderStyleRoundedRect];
    
    [field setFont:[UIFont fontWithName:@"GillSans" size:[UIFont systemFontSize] + 1.]];
    
//    [field setDelegate:self];
//    [field addTarget:self action:@selector(checkTextField:) forControlEvents:UIControlEventEditingChanged];
}

- (void)configureSegmentedControl:(UISegmentedControl *const)segmentedControl withTag:(const FHGTagExperimentParametersSegmentedControl)tag
{
    NSArray     *segments;
    NSInteger   defaultSelection = 0;
    SEL         actionOnSelection = nil;
    
    switch (tag) {
        case FHGTagEPVSegControlLength:
            segments = @[ @"Width", @"Height" ];
            defaultSelection = 0;
            break;
            
        case FHGTagEPVSegControlBlockSize:
            segments = EPV_SEGCL_BS_ARR_RES;
            defaultSelection = 1;
            break;
        
        default:
            FHG_TAG_NOT_HANDLED;
    }
    
    for (NSString *title in segments)
        [segmentedControl insertSegmentWithTitle:title atIndex:segmentedControl.numberOfSegments animated:NO];
    
    [segmentedControl setTag:(NSInteger)tag];
    [segmentedControl setSelectedSegmentIndex:defaultSelection];
    [segmentedControl addTarget:self action:actionOnSelection forControlEvents:UIControlEventValueChanged];
}

- (void)configureSliderWithTag:(const FHGTagExperimentParametersViews)tag
{
    [_samplesSlider setTag:tag];
    [_samplesSlider setMinimumValue:0.];
    [_samplesSlider setMaximumValue:kFHGMaximumNumberOfSamples / 10.];
    
    [_samplesSlider setValue:kEPVStartingSamplesCount / 10. animated:NO];
    
    [_samplesSlider setMinimumValueImage:[[UIImage imageNamed:EPV_F_SMPL_IMG_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [_samplesSlider setMaximumValueImage:[[UIImage imageNamed:EPV_M_SMPL_IMG_RES] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    
    [_samplesSlider setMinimumTrackTintColor:self.tintColor];
    
    [_samplesCount  setTextAlignment:NSTextAlignmentRight];
    [_samplesCount  setText:[NSString stringWithFormat:@"%.f", kEPVStartingSamplesCount]];
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
    const CGFloat topSpacing    = FHGV_SCREEN_HEIGHT(kEPVTopSpacingPercentage);
    const CGFloat bottomSpacing = FHGV_SCREEN_HEIGHT(kEPVBottomSpacingPercentage);
    const CGFloat rightSpacing  = FHGV_SCREEN_WIDTH(kEPVRightSpacingPercentage);
    
    [_mainStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[_mainStackView.leadingAnchor constraintEqualToAnchor:_mainScrollView.leadingAnchor] setActive:YES];
    [[_mainStackView.trailingAnchor constraintEqualToAnchor:_mainScrollView.trailingAnchor constant:rightSpacing] setActive:YES];
    [[_mainStackView.topAnchor constraintEqualToAnchor:_mainScrollView.topAnchor constant:topSpacing] setActive:YES];
    [[_mainStackView.bottomAnchor constraintEqualToAnchor:_mainScrollView.bottomAnchor constant:-bottomSpacing] setActive:YES];
    [[_mainStackView.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
}

- (void)setupLengthViewsConstraints
{
    const CGFloat rightSpacing  =  FHGV_SCREEN_WIDTH(kEPVRightSpacingPercentage); // getPercentageOfScreenWidth(kRightSpacingPercentage);
    
    [_lengthStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_lengthStackView.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
    
    [_lengthImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_lengthImageView addConstraint:[NSLayoutConstraint constraintWithItem:_lengthImageView
                                                                 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                    toItem:_lengthImageView
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1.
                                                                  constant:1.]];
}

- (void)setupSampleConstraints
{
    const CGFloat rightSpacing  =  FHGV_SCREEN_WIDTH(kEPVRightSpacingPercentage);
    
    [_samplesLabelStackView  setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_samplesLabelStackView.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
    
    [_samplesSlider setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_samplesSlider.widthAnchor constraintEqualToAnchor:_mainScrollView.widthAnchor constant:-rightSpacing] setActive:YES];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
