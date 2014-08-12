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


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil namesList:(NSMutableArray *)currentNamesList
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        // Nav bar items
        self.navigationItem.title = @"Slice List";
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        
        self.navigationItem.rightBarButtonItem = doneItem;
        
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        
        self.navigationItem.leftBarButtonItem = cancelItem;
        
        // Initialize namesList
        self.namesList = [[NSMutableArray alloc] initWithObjects:nil];
        [self.namesList addObjectsFromArray:(NSArray *)currentNamesList];
        
    }
    return self;
}

- (void)done:(id)sender
{
    [self sendArrayNamesBack];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the NIB file
    UINib *nib = [UINib nibWithNibName:@"YBINameCell" bundle:nil];
    
    // Register this NIB, which contains the cell
    [self.usersTable registerNib:nib forCellReuseIdentifier:@"YBINameCell"];
    
    
    [self.addUserButton setEnabled:NO];
   
    // Initializd tableView with currentList
    for (int i=0; i < [self.namesList count]; i++) {
        [self.usersTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
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
    // TODO delete?
    
    YBINameCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YBINameCell" forIndexPath:indexPath];
    
    NSString *name = [self.namesList objectAtIndex:indexPath.row];
    cell.nameField.text = name;

    // Logic for alternating row color
    if (indexPath.row % 2 == 0) {
        //cell.backgroundColor = FlatTeal;
        cell.nameField.backgroundColor = FlatTeal;
    } else {
        //cell.backgroundColor = FlatBlue;
        cell.nameField.backgroundColor = FlatBlue;
    }

    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [self addNewUser:self];
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}

// When userTextField editing stage changes
- (IBAction)editingChanged:(id)sender
{
    if ([self.userTextField.text isEqual: @""]) {
        [self.addUserButton setEnabled:NO];
    } else {
        [self.addUserButton setEnabled:YES];
    }
}

// TODO Dont send back duplicates
- (void)sendArrayNamesBack
{
    NSMutableArray *finalNames = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.usersTable numberOfRowsInSection:0]; i++) {
       
        YBINameCell *curCell = (YBINameCell*)[self.usersTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [finalNames addObject:curCell.nameField.text];
    }
    
    if ([_delegate respondsToSelector:@selector(addNameViewController:didFinishAddingNames:)]) {
        [_delegate addNameViewController:self didFinishAddingNames:finalNames];
    }
}


@end
