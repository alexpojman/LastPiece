//
//  YBIListCell.h
//  LastPiece
//
//  Created by Alex Pojman on 12/18/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YBIListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *listName;
@property (weak, nonatomic) IBOutlet UILabel *containedSlices;
@property (strong, nonatomic) IBOutlet UILabel *sliceCount;

@end
