//
//  YBIListTableViewController.m
//  LastPiece
//
//  Created by Alex Pojman on 12/18/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBIListTableViewController.h"
#import "YBIListCell.h"
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

@interface YBIListTableViewController ()

@property (strong, nonatomic) NSMutableArray *namesList;
@property (strong, nonatomic) NSIndexPath *currentIndexPaths;
@property (strong, nonatomic) NSArray *sliceColors;
@property (strong, nonatomic) NSMutableArray *listObjects;
@end

@implementation YBIListTableViewController

#pragma mark - initialization methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil namesList:(NSMutableArray *)currentNamesList
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        // Custom initialization
        // Nav bar items
        self.navigationItem.title = @"SAVED SLICE LISTS";
        
        UIBarButtonItem *finishItem = [[UIBarButtonItem alloc] initWithTitle:@"Finish" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
        
        self.navigationItem.rightBarButtonItem = finishItem;
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save Current" style:UIBarButtonItemStylePlain target:self action:@selector(saveCurrentList)];
        
        // Initialize namesList
        self.namesList = [[NSMutableArray alloc] init];
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Load the NIB file
    UINib *nib = [UINib nibWithNibName:@"YBIListCell" bundle:nil];
    
    // Register this NIB, which contains the cell
    [self.tableView registerNib:nib forCellReuseIdentifier:@"YBIListCell"];

    // Initialized tableView with currentList of Lists
    for (int i=0; i < [_listObjects count]; i++) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    // Set Color for UsersTable and Main View Background
    [self.tableView setBackgroundColor:FlatBlack];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
    [self retrieveCurrentList];
    
    if (_listObjects == nil) {
        _listObjects = [NSMutableArray array];
    }
    
}

- (void)saveCurrentList {
    NSLog(@"%@", _listObjects);
    NSMutableDictionary *lists = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *list = [NSMutableDictionary dictionary];
    [list setValue:@"test" forKey:@"Name"];
    [list setValue:_namesList forKey:@"Slices"];
    
    [_listObjects addObject:list];
    [lists setValue:_listObjects forKey:@"Lists"];
    
    [[NSUserDefaults standardUserDefaults] setValue:lists forKey:@"saved_lists"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
}

- (void)retrieveCurrentList {
    NSMutableDictionary *storedLists = [[NSUserDefaults standardUserDefaults] valueForKey:@"saved_lists"];
    
    _listObjects = [[storedLists valueForKey:@"Lists"] mutableCopy]; // Returns array of "List" objects -> each list object has Name and Slice array
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_listObjects count];
}

#pragma mark - Finish
- (void)finish:(id)sender
{
    [self.view endEditing:YES];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YBIListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YBIListCell" forIndexPath:indexPath];
    NSMutableArray *currentLists = _listObjects;
    //Now we populate each row of the cell with each `list` Name.
    
    cell.listName.text = [[currentLists objectAtIndex:[indexPath row]] valueForKey:@"Name"];
    
    NSString *containedSlices = @"Includes: ";
    
    for (int i = 0; i < [[[currentLists objectAtIndex:[indexPath row]] valueForKey:@"Slices"] count]; i++) {
        containedSlices = [containedSlices stringByAppendingString:[[[currentLists objectAtIndex:[indexPath row]] valueForKey:@"Slices"] objectAtIndex:i]];
        
        if (i != [[[currentLists objectAtIndex:[indexPath row]] valueForKey:@"Slices"] count] - 1) {
            containedSlices = [containedSlices stringByAppendingString:@", "];
        }
    }
                           
    cell.containedSlices.text = containedSlices;
    
    return cell;
}

@end
