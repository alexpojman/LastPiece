//
//  YBIViewController.m
//  LastPiece
//
//  Created by Alex Pojman on 7/29/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBIViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Chameleon.h"
#import "YBIAddNameViewController.h"
#import "YBIListTableViewController.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define paletteBlue      0x61ADFF
#define paletteBlueAlt   0x61CDFF
#define paletteGreen     0x8AD998
#define paletteGreenAlt  0x8AF998
#define paletteRed       0xFF5A4F
#define paletteRedAlt    0xFF7A4F
#define paletteOrange    0xFFB13F
#define paletteOrangeAlt 0xFFD13F


@implementation YBIViewController

@synthesize pieChart = _pieChart;
@synthesize slices = _slices;
@synthesize sliceColors = _sliceColors;



- (instancetype)init
{
    if (self) {
        NSString *nibName = @"";
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            CGSize result = [[UIScreen mainScreen] bounds].size;
            if(result.height == 480)
            {
                nibName = @"YBIViewController3";
                _pieChartAnimationValue = 130;
                _rotateButtonAnimationValue = 440;
                _rotateButtonScaleValue = 1.03;
                
            }
            else if(result.height >= 568)
            {
                nibName = @"YBIViewController";
                _pieChartAnimationValue = 130;
                _rotateButtonAnimationValue = 300;
                _rotateButtonScaleValue = 1.03;
            }
        }
        self = [super initWithNibName:nibName bundle:nil];
        
        UINavigationItem *navItem = self.navigationItem;
        navItem.title = @"LAST PIECE";
        
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(addParticipants:)];
        
        // Left Bar Button (Hamburger Menu)
        LBHamburgerButton *button = [[LBHamburgerButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)
                                                 withHamburgerType:LBHamburgerButtonTypeBackButton
                                                         lineWidth:25
                                                        lineHeight:25/6
                                                       lineSpacing:4
                                                        lineCenter:CGPointMake(10,25)
                                                             color:UIColorFromRGB(paletteBlue)];
        
        _hamburgerButton = button;
        
        [_hamburgerButton addTarget:self action:@selector(showRearMenu) forControlEvents:UIControlEventTouchUpInside];
        
        //[self.view addSubview:button];
        UIBarButtonItem *rbi = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        // Left Bar Navigation Item Setup
        navItem.rightBarButtonItem = bbi;
        
        // Right Bar Naviagation Item Setup
        navItem.leftBarButtonItem = rbi;
        
        // Set Colors
        [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          UIColorFromRGB(paletteOrange), NSForegroundColorAttributeName,
          [UIFont fontWithName:@"MyriadPro-BoldCond" size:21],
          NSFontAttributeName, nil]];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        
        // Set font for Nav Items
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [UIFont fontWithName:@"MyriadPro-Regular" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [UIFont fontWithName:@"MyriadPro-Regular" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];

        // Set font for winner label
        UIFont *font=[UIFont fontWithName:@"MyriadPro-Regular" size:24];
        [self.winnerLabel setFont:font];
        
        // Starting pieChart bool values
        _animating = NO;
        _pieChartHasRelocated = NO;
        
        // Add observer for returning from background
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetViewOnReturnFromBackground)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];
        
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

// Fix initial loading
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib
    
    // Slices init
    self.slices = [[NSMutableArray alloc] init];
    
    NSArray *names = [NSArray array];
    for(int i = 0; i < names.count; i ++)
    {
        NSString *sliceLabels = names[i];
        [_slices addObject:sliceLabels];
    }
    
    // Initialize Pie Chart Object
    [self.pieChart setDelegate:self];
    [self.pieChart setDataSource:self];
    [self.pieChart setLabelColor:[UIColor blackColor]];
    
    // Add Gesture to Pie
    UITapGestureRecognizer *pieChartTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addParticipants:)];
    
    [self.pieChart addGestureRecognizer:pieChartTapRecognizer];
    
    // Color for selecting slice
    if ([_slices count] < 6) {
    self.sliceColors = [NSArray arrayWithObjects:
                       UIColorFromRGB(paletteBlue),
                       UIColorFromRGB(paletteGreen),
                       UIColorFromRGB(paletteOrange),
                       UIColorFromRGB(paletteRed),
                        UIColorFromRGB(paletteBlueAlt),
                        UIColorFromRGB(paletteGreenAlt),
                        UIColorFromRGB(paletteOrangeAlt),
                        UIColorFromRGB(paletteRedAlt),
                      nil];
    }
    
    // Get Elimination Mode status
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _isEliminationMode = [userDefaults boolForKey:@"eliminationMode"];
    
    
    // Animation Elimation Mode test
    [_eliminationButton setBackgroundImage:[UIImage imageNamed:@"elim_mode0.png"] forState:UIControlStateNormal];
}

