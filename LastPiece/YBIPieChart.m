//
//  YBIPieChart.m
//  LastPiece
//
//  Created by Alex Pojman on 7/29/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBIPieChart.h"
#import <QuartzCore/QuartzCore.h>

@interface SliceLayer : CAShapeLayer
@property (nonatomic, assign) CGFloat   value;
@property (nonatomic, assign) CGFloat   percentage;
@property (nonatomic, assign) double    startAngle;
@property (nonatomic, assign) double    endAngle;
@property (nonatomic, assign) BOOL      isSelected;
@property (nonatomic, strong) NSString  *text;

- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate;
@end

@implementation SliceLayer
@synthesize text = _text;
@synthesize value = _value;
@synthesize percentage = _percentage;
@synthesize startAngle = _startAngle;
@synthesize endAngle = _endAngle;
@synthesize isSelected = _isSelected;


- (NSString*)description
{
    return [NSString stringWithFormat:@"value:%f, percentage:%0.0f, start:%f, end:%f", _value, _percentage, _startAngle/M_PI*180, _endAngle/M_PI*180];
}
+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
        return YES;
    }
    else {
        return [super needsDisplayForKey:key];
    }
}
- (id)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer])
    {
        if ([layer isKindOfClass:[SliceLayer class]]) {
            self.startAngle = [(SliceLayer *)layer startAngle];
            self.endAngle = [(SliceLayer *)layer endAngle];
        }
    }
    return self;
}
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate
{
    CABasicAnimation *arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    NSNumber *currentAngle = [[self presentationLayer] valueForKey:key];
    if(!currentAngle) currentAngle = from;
    [arcAnimation setFromValue:currentAngle];
    [arcAnimation setToValue:to];
    [arcAnimation setDelegate:delegate];
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    [self addAnimation:arcAnimation forKey:key];
    [self setValue:to forKey:key];
}
@end

@interface YBIPieChart (Private)
- (void)updateTimerFired:(NSTimer *)timer;
- (SliceLayer *)createSliceLayer;
- (CGSize)sizeThatFitsString:(NSString *)string;
- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(NSString *)value;
- (void)notifyDelegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection;
@end

@implementation YBIPieChart
{
    NSInteger _selectedSliceIndex;
    //pie view, contains all slices
    UIView *_pieView;
    
    //animation control
    NSTimer *_animationTimer;
    NSMutableArray *_animations;
}

static NSUInteger kDefaultSliceZOrder = 100;

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize startPieAngle = _startPieAngle;
@synthesize animationSpeed = _animationSpeed;
@synthesize pieCenter = _pieCenter;
@synthesize pieRadius = _pieRadius;
@synthesize labelFont = _labelFont;
@synthesize labelColor = _labelColor;
@synthesize labelShadowColor = _labelShadowColor;
@synthesize labelRadius = _labelRadius;
@synthesize selectedSliceStroke = _selectedSliceStroke;
@synthesize selectedSliceOffsetRadius = _selectedSliceOffsetRadius;


static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, center.x, center.y);
    
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    CGPathCloseSubpath(path);
    
    return path;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _pieView = [[UIView alloc] initWithFrame:frame];
        [_pieView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_pieView];
        
        _selectedSliceIndex = -1;
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        _startPieAngle = M_PI_2*3;
        _selectedSliceStroke = 3.0;
        
        self.pieRadius = MIN(frame.size.width/2, frame.size.height/2) - 10;
        self.pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.labelFont = [UIFont fontWithName:@"MyriadPro-BoldCond" size:MAX((int)self.pieRadius/10, 5)];
        _labelColor = [UIColor whiteColor];
        _labelRadius = _pieRadius/2;
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius
{
    self = [self initWithFrame:frame];
    if (self)
    {
        self.pieCenter = center;
        self.pieRadius = radius;
    }
    return self;
}

// This is the main initializer used
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _pieView = [[UIView alloc] initWithFrame:self.bounds];
        [_pieView setBackgroundColor:[UIColor clearColor]];
        [self insertSubview:_pieView atIndex:0];
        
        _selectedSliceIndex = -1;
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        _startPieAngle = M_PI_2*3;
        _selectedSliceStroke = 3.0;
        
        CGRect bounds = [[self layer] bounds];
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        self.labelFont = [UIFont fontWithName:@"MyriadPro-Regular" size:MAX((int)self.pieRadius/10, 5)];
        //self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _labelColor = [UIColor whiteColor];
        _labelRadius = _pieRadius * 0.8;
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        _sliceAnimating = NO;
    }
    return self;
}

