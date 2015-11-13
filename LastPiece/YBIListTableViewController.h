//
//  YBIListTableViewController.h
//  LastPiece
//
//  Created by Alex Pojman on 12/18/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YBIListTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil namesList:(NSMutableArray *)currentNamesList;
@end
