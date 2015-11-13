//
//  YBISettingsViewController.h
//  LastPiece
//
//  Created by Alex Pojman on 6/14/15.
//  Copyright (c) 2015 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"

@class YBISettingsViewController;
@protocol YBISettingsViewControllerDelegate <NSObject>

- (void)settingsViewController:(YBISettingsViewController *)svc didSelectList:(NSMutableArray *)list;

@end

@interface YBISettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id<YBISettingsViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITableView *listTable;
@property (strong, nonatomic) IBOutlet UIButton *saveListButton;

@end
