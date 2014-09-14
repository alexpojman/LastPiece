//
//  YBINameCell.m
//  LastPiece
//
//  Created by Alex Pojman on 8/8/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBINameCell.h"
@interface YBINameCell ()



@end
@implementation YBINameCell

- (void)awakeFromNib
{
    // Initialization code
    self.nameField.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Notify YBIAddNameViewController if field was updated at all
    if ([_delegate respondsToSelector:@selector(nameCell:didUpdateField:)]) {
        [_delegate nameCell:self didUpdateField:self.nameField.text];
    }
}

// Dismiss the keyboard on "Return" button being pressed
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [textField resignFirstResponder];
}

@end