- (void)setPieCenter:(CGPoint)pieCenter
{
    [_pieView setCenter:pieCenter];
    _pieCenter = CGPointMake(_pieView.frame.size.width/2, _pieView.frame.size.height/2);
}

- (void)setPieRadius:(CGFloat)pieRadius
{
    _pieRadius = pieRadius;
    CGPoint origin = _pieView.frame.origin;
    CGRect frame = CGRectMake(origin.x+_pieCenter.x-pieRadius, origin.y+_pieCenter.y-pieRadius, pieRadius*2, pieRadius*2);
    _pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    [_pieView setFrame:frame];
    [_pieView.layer setCornerRadius:_pieRadius];
}

- (void)setPieBackgroundColor:(UIColor *)color
{
    [_pieView setBackgroundColor:color];
}

#pragma mark - Pie Reload Data With Animation

- (void)reloadData
{
    if (_dataSource)
    {
        CALayer *parentLayer = [_pieView layer];
        NSArray *slicelayers = [parentLayer sublayers];
        
        _selectedSliceIndex = -1;
        [slicelayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SliceLayer *layer = (SliceLayer *)obj;
            if(layer.isSelected)
                [self setSliceDeselectedAtIndex:idx];
        }];
        
        double startToAngle = 0.0;
        double endToAngle = startToAngle;
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieChart:self];
        
        // Assign Percentage Weights to Each Slice in Chart
        double angles[sliceCount];
        for (int index = 0; index < sliceCount; index++) {
            double div;
            div = 1.0 / sliceCount;
            angles[index] = M_PI * 2 * div;
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:_animationSpeed];
        
        [_pieView setUserInteractionEnabled:NO];
        
        __block NSMutableArray *layersToRemove = nil;
        
        BOOL isOnStart = ([slicelayers count] == 0 && sliceCount);
        NSInteger diff = sliceCount - [slicelayers count];
        layersToRemove = [NSMutableArray arrayWithArray:slicelayers];
        
        BOOL isOnEnd = ([slicelayers count] && sliceCount == 0);
        if(isOnEnd)
        {
            for(SliceLayer *layer in _pieView.layer.sublayers){
                [self updateLabelForLayer:layer value:0];
                
                [layer createArcAnimationForKey:@"startAngle"
                                      fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                        toValue:[NSNumber numberWithDouble:_startPieAngle]
                                       Delegate:self];
                [layer createArcAnimationForKey:@"endAngle"
                                      fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                        toValue:[NSNumber numberWithDouble:_startPieAngle]
                                       Delegate:self];
                
                
            }
            [CATransaction commit];
            return;
        }
        
        for(int index = 0; index < sliceCount; index ++)
        {
            SliceLayer *layer;
            double angle = angles[index];
            endToAngle += angle;
            double startFromAngle = _startPieAngle + startToAngle;
            double endFromAngle = _startPieAngle + endToAngle;
            
            if( index >= [slicelayers count] )
            {
                layer = [self createSliceLayer];
                if (isOnStart)
                    startFromAngle = endFromAngle = _startPieAngle;
                [parentLayer addSublayer:layer];
                diff--;
            }
            else
            {
                SliceLayer *onelayer = [slicelayers objectAtIndex:index];
                if(diff == 0)
                {
                    layer = onelayer;
                    [layersToRemove removeObject:layer];
                }
                else if(diff > 0)
                {
                    layer = [self createSliceLayer];
                    [parentLayer insertSublayer:layer atIndex:index];
                    diff--;
                }
                else if(diff < 0)
                {
                    while(diff < 0)
                    {
                        [onelayer removeFromSuperlayer];
                        [parentLayer addSublayer:onelayer];
                        diff++;
                        onelayer = [slicelayers objectAtIndex:index];
                        if(diff == 0)
                        {
                            layer = onelayer;
                            [layersToRemove removeObject:layer];
                            break;
                        }
                    }
                }
            }
            
        
            
            UIColor *color = nil;
            if([_dataSource respondsToSelector:@selector(pieChart:colorForSliceAtIndex:)])
            {
                color = [_dataSource pieChart:self colorForSliceAtIndex:index];
            }
            
            if(!color)
            {
                color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
            }
            
            [layer setFillColor:color.CGColor];
            if([_dataSource respondsToSelector:@selector(pieChart:textForSliceAtIndex:)])
            {
                layer.text = [_dataSource pieChart:self textForSliceAtIndex:index];
            }
            
            [self updateLabelForLayer:layer value:@"3"];
            [layer createArcAnimationForKey:@"startAngle"
                                  fromValue:[NSNumber numberWithDouble:startFromAngle]
                                    toValue:[NSNumber numberWithDouble:startToAngle+_startPieAngle]
                                   Delegate:self];
            [layer createArcAnimationForKey:@"endAngle"
                                  fromValue:[NSNumber numberWithDouble:endFromAngle]
                                    toValue:[NSNumber numberWithDouble:endToAngle+_startPieAngle]
                                   Delegate:self];
            startToAngle = endToAngle;
        }
        [CATransaction setDisableActions:YES];
        for(SliceLayer *layer in layersToRemove)
        {
            [layer setFillColor:[self backgroundColor].CGColor];
            [layer setDelegate:nil];
            [layer setZPosition:0];
            CATextLayer *textLayer = [[layer sublayers] objectAtIndex:0];
            [textLayer setHidden:YES];
        }
        
        [layersToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj removeFromSuperlayer];
        }];
        
        [layersToRemove removeAllObjects];
        
        for(SliceLayer *layer in _pieView.layer.sublayers)
        {
            
            // Rotate Text Labels to Proper Angles
            CALayer *labelLayer = [layer.sublayers objectAtIndex:0];
            
            // Reset Rotation to Transform Identity, then re-rotate
            [labelLayer setTransform:CATransform3DIdentity];
            [labelLayer setTransform:CATransform3DRotate(labelLayer.transform, ((layer.startAngle + layer.endAngle) / 2 ) + M_PI / 2, 0, 0, 1)];
            
            
            // Set Layer Z Positions back to proper
            [layer setZPosition:kDefaultSliceZOrder];
        }
        
       
        
        [_pieView setUserInteractionEnabled:YES];
        
        [CATransaction setDisableActions:NO];
        [CATransaction commit];
    }
}

