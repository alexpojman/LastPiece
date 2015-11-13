//
//  YBISettingsViewController.m
//  LastPiece
//
//  Created by Alex Pojman on 6/14/15.
//  Copyright (c) 2015 Ya Boi Inc. All rights reserved.
//

#import "YBISettingsViewController.h"
#import "YBIListCell.h"
#import "YBIViewController.h"

@interface YBISettingsViewController ()

@property (strong, nonatomic) NSMutableArray *namesList;
@property (strong, nonatomic) NSIndexPath *currentIndexPaths;
@property (strong, nonatomic) NSArray *sliceColors;
@property (strong, nonatomic) NSMutableArray *listObjects;
@property (strong, nonatomic) YBIViewController *vc;


@end

@implementation YBISettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _vc = (YBIViewController *)[[[self revealViewController] frontViewController] childViewControllers] [0];
    [_vc setSettingsDelegate:self];
    
    // Do any additional setup after loading the view from its nib.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    
    // Load the NIB file
    UINib *nib = [UINib nibWithNibName:@"YBIListCell" bundle:nil];
    
    // Register this NIB, which contains the cell
    [_listTable registerNib:nib forCellReuseIdentifier:@"YBIListCell"];
    
    // Section header font
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"MyriadPro-Regular" size:18]];
    
    // Set Butt
    
    // Initialize Saved Lists
    if (_listObjects == nil) {
        _listObjects = [NSMutableArray array];
    }
    
    // Retrieve current list
    [self retrieveCurrentList];
    
    // Initialize "Save Current List" button
    _saveListButton.layer.cornerRadius = 10;
    _saveListButton.layer.borderWidth = 1;
   
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Retrieve current list
    [self retrieveCurrentList];
    
    // Update table
    [_listTable reloadData];
}

#pragma mark - UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_listObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YBIListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YBIListCell" forIndexPath:indexPath];
    
    cell.listName.text = [[_listObjects objectAtIndex:indexPath.row ] objectForKey:@"Name"];
    cell.containedSlices.text = [self stringFromArray:[[_listObjects objectAtIndex:indexPath.row] objectForKey:@"Slices"]];
    cell.sliceCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[[_listObjects objectAtIndex:indexPath.row] objectForKey:@"Slices"] count]];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"SAVED LISTS";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(settingsViewController: didSelectList:)]) {
        [_delegate settingsViewController:self didSelectList:(NSMutableArray *)[[_listObjects objectAtIndex:indexPath.row] objectForKey:@"Slices"]];
    }
    
    // Change Header Title to List name
    NSString *listTitle = [[_listObjects objectAtIndex:indexPath.row ] objectForKey:@"Name"];
    _vc.navigationItem.title = listTitle.uppercaseString;
    
    [self.revealViewController revealToggleAnimated:YES];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES - we will be able to delete all rows
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Perform the real delete action here. Note: you may need to check editing style
    //   if you do not perform delete only.
    [_listObjects removeObjectAtIndex:indexPath.row];
    
    NSMutableDictionary *lists = [NSMutableDictionary dictionary];
    [lists setValue:_listObjects forKey:@"Lists"];
    
    [[NSUserDefaults standardUserDefaults] setValue:lists forKey:@"saved_lists"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_listTable reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Saving and Recalling Lists

- (void)retrieveCurrentList {
    NSMutableDictionary *storedLists = [[NSUserDefaults standardUserDefaults] valueForKey:@"saved_lists"];
    
    _listObjects = [[storedLists valueForKey:@"Lists"] mutableCopy]; // Returns array of "List" objects -> each list object has Name and Slice array
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)stringFromArray:(NSArray *)array {
    NSString *string = array[0];
    
    for (int i=1; i < [array count]; i++) {
        string = [NSString stringWithFormat:@"%@, %@", string, array[i]];
    }
    
    return string;
}

- (IBAction)saveCurrentListTapped:(id)sender {
    UIAlertController* alert;
    
    if (_vc.slices.count < 2) {
        alert = [UIAlertController alertControllerWithTitle:@"Please add at least 2 slices before saving a list."
                                                                       message:@""
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * action) {}];
        [alert addAction: cancelAction];
        
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Save Current List"
                                                                       message:@"Please Enter a Name for this List"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction* saveAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                              // Add code to save here or call method
                                                                  [self saveListInUserDefaults:alert.textFields.firstObject.text];
                                                                  
                                                              }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:saveAction];
        [alert addAction:cancelAction];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.placeholder = NSLocalizedString(@"List Name", @"ListName");
         }];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveListInUserDefaults:(NSString *)listName {
    
    // Initialize Saved Lists
    if (_listObjects == nil) {
        _listObjects = [NSMutableArray array];
    }
    
    // Dismiss Keyboard
    [self.view endEditing:YES];
    
    NSMutableDictionary *lists = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *list = [NSMutableDictionary dictionary];
    
    // Set Name for List
    [list setValue:listName forKey:@"Name"];
    
    // Set Array of Slices for List
    [list setValue: _vc.slices forKey:@"Slices"];
    
    // Add List to Array of Lists, Create Key
    [_listObjects addObject:list];
    [lists setValue:_listObjects forKey:@"Lists"];
   
    [[NSUserDefaults standardUserDefaults] setValue:lists forKey:@"saved_lists"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Refresh the list Section
    [_listTable reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    
    // Update table
    [self retrieveCurrentList];
}

@end
