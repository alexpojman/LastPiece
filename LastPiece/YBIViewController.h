//
//  YBIViewController.h
//  LastPiece
//
//  Created by Alex Pojman on 7/29/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBIPieChart.h"
#import "YBIAddNameViewController.h"
#import "YBISwirlGestureRecognizer.h"
@interface YBIViewController : UIViewController <YBIPieChartDelegate, YBIPieChartDataSource, YBIAddNameViewControllerDelegate, YBISwirlGestureRecognizerDelegate>


@property (strong, nonatomic) IBOutlet YBIPieChart *pieChart;
@property (weak, nonatomic) IBOutlet UIImageView *piePlaceholder;
@property (nonatomic, strong) NSMutableArray *slices;
@property (nonatomic, strong) NSArray        *sliceColors;
@property (weak, nonatomic) IBOutlet UIButton *rotateButton;
@property (weak, nonatomic) IBOutlet UILabel *winnerLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (nonatomic) BOOL animating;
@property (nonatomic) float progressValue;
@property (strong, nonatomic) NSArray *currentNames;           // To Be used to pass back
@property (strong, nonatomic) YBISwirlGestureRecognizer *swirlGestureRecognizer;
@property (nonatomic) float bearing;
@property (nonatomic) float pieChartRotationOffset;
@property (nonatomic) int requiredSpinsToStart;             // The number of initial spins required to begin app for first time
@property (nonatomic) BOOL isSpinningRight;                 // Determines if user is manually spinning circle right
@end
