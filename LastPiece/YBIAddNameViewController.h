//
//  YBIAddNameViewController.h
//  LastPiece
//
//  Created by Alex Pojman on 8/8/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBINameCell.h"

@class YBIAddNameViewController;
@protocol YBIAddNameViewControllerDelegate <NSObject>

- (void)addNameViewController:(YBIAddNameViewController *)pvc didFinishAddingNames:(NSMutableArray *)names;
@end

@interface YBIAddNameViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, YBINameCellDelegate>

@property (nonatomic, weak) id<YBIAddNameViewControllerDelegate> delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil namesList:(NSMutableArray *)currentNamesList;

@end
