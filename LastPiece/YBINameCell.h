//
//  YBINameCell.h
//  LastPiece
//
//  Created by Alex Pojman on 8/8/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YBINameCell;
@protocol YBINameCellDelegate <NSObject>

- (void)nameCell:(YBINameCell *)nc didUpdateField:(NSString *)updatedField;

@end

@interface YBINameCell : UITableViewCell <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (nonatomic, weak) id<YBINameCellDelegate> delegate;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

@end