#pragma mark - Animation Delegate + Run Loop Timer

- (void)updateTimerFired:(NSTimer *)timer;
{
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(CAShapeLayer * obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber *presentationLayerStartAngle = [[obj presentationLayer] valueForKey:@"startAngle"];
        CGFloat interpolatedStartAngle = [presentationLayerStartAngle doubleValue];
        
        NSNumber *presentationLayerEndAngle = [[obj presentationLayer] valueForKey:@"endAngle"];
        CGFloat interpolatedEndAngle = [presentationLayerEndAngle doubleValue];
        
        CGPathRef path = CGPathCreateArc(_pieCenter, _pieRadius, interpolatedStartAngle, interpolatedEndAngle);
        [obj setPath:path];
        CFRelease(path);
        
        {
            CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
            CGFloat interpolatedMidAngle = (interpolatedEndAngle + interpolatedStartAngle) / 2;
            [CATransaction setDisableActions:YES];
            [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];
            [CATransaction setDisableActions:NO];
        }
    }];
}

- (void)animationDidStart:(CAAnimation *)anim
{
    if (_animationTimer == nil) {
        static float timeInterval = 1.0/60.0;
        // Run the animation timer on the main thread.
        // We want to allow the user to interact with the UI while this timer is running.
        // If we run it on this thread, the timer will be halted while the user is touching the screen (that's why the chart was disappearing in our collection view).
        _animationTimer= [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
    }
    
    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)animationCompleted
{
    [_animations removeObject:anim];
    
    if ([_animations count] == 0) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

#pragma mark - Selection Notification

- (void)notifyDelegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection
{
    if (previousSelection != newSelection){
        if(previousSelection != -1){
            NSUInteger tempPre = previousSelection;
            if ([_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
                [_delegate pieChart:self willDeselectSliceAtIndex:tempPre];
            [self setSliceDeselectedAtIndex:tempPre];
            previousSelection = newSelection;
            if([_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
                [_delegate pieChart:self didDeselectSliceAtIndex:tempPre];
        }
        
        if (newSelection != -1){
            if([_delegate respondsToSelector:@selector(pieChart:willSelectSliceAtIndex:)])
                [_delegate pieChart:self willSelectSliceAtIndex:newSelection];
            [self setSliceSelectedAtIndex:newSelection];
            _selectedSliceIndex = newSelection;
            if([_delegate respondsToSelector:@selector(pieChart:didSelectSliceAtIndex:)])
                [_delegate pieChart:self didSelectSliceAtIndex:newSelection];
        }
    }else if (newSelection != -1){
        SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:newSelection];
        if(_selectedSliceOffsetRadius > 0 && layer){
            if (layer.isSelected) {
                if ([_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
                    [_delegate pieChart:self willDeselectSliceAtIndex:newSelection];
                [self setSliceDeselectedAtIndex:newSelection];
                if (newSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
                    [_delegate pieChart:self didDeselectSliceAtIndex:newSelection];
                previousSelection = _selectedSliceIndex = -1;
            }else{
                if ([_delegate respondsToSelector:@selector(pieChart:willSelectSliceAtIndex:)])
                    [_delegate pieChart:self willSelectSliceAtIndex:newSelection];
                [self setSliceSelectedAtIndex:newSelection];
                previousSelection = _selectedSliceIndex = newSelection;
                if (newSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didSelectSliceAtIndex:)])
                    [_delegate pieChart:self didSelectSliceAtIndex:newSelection];
            }
        }
    }
}

- (NSMutableArray *)getMiddleAngles
{
    NSMutableArray *middleAngles = [[NSMutableArray alloc] initWithCapacity:0];
    for (int index = 0; index < [_pieView.layer.sublayers count]; index++) {
        SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:index];
        double middleAngle = (layer.startAngle + layer.endAngle)/2.0;
        [middleAngles addObject:[NSNumber numberWithDouble:middleAngle]];
    }
    
    return middleAngles;
}

#pragma mark - Selection Programmatically Without Notification

- (void)setSliceSelectedAtIndex:(NSInteger)index
{
    if(_selectedSliceOffsetRadius <= 0)
        return;
    SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:index];
    if (layer && !layer.isSelected) {
        
        layer.isSelected = YES;
        [self notifyDelegateOfSelectionChangeFrom:-1 to:index];
        [self transformWithOptions:UIViewAnimationOptionOverrideInheritedOptions];
        
        // Highlight selected index
        CALayer *parentLayer = [_pieView layer];
        NSArray *pieLayers = [parentLayer sublayers];
        
        [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [layer setLineWidth:_selectedSliceStroke];
                [layer setStrokeColor:[UIColor whiteColor].CGColor];
                [layer setLineJoin:kCALineJoinBevel];
                [layer setZPosition:MAXFLOAT];
        }];
    }
    
}

- (void)setSliceDeselectedAtIndex:(NSInteger)index
{
    if(_selectedSliceOffsetRadius <= 0)
        return;
    SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:index];
    _sliceAnimating = NO;
    if (layer && layer.isSelected) {
   
        layer.isSelected = NO;
        [self notifyDelegateOfSelectionChangeFrom:_selectedSliceIndex to:-1];
       
        // Unhighlight the previously selected index
        [layer setZPosition:kDefaultSliceZOrder];
        [layer setLineWidth:0.0];
    }
    
}

// TODO move this back to setSliceSelectedAtIndex
#pragma mark - Pie Layer Slice Animation
- (void) transformWithOptions: (UIViewAnimationOptions) options
{
    SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:_selectedSliceIndex];
    CGPoint originalPos = layer.position;
    double middleAngle = ((layer.startAngle + layer.endAngle)/2.0);
    CGPoint innerPos = CGPointMake(originalPos.x + (_selectedSliceOffsetRadius/1.5)*cos(middleAngle), originalPos.y + (_selectedSliceOffsetRadius/1.5)*sin(middleAngle));
    CGPoint outerPos = CGPointMake(originalPos.x + _selectedSliceOffsetRadius*cos(middleAngle), originalPos.y + _selectedSliceOffsetRadius*sin(middleAngle));
    
    _sliceAnimating = YES;
    [self sliceAnimate:layer aLocation:innerPos bLocation:outerPos ogLocation:originalPos duration:0.5];
}

-(void)sliceAnimate:(SliceLayer *)layer aLocation:(CGPoint)aLocation bLocation:(CGPoint)bLocation ogLocation:(CGPoint)ogLocation duration:(float)duration{
    
    if(_sliceAnimating == YES) {
    [CATransaction setCompletionBlock: ^{
        [CATransaction setCompletionBlock:^{
            if(_sliceAnimating == YES) {
                [self sliceAnimate:layer aLocation:aLocation bLocation:bLocation ogLocation:ogLocation duration:duration];
            } else {
                [CATransaction begin]; {
                    [CATransaction setAnimationDuration:0.001];
                    layer.position=CGPointMake(0, 0);
                    layer.opacity = 1.0;
                    layer.zPosition=kDefaultSliceZOrder;
                    
                } [CATransaction commit];
            }
        }];
        if(_sliceAnimating == YES) {
            [CATransaction begin]; {
                [CATransaction setAnimationDuration:duration];
                layer.position=aLocation;
                layer.opacity = 0.75;
                layer.zPosition=50.0;
            
            } [CATransaction commit];
        } else {
            [CATransaction begin]; {
                [CATransaction setAnimationDuration:0.001];
                layer.position=CGPointMake(0, 0);
                layer.opacity = 1.0;
                layer.zPosition=kDefaultSliceZOrder;
                
            } [CATransaction commit];
        }
    }];
    [CATransaction begin]; {
        [CATransaction setAnimationDuration:duration];
        layer.position=bLocation;
        layer.opacity = 1.0;
        layer.zPosition=50.0;
        
    } [CATransaction commit];
    } else {
        [CATransaction begin]; {
            [CATransaction setAnimationDuration:0.0001];
            layer.position=CGPointMake(0, 0);
            layer.opacity = 1.0;
            layer.zPosition=kDefaultSliceZOrder;
            
        } [CATransaction commit];
    }
}
#pragma mark - Pie Layer Creation Method

- (SliceLayer *)createSliceLayer
{
    SliceLayer *pieLayer = [SliceLayer layer];
    [pieLayer setZPosition:0];
    [pieLayer setStrokeColor:NULL];
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    CGFontRef font = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
    } else {
        font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
    }
    if (font) {
        [textLayer setFont:font];
        CFRelease(font);
    }
    [textLayer setFontSize:self.labelFont.pointSize];
    [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    [textLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [textLayer setForegroundColor:self.labelColor.CGColor];
    if (self.labelShadowColor) {
        [textLayer setShadowColor:self.labelShadowColor.CGColor];
        [textLayer setShadowOffset:CGSizeZero];
        [textLayer setShadowOpacity:1.0f];
        [textLayer setShadowRadius:2.0f];
    }
    
    //TODO fix this so that text gets truncated
    //CGSize size = [@"0" sizeWithFont:self.labelFont];
    CGRect textRect = [@"0" boundingRectWithSize:CGSizeMake(90, 30)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:self.labelFont}
                                          context:nil];
    
    CGSize size = textRect.size;

    [CATransaction setDisableActions:YES];
    [textLayer setFrame:CGRectMake(0, 0, size.width, size.height)];
    [textLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(0)), _pieCenter.y + (_labelRadius * sin(0)))];
    [CATransaction setDisableActions:NO];
    [pieLayer addSublayer:textLayer];
    
    return pieLayer;
}

- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(NSString *)value
{
    CATextLayer *textLayer = [[pieLayer sublayers] objectAtIndex:0];
   
    NSString *label;
    
    // Here is where label gets assigned
    label = (pieLayer.text)?pieLayer.text:[NSString stringWithFormat:@"%@", value];
    
   // CGSize size = [label sizeWithFont:self.labelFont];
    CGRect textRect = [label boundingRectWithSize:CGSizeMake(300 / [_pieView.layer.sublayers count], 30)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:self.labelFont}
                                         context:nil];
    
    CGSize size = textRect.size;
    
    [CATransaction setDisableActions:YES];
    
    [textLayer setString:label];
    [textLayer setBounds:CGRectMake(0, 0, size.width, size.height)];
    
    [CATransaction setDisableActions:NO];
}

@end
