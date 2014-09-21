//
//  YBISwirlGestureRecognizer.h
//  LastPiece
//
//  Created by Alex Pojman on 8/9/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>
@protocol YBISwirlGestureRecognizerDelegate <UIGestureRecognizerDelegate>

@end

@interface YBISwirlGestureRecognizer : UIGestureRecognizer

@property CGFloat currentAngle;
@property CGFloat previousAngle;
@end