- (void)viewDidUnload
{
    [self setPieChart:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Check the number of slices for enable/disable SPIN button
    if ([self numberOfSlicesInPieChart:self.pieChart] < 2) {
        [self.navigationItem.rightBarButtonItem setTitle:@""];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [_rotateButton setEnabled:NO];
        [[_rotateButton titleLabel] setFont:[UIFont systemFontOfSize:15]];
    } else {
        [self reloadPie];
    }
    
    // Reset winner label
    _winnerLabel.transform = CGAffineTransformIdentity;
    
    // Add Gesture for Side-Menu
    [self.revealViewController panGestureRecognizer];
    
    // Add SWRevealViewController Pan Gesture
    self.revealViewController.panGestureRecognizer.enabled = YES;
    
    self.revealViewController.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.pieChart reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)resetViewOnReturnFromBackground
{
    if([[[_rotateButton titleLabel] text] isEqual: @"STOP"]) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self fadeButtonWithOptions:UIViewAnimationOptionCurveEaseIn newAlpha:0 buttonToDisplay:@"GO"];
        _animating = NO;
        self.pieChart.sliceAnimating = NO;
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - User Control Options
- (IBAction)rotate:(UIButton *)sender
{
    if([[[_rotateButton titleLabel] text] isEqual: @"GO"]) {
        if (self.pieChart.sliceAnimating == YES) {
            [self animateWinnerLabel:UIViewAnimationOptionCurveEaseInOut moveBehavior:@"MoveOffScreen"];
            
            if (_isEliminationMode == YES && _slices.count > 1) {
                [_slices removeObjectAtIndex:_mostRecentWinnerIndex];
                [self.pieChart reloadData];
            }
        }
        
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self fadeButtonWithOptions:UIViewAnimationOptionCurveEaseIn newAlpha:0 buttonToDisplay:@"STOP"];
        for (int i=0; i < [self numberOfSlicesInPieChart:self.pieChart]; i++) {
            [self.pieChart setSliceDeselectedAtIndex:i];
        }
        if (!_animating) {
            _animating = YES;
            [self spinWithOptions: UIViewAnimationOptionCurveLinear];
        }
    } else if([[[_rotateButton titleLabel] text] isEqual: @"STOP"]) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self fadeButtonWithOptions:UIViewAnimationOptionCurveEaseIn newAlpha:0 buttonToDisplay:@"GO"];
        _animating = NO;
        self.pieChart.sliceAnimating = NO;
    }
}

- (IBAction)eliminationTapped:(id)sender {
    //UIImageView *elimButtonTappedAnimation = [[UIImageView alloc] initWithFrame:_eliminationButton.frame];
    
    NSMutableArray *animatedImagesArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < 6; i++)
    {
        [animatedImagesArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"elim_mode%d%@", i, @".png"]]];
    }
    
    _eliminationButton.imageView.animationImages = animatedImagesArray;
    _eliminationButton.imageView.animationDuration = 2.0f;
    _eliminationButton.imageView.animationRepeatCount = 1.0f;
    
    //[_eliminationButton setBackgroundImage: [_eliminationButton.imageView.animationImages lastObject] forState:UIControlStateNormal];
    [_eliminationButton.imageView startAnimating];
    
    //[_eliminationButton setBackgroundImage: [elimButtonTappedAnimation.animationImages lastObject] forState:UIControlStateNormal];
    
    _isEliminationMode = !_isEliminationMode;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_isEliminationMode forKey:@"eliminationMode"];
}

#pragma mark - Animation Methods
- (void)fadeButtonWithOptions: (UIViewAnimationOptions) options newAlpha:(float)newAlpha buttonToDisplay:(NSString*)buttonName
{
    [UIView animateWithDuration:.15f
                          delay: 0.0f
                        options: options
                     animations:^{
                         [_rotateButton setAlpha:newAlpha];
                     }
                     completion:^(BOOL finished){
                         if(_rotateButton.alpha < 1) {
                             if ([buttonName isEqualToString:@"STOP"]) {
                                 [_rotateButton setTitle:@"STOP" forState:UIControlStateNormal];
                                 [_rotateButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
                                 [self fadeButtonWithOptions:UIViewAnimationOptionCurveLinear newAlpha:1 buttonToDisplay:@"STOP"];
                             }
                             else if([buttonName isEqualToString:@"GO"]) {
                                 [_rotateButton setTitle:@"GO" forState:UIControlStateNormal];
                                 [_rotateButton setImage:[UIImage imageNamed:@"go.png"] forState:UIControlStateNormal];
                                 [self fadeButtonWithOptions:UIViewAnimationOptionCurveLinear newAlpha:1 buttonToDisplay:@"GO"];
                             }
                         }
                         
                     }];
}

- (void)spinWithOptions: (UIViewAnimationOptions) options
{
    // Spin the pie chart
    [UIView animateWithDuration: .00001f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.pieChart.transform = CGAffineTransformRotate(_pieChart.transform, M_PI / 8);
                         self.pieChartRotationOffset += (M_PI / 8);
                         if(self.pieChartRotationOffset >= M_PI * 2) {
                             self.pieChartRotationOffset = 0.0;
                         }
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (_animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                                 
                                 // Slight delay, choose winning slice
                                 sleep(0.5);
                                 [self chooseIndexOfWinningSlice];
                             }
                         }
                     }];
}

