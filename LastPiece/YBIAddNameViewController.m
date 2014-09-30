//
//  YBIAddNameViewController.m
//  LastPiece
//
//  Created by Alex Pojman on 8/8/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBIAddNameViewController.h"
#import "YBINameCell.h"
#import "Chameleon.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define paletteBlue      0x61ADFF
#define paletteBlueAlt   0x61CDFF
#define paletteGreen     0x8AD998
#define paletteGreenAlt  0x8AF998
#define paletteRed       0xFF5A4F
#define paletteRedAlt    0xFF7A4F
#define paletteOrange    0xFFB13F
#define paletteOrangeAlt 0xFFD13F
#define paletteYellow    0xFFDC50
#define paletteYellowAlt 0xFFFC50

@interface YBIAddNameViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addUserButton;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UIView *instructionLabel;
@property (weak, nonatomic) IBOutlet UIView *backgroundFilterView;
@property (weak, nonatomic) IBOutlet UIButton *gotItButton;
@property (strong, nonatomic) NSMutableArray *namesList;
@property (strong, nonatomic) NSIndexPath *currentIndexPaths;
@property (strong, nonatomic) NSArray *sliceColors;
@end

@implementation YBIAddNameViewController

@synthesize usersTable;
@synthesize namesList;

#pragma mark - initialization methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil namesList:(NSMutableArray *)currentNamesList
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        // Nav bar items
        self.navigationItem.title = @"SLICE LIST";
        
        UIBarButtonItem *finishItem = [[UIBarButtonItem alloc] initWithTitle:@"Finish" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
        
        self.navigationItem.rightBarButtonItem = finishItem;
        
        self.navigationItem.leftBarButtonItem = [self editButtonItem];
        
        // Initialize namesList
        self.namesList = [[NSMutableArray alloc] initWithObjects:nil];
        [self.namesList addObjectsFromArray:(NSArray *)currentNamesList];
        
        // Set Fonts for navItems
        [finishItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [UIFont fontWithName:@"MyriadPro-Regular" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIFont fontWithName:@"MyriadPro-Regular" size:18.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
        
        // Set Slice Colors -> TODO: Change to get this from parent view
        self.sliceColors = [NSArray arrayWithObjects:
                            UIColorFromRGB(paletteBlue),
                            UIColorFromRGB(paletteGreen),
                            UIColorFromRGB(paletteOrange),
                            UIColorFromRGB(paletteRed),
                            UIColorFromRGB(paletteYellow),
                            UIColorFromRGB(paletteBlueAlt),
                            UIColorFromRGB(paletteGreenAlt),
                            UIColorFromRGB(paletteOrangeAlt),
                            UIColorFromRGB(paletteRedAlt),
                            UIColorFromRGB(paletteYellowAlt),
                            nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the NIB file
    UINib *nib = [UINib nibWithNibName:@"YBINameCell" bundle:nil];
    
    // Register this NIB, which contains the cell
    [self.usersTable registerNib:nib forCellReuseIdentifier:@"YBINameCell"];
    
    // Set Fonts for items
    self.userTextField.font =[UIFont fontWithName:@"MyriadPro-Regular" size:18];
    self.addUserButton.titleLabel.font = [UIFont fontWithName:@"MyriadPro-Regular" size:18];
    
    // "Got It!" button style
    self.gotItButton.titleLabel.font = [UIFont fontWithName:@"MyriadPro-BoldCond" size:18];
    self.gotItButton.titleLabel.textColor = [UIColor whiteColor];
    self.gotItButton.layer.cornerRadius = 2;
    self.gotItButton.layer.borderWidth = 1;
    self.gotItButton.layer.borderColor = (__bridge CGColorRef)(UIColorFromRGB(paletteOrange));
    
    // "Add" button should not be enabled on start
    [self.addUserButton setEnabled:NO];
    
    // Make sure userTextField is not enabled at first until instructionLabel is dismissed
    if ([self.namesList count] == 0) {
        [_userTextField setEnabled:NO];
    }
    
    // Initialized tableView with currentList
    for (int i=0; i < [self.namesList count]; i++) {
        [self.usersTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    // Set Color for UsersTable and Main View Background
    [self.usersTable setBackgroundColor:FlatWhite];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    if ([usersTable numberOfRowsInSection:0] == 0) {
        [self animateInstructionLabel:UIViewAnimationOptionCurveEaseInOut animateOffScreen:NO delay:0.0f];
    }
}

- (IBAction)dismissInstructionLabel:(id)sender {
     [self animateInstructionLabel:UIViewAnimationOptionCurveEaseIn animateOffScreen:YES delay:0.0f];
}

#pragma mark - Row Editing
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
   
    
    if (editing) {
        [self.usersTable setEditing:YES animated:YES];
    } else {
        [self.usersTable setEditing:NO animated:YES];
    }

    [self updateColors];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.namesList removeObjectAtIndex:indexPath.row];
        
        // Manual fade animation due to broken views
        UITableViewCell *cell = [self.usersTable cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.25f
                         animations:^{
                             
                             UIScrollView *internalScrollView = (UIScrollView*)cell.contentView.superview;
                             if([internalScrollView isKindOfClass:[UIScrollView class]]){
                                 
                                 [internalScrollView setContentOffset:CGPointZero animated:YES];
                             }
                             
                             cell.center = CGPointMake(cell.center.x - cell.bounds.size.width, cell.center.y);
                             
                         } completion:^(BOOL finished) {
                             
                             [self.usersTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                             [self updateColors];
                         }];
        
    }
    
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController setEditing:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController setEditing:NO];
}

#pragma mark - 
- (void)finish:(id)sender
{
    if ( [self.namesList count] < 2)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hold On A Second!"
														message:@"You need to add at least two slices to choose from!"
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles: nil];
		[alert show];
		
    }
    else {
        [self.view endEditing:YES];
        [self sendArrayNamesBack];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Add Button Tapped
- (IBAction)addNewUser:(id)sender
{
    // Dismiss Keyboard
    [self.view endEditing:YES];
    
    // Disable the "Add" button
    [self.addUserButton setEnabled:NO];
    
    NSString *name = self.userTextField.text;
    [self.namesList addObject:name];
    
    self.userTextField.text = nil;
    [self.userTextField becomeFirstResponder];
    [self.usersTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.namesList count] - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.namesList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YBINameCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YBINameCell" forIndexPath:indexPath];
    
    cell.delegate = self;
    
    NSString *name = [self.namesList objectAtIndex:indexPath.row];
    cell.nameField.text = name;

    // Change Row color
    cell.backgroundColor = FlatTeal;
    
     if(indexPath.row >= _sliceColors.count) {
         cell.backgroundColor = _sliceColors[indexPath.row - _sliceColors.count];
     } else {
         cell.backgroundColor = _sliceColors[indexPath.row];
     }

      
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [self addNewUser:self];
    [textField becomeFirstResponder];
    return YES;
}

- (IBAction)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)editingChanged:(id)sender
{
    if ([self.userTextField.text isEqual: @""]) {
        [self.addUserButton setEnabled:NO];
    } else {
        [self.addUserButton setEnabled:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YBINameCell *selectedCell =(YBINameCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    [selectedCell.nameField becomeFirstResponder];
    [selectedCell.nameField setUserInteractionEnabled:YES];
    [selectedCell textFieldShouldBeginEditing:selectedCell.nameField];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YBINameCell *selectedCell =(YBINameCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    [selectedCell.nameField setUserInteractionEnabled:NO];
    [selectedCell textFieldShouldEndEditing:selectedCell.nameField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

- (void)sendArrayNamesBack
{
    if ([_delegate respondsToSelector:@selector(addNameViewController:didFinishAddingNames:)]) {
        [_delegate addNameViewController:self didFinishAddingNames:namesList];
    }
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)nameCell:(YBINameCell *)nc didUpdateField:(NSString *)updatedField
{
   [namesList replaceObjectAtIndex:[self.usersTable indexPathForCell:nc].row withObject:updatedField];
}

#pragma mark - Animation Methods
- (void)updateColors
{
    [UIView animateWithDuration:0.25f
                     animations:^{
                         // Reload Data for color matching
                         for (int i=0; i < self.namesList.count; i++) {
                             UITableViewCell *curCell = [self.usersTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                             if(i >= _sliceColors.count) {
                                 curCell.backgroundColor = _sliceColors[i - _sliceColors.count];
                             } else {
                                 curCell.backgroundColor = _sliceColors[i];
                             }
                         }
                     }];

}

// TODO: Change so that no "magic numbers" are used
- (void)animateInstructionLabel: (UIViewAnimationOptions) options animateOffScreen:(BOOL)animateOffScreen delay:(float)delay
{
    
    [UIView animateWithDuration: 0.25f
                          delay: delay
                        options: options
                     animations: ^{
                         
                         if (animateOffScreen == NO) {
                             [_instructionLabel setHidden:NO];
                             _instructionLabel.transform = CGAffineTransformTranslate(_instructionLabel.transform, 820, _instructionLabel.transform.ty);
                             
                             // Change filter alpha
                             _backgroundFilterView.alpha = 1.0;
        
                         } else {
                             [_instructionLabel setFrame:CGRectMake(_instructionLabel.transform.tx + 820, _instructionLabel.transform.ty, _instructionLabel.frame.size.width, _instructionLabel.frame.size.height)];
                              _instructionLabel.transform = CGAffineTransformTranslate(_instructionLabel.transform, 820, _instructionLabel.transform.ty);
                             
                             // Change filter alpha
                             _backgroundFilterView.alpha = 0.0;
                           [self.navigationController.navigationBar setHidden:NO];
                           
                         }
                     }
                     completion: ^(BOOL finished) {
                         if (animateOffScreen == YES) {
                             // Select userTextField
                             [_userTextField setEnabled:YES];
                             [_userTextField becomeFirstResponder];
                         } else {
                              [self.navigationController.navigationBar setHidden:YES];
                         }
                     }];
    
}

- (void)dismissInstruction
{
    [self animateInstructionLabel:UIViewAnimationOptionCurveEaseIn animateOffScreen:YES delay:0.0f];
}
@end
