//
//  YBIPieChart.h
//  LastPiece
//
//  Created by Alex Pojman on 7/29/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YBIPieChart;
@protocol YBIPieChartDataSource <NSObject>
@required
- (NSUInteger)numberOfSlicesInPieChart:(YBIPieChart *)pieChart;
@optional
- (UIColor *)pieChart:(YBIPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index;
- (NSString *)pieChart:(YBIPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index;
@end

@protocol YBIPieChartDelegate <NSObject>
@optional
- (void)pieChart:(YBIPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(YBIPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(YBIPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(YBIPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index;
@end

@interface YBIPieChart : UIView

@property(nonatomic, weak) id<YBIPieChartDataSource> dataSource;
@property(nonatomic, weak) id<YBIPieChartDelegate> delegate;
@property(nonatomic, assign) CGFloat startPieAngle;
@property(nonatomic, assign) CGFloat animationSpeed;
@property(nonatomic, assign) CGPoint pieCenter;
@property(nonatomic, assign) CGFloat pieRadius;
@property(nonatomic, strong) UIFont  *labelFont;
@property(nonatomic, strong) UIColor *labelColor;
@property(nonatomic, strong) UIColor *labelShadowColor;
@property(nonatomic, assign) CGFloat labelRadius;
@property(nonatomic, assign) CGFloat selectedSliceStroke;
@property(nonatomic, assign) CGFloat selectedSliceOffsetRadius;
@property(nonatomic) BOOL sliceAnimating;

- (id)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius;
- (void)reloadData;
- (void)setPieBackgroundColor:(UIColor *)color;
- (NSMutableArray *)getMiddleAngles;

- (void)setSliceSelectedAtIndex:(NSInteger)index;
- (void)setSliceDeselectedAtIndex:(NSInteger)index;

@end