- (void)movePieChartConstraintWithOptions: (UIViewAnimationOptions) options
{
    [UIView animateWithDuration: 1.0f
                          delay: 0.25f
                        options: options
                     animations: ^{
                         // Move pie chart
                         //TODO: update variables instead of magic numbers
                         self.pieChart.transform = CGAffineTransformTranslate(self.pieChart.transform, self.pieChart.transform.tx, self.pieChart.transform.ty - (_pieChartAnimationValue/2));

                         
                        // Move the rotate button
                         self.rotateButton.transform = CGAffineTransformTranslate(self.rotateButton.transform, self.rotateButton.transform.tx, self.rotateButton.transform.ty - (_rotateButtonAnimationValue/2));
                         
                         // Move ticker symbol
                         self.tickerSymbol.transform = CGAffineTransformTranslate(self.tickerSymbol.transform, self.tickerSymbol.transform.tx - 45, self.tickerSymbol.transform.ty);
                     }
                     completion: ^(BOOL finished) {
                         _pieChartHasRelocated = YES;
                         
                     }];
}


- (void)animateWinnerLabel: (UIViewAnimationOptions) options moveBehavior:(NSString *)moveBehavior
{
    [UIView animateWithDuration: 0.4f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         if ([moveBehavior isEqual:@"MoveOnScreen"])
                         {
                             _winnerLabel.transform = CGAffineTransformTranslate(_winnerLabel.transform, 410, _winnerLabel.transform.ty);
                         }
                         else if ([moveBehavior isEqual:@"MoveOffScreen"]) {
                             _winnerLabel.transform = CGAffineTransformTranslate(_winnerLabel.transform, 410, _winnerLabel.transform.ty);
                         }
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if ([moveBehavior isEqual:@"MoveOffScreen"]) {
                                 _winnerLabel.transform = CGAffineTransformIdentity;
                             }
                             
                         }
                     }];
}

#pragma mark - Nav-Related Methods
- (IBAction)addParticipants:(id)sender
{
    [_pieChart setAlpha:0.8f];
    YBIAddNameViewController *advc = [[YBIAddNameViewController alloc] initWithNibName:nil bundle:nil namesList:_slices];
    advc.delegate = self;
    
    // Delselect the winning slice
    self.pieChart.sliceAnimating = NO;
    
    //[self.navigationController presentViewController:advc animated:YES completion:nil];
    [self.navigationController pushViewController:advc animated:YES];
}

- (void)showRearMenu {
    [_hamburgerButton switchState];
    [self.revealViewController revealToggle:self];
}

