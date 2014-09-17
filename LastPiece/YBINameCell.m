//
//  YBINameCell.m
//  LastPiece
//
//  Created by Alex Pojman on 8/8/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBINameCell.h"
#define OFFSET 14
@interface YBINameCell ()



@end
@implementation YBINameCell

- (void)awakeFromNib
{
    // Initialization code
    self.nameField.delegate = self;
    UIFont *font=[UIFont fontWithName:@"MyriadPro-Regular" size:16];
    [self.nameField setFont:font];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.nameField.center = CGPointMake(self.nameField.center.x+OFFSET, self.nameField.center.y);
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.nameField.center = CGPointMake(self.nameField.center.x-OFFSET, self.nameField.center.y);
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
