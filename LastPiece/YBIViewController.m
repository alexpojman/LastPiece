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
#define paletteYellow    0xFFDC50
#define paletteYellowAlt 0xFFFC50

@implementation YBIViewController

@synthesize pieChart = _pieChart;
@synthesize slices = _slices;
@synthesize sliceColors = _sliceColors;
@synthesize progressBar;
@synthesize progressValue;

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
                
            }
            if(result.height == 568)
            {
                nibName = @"YBIViewController";
            }
        }
        self = [super initWithNibName:nibName bundle:nil];
        
        UINavigationItem *navItem = self.navigationItem;
        navItem.title = @"LAST PIECE";
        
        // Create a new bar button item that will send addNewItem to BNRItemsViewController
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(addParticipants:)];
        
        // Left Bar Navigation Item Setup
        navItem.leftBarButtonItem = bbi;
        //[navItem.leftBarButtonItem setTintColor:[UICOl]];
        
        //TODO: Decide if we want border around frame
        CGFloat borderWidth = 2.0f;
        
        self.view.frame = CGRectInset(self.view.frame, -borderWidth, -borderWidth);
        self.view.layer.borderColor = UIColorFromRGB(paletteOrange).CGColor;
        self.view.layer.borderWidth = borderWidth;
        
        // Set Colors
        [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          UIColorFromRGB(paletteOrange), NSForegroundColorAttributeName,
          [UIFont fontWithName:@"MyriadPro-BoldCond" size:21],
          NSFontAttributeName, nil]];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        [self.progressBar setProgressTintColor:UIColorFromRGB(paletteOrange)];
        [self.progressBar setTrackTintColor:UIColorFromRGB(paletteYellow)];
        
        // Set font for Nav Item
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [UIFont fontWithName:@"MyriadPro-Regular" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];

        
        // Set font for winner label
        UIFont *font=[UIFont fontWithName:@"MyriadPro-Regular" size:24];
        [self.winnerLabel setFont:font];
        
        // Starting pieChart bool values
        _animating = NO;
        _pieChartHasRelocated = NO;
        
        // Establish requiredSpinsToStart
        _requiredSpinsToStart = 4;
        
        
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
    
    // Do any additional setup after loading the view from its nib.
    self.slices = [[NSMutableArray alloc] init];
    
    NSArray *names = [NSArray arrayWithObjects:nil];
    for(int i = 0; i < names.count; i ++)
    {
        NSString *sliceLabels = names[i];
        [_slices addObject:sliceLabels];
    }
    
  
    [self.pieChart setDelegate:self];
    [self.pieChart setDataSource:self];
    
    
    [self.pieChart setLabelColor:[UIColor blackColor]];
    
    // Color for selecting slice
    if ([_slices count] < 6) {
    self.sliceColors = [NSArray arrayWithObjects:
                       UIColorFromRGB(paletteBlue),
                       UIColorFromRGB(paletteGreen),
                       UIColorFromRGB(paletteOrange),
                       UIColorFromRGB(paletteRed),
                       UIColorFromRGB(paletteYellow),
                        UIColorFromRGB(paletteBlueAlt),
                        UIColorFromRGB(paletteGreenAlt),
                        UIColorFromRGB(paletteOrangeAlt),
                        UIColorFromRGB(paletteRedAlt),
                        UIColorFromRGB(paletteYellowAlt),
                      nil];
    }


    
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
        [self.navigationItem.leftBarButtonItem setTitle:@""];
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        [_rotateButton setEnabled:NO];
        [[_rotateButton titleLabel] setFont:[UIFont systemFontOfSize:15]];
    } else {
        if (_pieChartHasRelocated == NO) {
            [self movePieChartConstraintWithOptions:UIViewAnimationOptionCurveEaseInOut];
        }
        [self.navigationItem.leftBarButtonItem setTitle:@"Edit"];
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
        [_piePlaceholder setHidden:YES];
        //[_spinToBeginLogo setHidden:YES];
        [_rotateButton setHidden:YES];
        [_rotateButton setEnabled:YES];
        [_rotateButton setTitle:@"GO" forState:UIControlStateNormal];
        [_rotateButton setImage:[UIImage imageNamed:@"go.png"] forState:UIControlStateNormal];
        [_rotateButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [[_rotateButton titleLabel] setFont:[UIFont systemFontOfSize:32]];
        [_rotateButton setHidden:NO];
        
    }
    
    // Reset winner label
    _winnerLabel.transform = CGAffineTransformIdentity;

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
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
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
- (IBAction) rotate:(UIButton *)sender
{
    if([[[_rotateButton titleLabel] text] isEqual: @"GO"]) {
        if (self.pieChart.sliceAnimating == YES) {
            [self animateWinnerLabel:UIViewAnimationOptionCurveEaseInOut moveBehavior:@"MoveOffScreen"];
        }
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        [self fadeButtonWithOptions:UIViewAnimationOptionCurveEaseIn newAlpha:0 buttonToDisplay:@"STOP"];
        for (int i=0; i < [self numberOfSlicesInPieChart:self.pieChart]; i++) {
            [self.pieChart setSliceDeselectedAtIndex:i];
        }
        if (!_animating) {
            _animating = YES;
            [self spinWithOptions: UIViewAnimationOptionCurveLinear];
        }
    } else if([[[_rotateButton titleLabel] text] isEqual: @"STOP"]) {
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
        [self fadeButtonWithOptions:UIViewAnimationOptionCurveEaseIn newAlpha:0 buttonToDisplay:@"GO"];
        _animating = NO;
        self.pieChart.sliceAnimating = NO;
    }
}

#pragma mark - Animation Methods
- (void) fadeButtonWithOptions: (UIViewAnimationOptions) options newAlpha:(float)newAlpha buttonToDisplay:(NSString*)buttonName
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

- (void) spinWithOptions: (UIViewAnimationOptions) options
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

- (void) movePieChartConstraintWithOptions: (UIViewAnimationOptions) options
{
    [UIView animateWithDuration: 1.5f
                          delay: 0.5f
                        options: options
                     animations: ^{
                         // Move pie chart
                         //TODO: update variables instead of magic numbers
                         [self.pieChart setFrame:CGRectMake(160, 450, 280, 280)];
                         self.pieChart.transform = CGAffineTransformTranslate(self.pieChart.transform, self.pieChart.transform.tx, self.pieChart.transform.ty - 130);
                         
                         // Move the progress bar
                         [self.progressBar setFrame:CGRectMake(40, 495, 250, 60)];
                         self.progressBar.transform = CGAffineTransformTranslate(self.progressBar.transform, self.progressBar.transform.tx - 1000, self.progressBar.transform.ty);
                         
                         // Move Spin logo
                         [self.spinToBeginLogo setFrame:CGRectMake(self.spinToBeginLogo.transform.tx + 160, self.spinToBeginLogo.transform.ty - 200, self.spinToBeginLogo.frame.size.width, self.spinToBeginLogo.frame.size.height)];
                         self.spinToBeginLogo.transform = CGAffineTransformTranslate(self.spinToBeginLogo.transform, self.spinToBeginLogo.transform.tx, self.spinToBeginLogo.transform.ty - 2000);
                         
                         // Move the rotate button
                         self.rotateButton.transform = CGAffineTransformTranslate(self.rotateButton.transform, self.rotateButton.transform.tx, self.rotateButton.transform.ty - 300);
                         
                         // Move ticker symbol
                         self.tickerSymbol.transform = CGAffineTransformTranslate(self.tickerSymbol.transform, self.tickerSymbol.transform.tx - 90, self.tickerSymbol.transform.ty);
                     }
                     completion: ^(BOOL finished) {
                         _pieChartHasRelocated = YES;
                         [self.progressBar setHidden:YES];

                         
                     }];
}

#pragma mark - Nav-Related Methods
- (IBAction)addParticipants:(id)sender
{
    
    YBIAddNameViewController *advc = [[YBIAddNameViewController alloc] initWithNibName:nil bundle:nil namesList:_slices];
    
    advc.delegate = self;
    
    // Delselect the winning slice
    self.pieChart.sliceAnimating = NO;
    
    [self.navigationController pushViewController:advc animated:YES];
}

#pragma mark - ChooseWinner Methods
-(void)chooseIndexOfWinningSlice
{
    // Calculate true middle angle for each slice layer
    // = (rotate offset + middle angle(original)) - (2pi * number of slices)
    //self.pieChartRotationOffset
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
        

        //TODO: Calcuate Lowest value, need to change initial "if" to test for dupes
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
    
    if ([self.slices[currentPotentialWinnerIndex] length] > 10) {
        winnerText = [NSString stringWithFormat:@"%@...",[self.slices[currentPotentialWinnerIndex] substringToIndex:10]];
    }
    _winnerLabel.Text = [NSString stringWithFormat:@"%@ is the winner!", winnerText];
    
    // Set winner label background to winning slice color
    if(currentPotentialWinnerIndex >= _sliceColors.count) {
        _winnerLabel.backgroundColor = _sliceColors[currentPotentialWinnerIndex - _sliceColors.count];
    } else {
        _winnerLabel.backgroundColor = _sliceColors[currentPotentialWinnerIndex];
    }
    // Animate winner label
    [self animateWinnerLabel:UIViewAnimationOptionCurveEaseInOut moveBehavior:@"MoveOnScreen"];
    [self.pieChart setSliceSelectedAtIndex:currentPotentialWinnerIndex];
     
}

// TODO: Change so that no "magic numbers" are used
- (void)animateWinnerLabel: (UIViewAnimationOptions) options moveBehavior:(NSString *)moveBehavior
{
    [UIView animateWithDuration: 0.4f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         if ([moveBehavior isEqual:@"MoveOnScreen"])
                         {
                             _winnerLabel.transform = CGAffineTransformTranslate(_winnerLabel.transform, 820, _winnerLabel.transform.ty);
                         }
                         else if ([moveBehavior isEqual:@"MoveOffScreen"]) {
                             [_winnerLabel setFrame:CGRectMake(_winnerLabel.transform.tx + 820, _winnerLabel.transform.ty, _winnerLabel.frame.size.width, _winnerLabel.frame.size.height)];
                             _winnerLabel.transform = CGAffineTransformTranslate(_winnerLabel.transform, 820, _winnerLabel.transform.ty);
                         }
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if ([moveBehavior isEqual:@"MoveOffScreen"]) {
                                 _winnerLabel.transform = CGAffineTransformIdentity;                             }
                         
                         }
                     }];
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