#pragma mark - ChooseWinner Methods
-(void)chooseIndexOfWinningSlice
{
    NSInteger numOfSlices = [self numberOfSlicesInPieChart:self.pieChart];
    
    
    NSMutableArray *offsetMiddleAngles = [self.pieChart getMiddleAngles];
    
    double lowestDistance = 2 * M_PI;
    double marginForSameDistance = 0.005;       // Offset for lowestDistance to check if potential duplicate lowestDistance slices
    NSInteger currentPotentialWinnerIndex = 0;
    // Calculate "offset" middle angles after offset for each slice
    for(int i=0; i < numOfSlices; i++) {
        
        // Calculate initial offset
        offsetMiddleAngles[i]  = [NSNumber numberWithDouble:((self.pieChartRotationOffset + [offsetMiddleAngles[i] floatValue]) - ((2 * M_PI)))];
        
        // Bring offset values in range from 0-2pi
        if([offsetMiddleAngles[i] floatValue] > (2 * M_PI)) {
            offsetMiddleAngles[i] = [NSNumber numberWithDouble:([offsetMiddleAngles[i] floatValue] - (2 * M_PI))];
        }
        
        // Calcuate absolute difference from 0/2pi
        if([offsetMiddleAngles[i] floatValue] > M_PI) {
            offsetMiddleAngles[i] = [NSNumber numberWithDouble:ABS(([offsetMiddleAngles[i] floatValue] - (2 * M_PI)))];
        }
        
        // Correct for any negative error
        if([offsetMiddleAngles[i] floatValue] < 0) {
            offsetMiddleAngles[i] = [NSNumber numberWithDouble:ABS([offsetMiddleAngles[i] floatValue])];

        }
        
        if([offsetMiddleAngles[i] floatValue] < (lowestDistance - marginForSameDistance))
        {
            lowestDistance = [offsetMiddleAngles[i] floatValue];
            currentPotentialWinnerIndex = i;
        } else if (([offsetMiddleAngles[i] floatValue] > (lowestDistance - marginForSameDistance)) && ([offsetMiddleAngles[i] floatValue] < (lowestDistance + marginForSameDistance))) {
            // Account for a tie
            int r = arc4random_uniform(1000);
            if(r > 499) {
                lowestDistance = [offsetMiddleAngles[i] floatValue];
                currentPotentialWinnerIndex = i;
            }
        }
    }
    
    //Truncate currentPotentialWinner to avoid cutting off winnerLabel text
    NSString *winnerText = self.slices[currentPotentialWinnerIndex];
    
    if ([self.slices[currentPotentialWinnerIndex] length] > 16) {
        winnerText = [NSString stringWithFormat:@"%@...",[self.slices[currentPotentialWinnerIndex] substringToIndex:16]];
    }


    if (_isEliminationMode == YES && _slices.count > 2) {
        _winnerLabel.text = [NSString stringWithFormat:@"%@\n will be removed!", winnerText];
    } else if (_isEliminationMode == YES && _slices.count == 2) {
        _winnerLabel.text = [NSString stringWithFormat:@"%@\n is the last piece!", winnerText];
    } else {
        _winnerLabel.text = [NSString stringWithFormat:@"%@\n is the winner!", winnerText];
    }
    
    // Set winner label background to winning slice color
    if(currentPotentialWinnerIndex >= _sliceColors.count) {
        _winnerLabel.backgroundColor = _sliceColors[currentPotentialWinnerIndex - _sliceColors.count];
    } else {
        _winnerLabel.backgroundColor = _sliceColors[currentPotentialWinnerIndex];
    }
    
    // Animate winner label
    [self animateWinnerLabel:UIViewAnimationOptionCurveEaseInOut moveBehavior:@"MoveOnScreen"];
    [self.pieChart setSliceSelectedAtIndex:currentPotentialWinnerIndex];
    
    _mostRecentWinnerIndex = currentPotentialWinnerIndex;
}

#pragma mark - YBIPieChart Data Source

- (NSUInteger)numberOfSlicesInPieChart:(YBIPieChart *)pieChart
{
    return self.slices.count;
}

- (UIColor *)pieChart:(YBIPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    //if(pieChart == self.pieChart) return nil;
    return [self.sliceColors objectAtIndex:(index % self.sliceColors.count)];
}

- (UIColor *)pieChart:(YBIPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index
{
    return self.slices[index];
}


#pragma mark - Delegation from YBIAddNameViewController
- (void)addNameViewController:(YBIAddNameViewController *)pvc didFinishAddingNames:(NSMutableArray *)names
{
    [_slices removeAllObjects];
    for(int i=0; i < [names count]; i++) {
       [_slices insertObject:[names objectAtIndex:i] atIndex:_slices.count];
    }
}

#pragma mark - Delegation from YBISettingsViewController
- (void)setSettingsDelegate:(YBISettingsViewController *)svc {
    svc.delegate = self;
}

- (void)settingsViewController:(YBISettingsViewController *)svc didSelectList:(NSMutableArray *)list {
    [_slices removeAllObjects];
    for(int i=0; i < [list count]; i++) {
        [_slices insertObject:[list objectAtIndex:i] atIndex:_slices.count];
    }
    
    _winnerLabel.transform = CGAffineTransformIdentity;
    [self resetViewOnReturnFromBackground];
    [self reloadPie];
}

- (IBAction)pieChartTapped:(UITapGestureRecognizer *)sender {
    UIView *view = sender.view;
}

#pragma mark - Helper Methods
- (void)reloadPie {
    [self.pieChart reloadData];
    
    if (_pieChartHasRelocated == NO) {
        [self movePieChartConstraintWithOptions:UIViewAnimationOptionCurveEaseInOut];
    }
    
    [self.navigationItem.rightBarButtonItem setTitle:@"Edit"];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [_piePlaceholder setHidden:YES];
    [_rotateButton setHidden:YES];
    [_rotateButton setEnabled:YES];
    [_rotateButton setTitle:@"GO" forState:UIControlStateNormal];
    [_rotateButton setImage:[UIImage imageNamed:@"go.png"] forState:UIControlStateNormal];
    [_rotateButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [[_rotateButton titleLabel] setFont:[UIFont systemFontOfSize:32]];
    [_rotateButton setHidden:NO];
}

#pragma mark - RevealView Methods
- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position; {
    if (position == 4 && [_hamburgerButton hamburgerState] == 0) {
        [_hamburgerButton switchState];
    } else if (position == 3 && [_hamburgerButton hamburgerState] == 1) {
        [_hamburgerButton switchState];
    }
}
@end
