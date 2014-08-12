//
//  YBITableViewController.h
//  LastPiece
//
//  Created by Alex Pojman on 7/30/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/* How to use delegation:
 1.) Create class and protocol in the .h of the object that will be passing the information
 1b.)Create a delegate property in the interface of sending object
 2.) Make the object that will be receiving the information a delegate using <xxx> in .m file
 3.) Implement a method defined in the object passing the information, but implement this method in the receiving object
 4.) In some method in object passing information (.m), check if delegate responds to method i.d
 
 if ([_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
 [_delegate pieChart:self willDeselectSliceAtIndex:tempPre];
 
 5.)
 */

@class YBIParticipantViewController;
@protocol YBIPartipantViewControllerDelegate <NSObject>

- (void)participantViewController:(YBIParticipantViewController *)pvc didFinishAddingNames:(NSArray *)names;
@end

@interface YBIParticipantViewController : UITableViewController
@property (nonatomic, weak) id<YBIPartipantViewControllerDelegate> delegate;
@end