#pragma mark - Swirl Gesture Recognizer

- (void)rotationDidChangeByAngle:(CGFloat)angle {
    
    self.pieChart.transform = CGAffineTransformRotate(self.pieChart.transform, DEGREES_TO_RADIANS(-angle));
    self.bearing += (-angle);
    
    //TODO fix this, still a bit weird
  

    progressValue = ABS(lroundf(self.bearing)) / (360.0f * _requiredSpinsToStart);
    
    progressBar.progress = progressValue;
    
    if ((self.bearing >= 360.0f * _requiredSpinsToStart) || (self.bearing <= -360.0f * _requiredSpinsToStart)) {
        [_rotationControl endDeceleration];
    }
}

- (void)decelerationDidEnd {
    if((self.bearing >= 360.0f * _requiredSpinsToStart) || (self.bearing <= -360.0f * _requiredSpinsToStart)) {
        // Remove Touch Input to prevent errorneous spinning
        [_rotationControl setUserInteractionEnabled:NO];
        
        CGAffineTransform knobTransform = self.pieChart.transform;
        CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, DEGREES_TO_RADIANS((360.0 * _requiredSpinsToStart) - self.bearing));
     
     
        [self.pieChart setTransform:newKnobTransform];
    
        [self addParticipants:self];
    }
}

