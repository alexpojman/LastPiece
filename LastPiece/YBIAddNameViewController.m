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

@interface YBIAddNameViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addUserButton;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (strong, nonatomic) NSMutableArray *namesList;
@property (strong, nonatomic) NSIndexPath *currentIndexPaths;
@end

@implementation YBIAddNameViewController

//TODO is this necessary?
@synthesize usersTable;
@synthesize namesList;

#pragma mark - initialization methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil namesList:(NSMutableArray *)currentNamesList
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        // Nav bar items
        self.navigationItem.title = @"Slice List";
        
        UIBarButtonItem *finishItem = [[UIBarButtonItem alloc] initWithTitle:@"Finish" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
        
        self.navigationItem.rightBarButtonItem = finishItem;
        
        self.navigationItem.leftBarButtonItem = [self editButtonItem];
        
        // Initialize namesList
        self.namesList = [[NSMutableArray alloc] initWithObjects:nil];
        [self.namesList addObjectsFromArray:(NSArray *)currentNamesList];
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
    
    
    [self.addUserButton setEnabled:NO];
    
    // Initialized tableView with currentList
    for (int i=0; i < [self.namesList count]; i++) {
        [self.usersTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    // Set Color for UsersTable and Main View Background
    [self.usersTable setBackgroundColor:FlatWhite];
    [self.view setBackgroundColor:FlatMint];
    
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
    //TODO deselect any cell
    
    [self.view endEditing:YES];
    [self sendArrayNamesBack];
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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

    // Logic for alternating row color
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = FlatTeal;
        //cell.nameField.backgroundColor = FlatTeal;
    } else {
        cell.backgroundColor = FlatBlue;
        //cell.nameField.backgroundColor = FlatBlue;
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
@end
