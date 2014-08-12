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

@implementation YBIViewController

@synthesize pieChart = _pieChart;
@synthesize slices = _slices;
@synthesize sliceColors = _sliceColors;

// TODO move this variable
BOOL animating = NO;

- (instancetype)init
{
    if (self) {
        UINavigationItem *navItem = self.navigationItem;
        navItem.title = @"Last Piece!";
        
        // Create a new bar button item that will send addNewItem to BNRItemsViewController
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addParticipants:)];
        
        // Right Bar Navigation Item Setup
        navItem.rightBarButtonItem = bbi;
        [navItem.rightBarButtonItem setTintColor:ContrastColorOf(ComplementaryColorOf(self.view.backgroundColor))];
        
        // Left Bar Navigation Item Setup
        navItem.leftBarButtonItem = self.editButtonItem;
        [navItem.leftBarButtonItem setTintColor:ContrastColorOf(ComplementaryColorOf(self.view.backgroundColor))];
        
        [[UINavigationBar appearance] setBarTintColor:self.view.backgroundColor];
        [self.view setBackgroundColor:FlatMint];
        
        // Set Button Colors
        [_rotateButton setTitleColor:ComplementaryColorOf(self.view.backgroundColor) forState:UIControlStateNormal];
        
    }
    
    return self;
}

// TODO 
- (IBAction)addParticipants:(id)sender
{

    YBIAddNameViewController *advc = [[YBIAddNameViewController alloc] initWithNibName:nil bundle:nil namesList:_slices];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:advc];
    
    navController.modalPresentationStyle = UIModalTransitionStyleFlipHorizontal;
    
    advc.delegate = self;
    
    [self presentViewController:navController animated:YES completion:nil];
}


// Fix initial loading
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.slices = [NSMutableArray arrayWithCapacity:10];
    
    // TODO: Change this to array of names from table list
    NSArray *names = [NSArray arrayWithObjects:nil];
    for(int i = 0; i < names.count; i ++)
    {
        NSString *sliceLabels = names[i];
        [_slices addObject:sliceLabels];
    }
    
    
    [self.pieChart setDelegate:self];
    [self.pieChart setDataSource:self];
    
   
    [self.pieChart setLabelColor:[UIColor blackColor]];
    
    self.sliceColors = [NSArray arrayWithObjects:
                       [UIColor blueColor],
                       [UIColor colorWithRed:129/255.0 green:195/255.0 blue:29/255.0 alpha:1],
                       [UIColor colorWithRed:62/255.0 green:173/255.0 blue:219/255.0 alpha:1],
                       [UIColor colorWithRed:229/255.0 green:66/255.0 blue:115/255.0 alpha:1],
                       [UIColor colorWithRed:148/255.0 green:141/255.0 blue:139/255.0 alpha:1],nil];
    
    // Initialize the YBISwirlGestureRecognizer for spinning the wheel
    self.swirlGestureRecognizer = [[YBISwirlGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(rotationAction:)];
    [self.swirlGestureRecognizer setDelegate:self];
    [self.pieChart addGestureRecognizer:self.swirlGestureRecognizer];
    
    [self.pieChart setTranslatesAutoresizingMaskIntoConstraints:YES];
    

}
- (void)viewDidUnload
{
    [self setPieChart:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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


- (IBAction) rotate:(UIButton *)sender {
    if (!animating) {
        animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (IBAction) stopRotate:(UIButton *)sender {
    // set the flag to stop spinning after one last 90 degree increment
    animating = NO;
    CGPoint point = CGPointMake(120, 120);
    [self.pieChart setSliceSelectedAtPoint:point];
}

- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.25f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.pieChart.transform = CGAffineTransformRotate(_pieChart.transform, M_PI / 2.0);
                         self.pieChartRotationOffset += (M_PI / 2.0);
                         if(self.pieChartRotationOffset >= M_PI * 2) {
                             self.pieChartRotationOffset = 0.0;
                         }
                         
                         NSLog(@"%f", self.pieChartRotationOffset);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                                // self.pieChart.transform = CGAffineTransformRotate(_pieChart.transform, M_PI / 1.0);
                             }
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

#pragma mark - YBIPieChart Delegate
- (void)pieChart:(YBIPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will select slice at index %lu",(unsigned long)index);
}
- (void)pieChart:(YBIPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will deselect slice at index %lu",(unsigned long)index);
}
- (void)pieChart:(YBIPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"did deselect slice at index %lu",(unsigned long)index);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegation from YBIAddNameViewController

// TODO implement this to do something useful
- (void)addNameViewController:(YBIAddNameViewController *)pvc didFinishAddingNames:(NSArray *)names
{
    // Update or Add slices based on slice list
    for (int i=0; i < [names count]; i++) {
        if ([_slices count] > i) {
            [_slices replaceObjectAtIndex:i withObject:[names objectAtIndex:i]];
        } else {
            [_slices insertObject:[names objectAtIndex:i] atIndex:_slices.count];
        }
        
    }
    
    
}

#pragma mark - Swirl Gesture Recognizer
- (void)rotationAction:(id)sender {
    
    if([(YBISwirlGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        return;
    }
    
    CGFloat direction = ((YBISwirlGestureRecognizer*)sender).currentAngle
    - ((YBISwirlGestureRecognizer*)sender).previousAngle;
    
    self.bearing += 180 * direction / M_PI;
    
    if (self.bearing < -0.5) {
        self.bearing += 360;
    }
    else if (self.bearing > 359.5) {
        self.bearing -= 360;
    }
    
    CGAffineTransform knobTransform = self.pieChart.transform;
    
    CGAffineTransform newKnobTransform = CGAffineTransformRotate(knobTransform, direction);
    
    [self.pieChart setTransform:newKnobTransform];
    
    //self.pieChart.position.text = [NSString stringWithFormat:@"%d°", (int)lroundf(self.bearing)];
}

@end