- (void)resetRotationAction:(UIViewAnimationOptions) options delay:(float)delay{
    
    // Get resetSpeed based on direction spun
    float resetSpeed;
    if (self.bearing < 0.0f)
    {
        resetSpeed = 0.5f;
    } else if (self.bearing > 0.0f){
        resetSpeed = -0.5f;
    }
    
    [UIView animateWithDuration: 0.00001f
                          delay: delay
                        options: options
                     animations: ^{
                         if (((resetSpeed < 0.0f) && (self.bearing + ((180.0f * resetSpeed) / M_PI) > 0.0)) || ((resetSpeed > 0.0f) && (self.bearing + ((180.0f * resetSpeed) / M_PI) < 0.0))){
                             
                         CGAffineTransform knobTransform = self.pieChart.transform;
                         CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, resetSpeed);
                         
                         self.bearing += 180.0f * resetSpeed / M_PI;
                         [self.pieChart setTransform:newKnobTransform];

                         }

                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             progressValue = ABS(self.bearing / (360.0f * _requiredSpinsToStart));
                             progressBar.progress = progressValue;
                             if (((resetSpeed < 0.0f) && (self.bearing + ((180.0f * resetSpeed) / M_PI) > 0.0)) || ((resetSpeed > 0.0f) && (self.bearing + ((180.0f * resetSpeed) / M_PI) < 0.0))) {
                                 [self resetRotationAction:UIViewAnimationOptionCurveEaseIn delay:0.0f];
                             } else {
                                
                                 CGAffineTransform knobTransform = self.pieChart.transform;
                                 CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, (-self.bearing * M_PI) / 180.0f);
                                 
                                 self.bearing = 0.0;
                                 [self.pieChart setTransform:newKnobTransform];
                                 progressValue = self.bearing / (360.0f * _requiredSpinsToStart);
                                 progressBar.progress = progressValue;
                             }
                        }
                     }];

}

@end
