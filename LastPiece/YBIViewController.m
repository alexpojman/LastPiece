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

@implementation YBIViewController

@synthesize pieChart = _pieChart;
@synthesize slices = _slices;
@synthesize sliceColors = _sliceColors;
@synthesize progressBar;
@synthesize progressValue;

static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, center.x, center.y);
    
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    CGPathCloseSubpath(path);
    
    return path;
}

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
        navItem.title = @"Last Piece!";
        
        // Create a new bar button item that will send addNewItem to BNRItemsViewController
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(addParticipants:)];
        
        // Left Bar Navigation Item Setup
        navItem.leftBarButtonItem = bbi;
        [navItem.leftBarButtonItem setTintColor:ContrastColorOf(ComplementaryColorOf(self.view.backgroundColor))];
        
        [[UINavigationBar appearance] setBarTintColor:self.view.backgroundColor];
        [self.view setBackgroundColor:FlatMint];
        
        // Set font for Nav Item
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [UIFont fontWithName:@"MyriadPro-Regular" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
        
        _animating = NO;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

- (IBAction)addParticipants:(id)sender
{

    YBIAddNameViewController *advc = [[YBIAddNameViewController alloc] initWithNibName:nil bundle:nil namesList:_slices];
    
    advc.delegate = self;
    
    // Delselect the winning slice
    self.pieChart.sliceAnimating = NO;
    
    [self.navigationController pushViewController:advc animated:YES];
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
    self.sliceColors = [NSArray arrayWithObjects:
                       [UIColor blueColor],
                       [UIColor colorWithRed:129/255.0 green:195/255.0 blue:29/255.0 alpha:1],
                       [UIColor colorWithRed:62/255.0 green:173/255.0 blue:219/255.0 alpha:1],
                       [UIColor colorWithRed:229/255.0 green:66/255.0 blue:115/255.0 alpha:1],
                       [UIColor colorWithRed:148/255.0 green:141/255.0 blue:139/255.0 alpha:1],nil];
    
    //Initialize the YBISwirlGestureRecognizer for spinning the wheel
    self.swirlGestureRecognizer = [[YBISwirlGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(rotationAction:)];
    [self.swirlGestureRecognizer setDelegate:self];
    [self.pieChart addGestureRecognizer:self.swirlGestureRecognizer];
    
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
        [_rotateButton setTitle:@"Add at least two slices to spin!" forState:UIControlStateNormal];
        [_rotateButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    } else {
        [self.navigationItem.leftBarButtonItem setTitle:@"Edit"];
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
        [_piePlaceholder setHidden:YES];
        [_rotateButton setHidden:YES];
        [_rotateButton setEnabled:YES];
        [_rotateButton setTitle:@"GO" forState:UIControlStateNormal];
        [_rotateButton setImage:[UIImage imageNamed:@"go.png"] forState:UIControlStateNormal];
        [_rotateButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [[_rotateButton titleLabel] setFont:[UIFont systemFontOfSize:32]];
        [_rotateButton setHidden:NO];
        
    }

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


- (IBAction) rotate:(UIButton *)sender
{
    if([[[_rotateButton titleLabel] text] isEqual: @"GO"]) {
        
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

- (void) fadeButtonWithOptions: (UIViewAnimationOptions) options newAlpha:(float)newAlpha buttonToDisplay:(NSString*)buttonName
{
    [UIView animateWithDuration:.1f
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
    // this spin completes 360 degrees every 2 seconds
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
    _winnerLabel.Text = [NSString stringWithFormat:@"Winner is: %@", self.slices[currentPotentialWinnerIndex]];
    [self.pieChart setSliceSelectedAtIndex:currentPotentialWinnerIndex];
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

#pragma mark - YBIPieChart Delegate
- (void)pieChart:(YBIPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index
{
   // NSLog(@"will select slice at index %lu",(unsigned long)index);
}
- (void)pieChart:(YBIPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index
{
   // NSLog(@"will deselect slice at index %lu",(unsigned long)index);
}
- (void)pieChart:(YBIPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index
{
   // NSLog(@"did deselect slice at index %lu",(unsigned long)index);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegation from YBIAddNameViewController

- (void)addNameViewController:(YBIAddNameViewController *)pvc didFinishAddingNames:(NSMutableArray *)names
{
    [_slices removeAllObjects];
    for(int i=0; i < [names count]; i++) {
        [_slices insertObject:[names objectAtIndex:i] atIndex:_slices.count];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark - Swirl Gesture Recognizer
- (void)rotationAction:(id)sender {
    
    if([(YBISwirlGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
        // Event only fires if user has rotated some
        if(self.bearing > 0.0) {
            // Insert code here for moving backwards
            [self resetRotationAction:UIViewAnimationOptionCurveEaseInOut delay:0.5f];
        }
        
        return;
    }
    
    CGFloat direction = ((YBISwirlGestureRecognizer*)sender).currentAngle
    - ((YBISwirlGestureRecognizer*)sender).previousAngle;
    
    if (direction > 0.0) {
    self.bearing += 180 * direction / M_PI;
    CGAffineTransform knobTransform = self.pieChart.transform;
    
    CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, direction);
    
    [self.pieChart setTransform:newKnobTransform];
    
    
        
       /* CGPathRef path = CGPathCreateArc(_pieChart.pieCenter, _pieChart.pieRadius, -M_PI/2, DEGREES_TO_RADIANS(self.bearing));
        CAShapeLayer *obj = [[CAShapeLayer alloc] init];
        [obj setPath:path];
        [[_pieChart layer] addSublayer:obj];*/
    }
    
    // Adjust progress bar accordingly
    if(!progressBar.isHidden) {
        progressValue = lroundf(self.bearing) / 360.0f;
        progressBar.progress = progressValue;
        
        
        // Once progress bar becomes full
        if (self.bearing >= 360.0) {
            progressValue = 0.0;
            progressBar.progress = progressValue;
            [progressBar setHidden:YES];
            
            // Remove Touch Input to prevent errorneous spinning
            [_pieChart setUserInteractionEnabled:NO];
            
            //TODO: Make sure that bearing is at 0.0 -> rotate one last time
           
            if (self.bearing > 360.0) {
                CGAffineTransform knobTransform = self.pieChart.transform;
                CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, DEGREES_TO_RADIANS(360.0 - self.bearing));
        
                self.bearing = 0.0;
                [self.pieChart setTransform:newKnobTransform];
                progressValue = self.bearing / 360.0f;
                progressBar.progress = progressValue;
            }
            // Open Slice List
            [self addParticipants:self];
        }
    }

}

- (void)resetRotationAction:(UIViewAnimationOptions) options delay:(float)delay{
    
    float resetSpeed = -0.1;
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.00001f
                          delay: delay
                        options: options
                     animations: ^{
                         if (self.bearing + ((180.0f * resetSpeed) / M_PI) > 0.0) {
                         CGAffineTransform knobTransform = self.pieChart.transform;
                         
                         
                         CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, resetSpeed);
                         
                         self.bearing += 180.0f * resetSpeed / M_PI;
                         [self.pieChart setTransform:newKnobTransform];
                         progressValue = self.bearing / 360.0f;
                         progressBar.progress = progressValue;
                         }

                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if(self.bearing + (180.0f * resetSpeed / M_PI) > 0.0) {
                                 [self resetRotationAction:UIViewAnimationOptionCurveEaseIn delay:0.0f];
                             } else {
                                
                                 CGAffineTransform knobTransform = self.pieChart.transform;
                                 CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, (-self.bearing * M_PI) / 180.0f);
                                 
                                 self.bearing = 0.0;
                                 [self.pieChart setTransform:newKnobTransform];
                                 progressValue = self.bearing / 360.0f;
                                 progressBar.progress = progressValue;
                             }
                        }
                     }];

}

@end
