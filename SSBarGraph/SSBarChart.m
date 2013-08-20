//
//  SSBarChart.m
//  XYPieChart
//
//  Created by Saqib on 7/27/13.
//  Copyright (c) 2013 Xiaoyang Feng. All rights reserved.
//

#import "SSBarChart.h"
#import <math.h>
#import "SSScale.h"

#define _SSANIMATION_STEPS 60
@interface SSBarChart ()
- (SSScale*)calculateScale:(double)drawingHeight maxSteps:(double)maxSteps minSteps:(double)minSteps maxValue:(double)maxValue minValue:(double)minValue labelTemplateString:(NSString*)labelTemplateString;
- (NSMutableArray *) populateYAxisLabels:(NSString*)labelTemplateString labels:(NSMutableArray*)labels numberOfSteps:(double)numberOfSteps graphMin:(double)graphMin stepValue:(double)stepValue;
- (void) calculateXAxisSize:(SSScale*)calculatedScale;
- (void) setup;
- (void) drawScale;
- (void) animateBars;
- (double) CapValue:(double)valueToCap maxValue:(double) maxValue minValue:(double)minValue;
@end

@implementation SSBarChart{
    NSInteger _maxSize;
    NSInteger _scaleHop;
    NSInteger _labelHeight;
    NSInteger _scaleHeight;
    NSInteger _valueBounds;
    NSInteger _labelTemplateString;
    NSInteger _valueHop;
    NSInteger _widestXLabel;
    NSInteger _xAxisLength;
    NSInteger _yAxisPosX;
    NSInteger _xAxisPosY;
    NSInteger _barWidth;
    NSInteger _rotateLabels; //Default 0
    
    double _animFrameAmount,_percentComplete;
    
    NSTimer * _scheduleTimer;
    
    SSScale * _calculatedScale;
    
}
@synthesize labels;
- (id) initWithFrame:(CGRect)frame Labels:(NSString*)firstObj, ...; {
    if ([self initWithFrame:frame]){
        [self setup];
        _animFrameAmount=0;
        _percentComplete=0;
        id eachObject;
        va_list argumentList;
        if (firstObj)                      // The first argument isn't part of the varargs list,
        {                                     // so we'll handle it separately.
            self.labels = [NSMutableArray new];
            [self.labels addObject:firstObj];
            va_start(argumentList, firstObj);          // Start scanning for arguments after firstObject.
            while ((eachObject = va_arg(argumentList, id))) // As many times as we can get an argument of type "id"
            {
                [self.labels addObject:eachObject];              // that isn't nil, add it to self's contents.
            }
            va_end(argumentList);
        }
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aCoder{
    if(self = [super initWithCoder:aCoder]){
        [self setup];
        _animFrameAmount=0;
        _percentComplete=0;
    }
    return self;

}
- (void) setup{
    self.scaleOverlay = NO;
    self.scaleOverride = NO;
    self.scaleLineColor= [UIColor redColor];
    self.scaleLineWidth = 1;
    self.scaleShowLabels =YES;
    self.scaleShowGridLines =YES;
    self.scaleGridLineColor = [UIColor greenColor];
    self.scaleGridLineWidth = 1;
    self.barShowStroke=YES;
    self.barStrokeWidth=2;
    self.barValueSpacing=5;
    self.barDatasetSpacing=1;
    self.animation=YES;
    self.scaleFont = [UIFont fontWithName:@"Arial" size:12];

}
- (void) calculateDrawingSizes{
    _maxSize =self.frame.size.height;
    //Need to check the X axis first - measure the length of each text metric, and figure out if we need to rotate by 45 degrees.

    _widestXLabel = 1;
    for (NSString* label in self.labels) {
        CGSize size = [label sizeWithFont:self.scaleFont];
        //If the text length is longer - make that equal to longest text!
        _widestXLabel = (size.width > _widestXLabel)? size.width : _widestXLabel;
    }
    NSInteger width = self.frame.size.width;
    if (width/[self.labels count] < _widestXLabel){
        _rotateLabels = 45;
        if (width/[self.labels count] < cos(_rotateLabels) * _widestXLabel){
            _rotateLabels = 90;
            _maxSize -= _widestXLabel;
        }
        else{
            _maxSize -= sin(_rotateLabels) * _widestXLabel;
        }
    }
    else{
        _maxSize -= [UIFont systemFontSize];;
    }
    
    //Add a little padding between the x line and the text
    _maxSize -= 5;
    
    
    _labelHeight = self.scaleFont.pointSize;
    
    _maxSize -= _labelHeight;
    //Set 5 pixels greater than the font size to allow for a little padding from the X axis.
    
    _scaleHeight = _maxSize;
    
    //Then get the area above we can safely draw on.
    
}

- (ValueBounds) getValueBounds{
    double upperValue = INT_MIN;
    double lowerValue = INT_MAX;
    for (int i=0; i<[self.datasets count]; i++){
        for (int j=0; j<[[(SSBar*)[self.datasets objectAtIndex:i] barData]count]; j++){
            if ( [[[(SSBar*)[self.datasets objectAtIndex:i] barData] objectAtIndex:j] doubleValue] > upperValue) {
                upperValue = [[[(SSBar*)[self.datasets objectAtIndex:i] barData] objectAtIndex:j] doubleValue];
            }
            if ( [[[(SSBar*)[self.datasets objectAtIndex:i] barData] objectAtIndex:j] doubleValue] < lowerValue) {
                lowerValue = [[[(SSBar*)[self.datasets objectAtIndex:i] barData] objectAtIndex:j] doubleValue];
            }
        }
    }
	
    double maxSteps = floor((_scaleHeight / (_labelHeight*0.66)));
    double minSteps = floor((_scaleHeight / _labelHeight*0.5));
    
    ValueBounds bounds;
    bounds.maxValue=upperValue;
    bounds.minValue=lowerValue;
    bounds.maxSteps= maxSteps;
    bounds.minSteps= minSteps;
    return bounds;
}

-(double) calculateOrderOfMagnitude:(double)val{
    return floor(log(val) / M_LN10);
}
- (NSMutableArray *) populateYAxisLabels:(NSString*)labelTemplateString labels:(NSMutableArray*)labels numberOfSteps:(double)numberOfSteps graphMin:(double)graphMin stepValue:(double)stepValue;{
    //if (labelTemplateString) {
        //Fix floating point errors by setting to fixed the on the same decimal as the stepValue.
        NSMutableArray * yAxisLabels = [NSMutableArray new];
        for (int i = 1; i < numberOfSteps + 1; i++) {
            NSString * yAxisLabel = [NSString stringWithFormat:@"%.f",graphMin + (stepValue * i)];
            [yAxisLabels addObject:yAxisLabel];
        }
        return yAxisLabels;
    //}
    //return nil;
}
- (SSScale *)calculateScale:(double)drawingHeight maxSteps:(double)maxSteps minSteps:(double)minSteps maxValue:(double)maxValue minValue:(double)minValue labelTemplateString:(NSString*)labelTemplateString;{
    
    double graphMin,graphMax,graphRange,stepValue,numberOfSteps,valueRange,rangeOrderOfMagnitude,decimalNum;
    
    valueRange = maxValue - minValue;
    
    rangeOrderOfMagnitude = [self calculateOrderOfMagnitude:valueRange];
    
    graphMin = floor(minValue / (1 * pow(10, rangeOrderOfMagnitude))) * pow(10, rangeOrderOfMagnitude);
    
    graphMax = ceil(maxValue / (1 * pow(10, rangeOrderOfMagnitude))) * pow(10, rangeOrderOfMagnitude);
    
    graphRange = graphMax - graphMin;
    
    stepValue = pow(10, rangeOrderOfMagnitude);
    
    numberOfSteps = round(graphRange / stepValue);
    
    //Compare number of steps to the max and min for that size graph, and add in half steps if need be.
    while(numberOfSteps < minSteps || numberOfSteps > maxSteps) {
        if (numberOfSteps < minSteps){
            stepValue /= 2;
            numberOfSteps = round(graphRange/stepValue);
        }
        else{
            stepValue *=2;
            numberOfSteps = round(graphRange/stepValue);
        }
    };
    
     NSMutableArray * yAxisLabels =[self populateYAxisLabels:labelTemplateString labels:labels numberOfSteps:numberOfSteps graphMin:graphMin stepValue:stepValue];
    SSScale * scale = [SSScale new];
    scale.steps = numberOfSteps;
    scale.stepValue = stepValue;
    scale.graphMin=graphMin;
    scale.labels = yAxisLabels;
    return scale;
    

    

}

- (void) calculateXAxisSize:(SSScale*)calculatedScale{
    double longestText = 1;
    //if we are showing the labels
    if (self.scaleShowLabels){
        //TODO: use custom font
        UIFont * labelFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        for (int i=0; i<[calculatedScale.labels count]; i++){
            CGSize size = [(NSString*)[calculatedScale.labels objectAtIndex:i ] sizeWithFont:labelFont];
            longestText = (size.width > longestText)? size.width : longestText;
        }
        //Add a little extra padding from the y axis
        longestText +=10;
    }
    _xAxisLength = self.frame.size.width - longestText - _widestXLabel;
    _valueHop = floor(_xAxisLength/([self.labels count]));
    
    _barWidth = (_valueHop - self.scaleGridLineWidth*2 - (self.barValueSpacing*2) - (self.barDatasetSpacing* [self.datasets count]-1) - ((self.barStrokeWidth/2)*[self.datasets count]-1))/[self.datasets count];
    
    _yAxisPosX = self.frame.size.width-_widestXLabel/2-_xAxisLength;
    _xAxisPosY = _scaleHeight + self.scaleFont.pointSize/2;
}
- (void) reloadData;{
    [self calculateDrawingSizes];
    ValueBounds valueBounds = [self getValueBounds];
    NSString * labelTemplateString = self.scaleShowLabels? self.scaleLabel : @"";
    if (!self.scaleOverride){
        
        _calculatedScale =[self calculateScale:_scaleHeight maxSteps:valueBounds.maxSteps minSteps:valueBounds.minSteps maxValue:valueBounds.maxValue minValue:valueBounds.minValue labelTemplateString:labelTemplateString];
    }
    else {
        _calculatedScale = [SSScale new];
        _calculatedScale.steps = self.scaleSteps;
        _calculatedScale.stepValue =self.scaleStepWidth;
        _calculatedScale.graphMin = self.scaleStartValue;
        _calculatedScale.labels=[self populateYAxisLabels:labelTemplateString labels:_calculatedScale.labels numberOfSteps:_calculatedScale.steps graphMin:self.scaleStartValue stepValue:self.scaleStepWidth];
    }
    
    _scaleHop = floor(_scaleHeight/_calculatedScale.steps);
    [self calculateXAxisSize:_calculatedScale ] ;

    _percentComplete = (self.animation)? 1/[self CapValue:_SSANIMATION_STEPS maxValue:INT_MAX minValue:1] : 1;
    _scheduleTimer =[NSTimer scheduledTimerWithTimeInterval:.12 target:self selector:@selector(animateFrame:) userInfo:nil repeats:YES];


//    animationLoop(config,drawScale,drawBars,ctx);
  
}

- (void)drawRect:(CGRect)rect;{
    [super drawRect:rect];
    [self drawScale];
    
    double easeAdjustedAnimationPercent =(self.animation)? [self CapValue:[self easingFunction: _percentComplete]maxValue:NAN minValue:0] : 1;
    [self drawBar:easeAdjustedAnimationPercent];

}
- (void) drawScale;{
    //X axis line
    float width = self.frame.size.width;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, self.scaleLineWidth);
    CGContextSetFillColorWithColor(ctx, [self.scaleLineColor CGColor]);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint (ctx, width-_widestXLabel/2+5, _xAxisPosY);
    CGContextAddLineToPoint(ctx, width-(_widestXLabel/2)-_xAxisLength-5, _xAxisPosY);
    CGContextFillPath(ctx);

    
    
    if (_rotateLabels > 0){
        CGContextSaveGState(ctx);
        //ctx.textAlign = "right";
    }
    else{
        //ctx.textAlign = "center";
    }
    CGContextSelectFont(ctx, [self.scaleFont.fontName cStringUsingEncoding:NSUTF8StringEncoding], self.scaleFont.pointSize, kCGEncodingFontSpecific);
    //ctx.fillStyle = config.scaleFontColor;
    for (int i=0; i<[self.labels count]; i++){
        CGContextSaveGState(ctx);
        if (_rotateLabels > 0){
            CGContextTranslateCTM(ctx, _yAxisPosX + i*_valueHop, _xAxisPosY + self.scaleFont.pointSize+20);
            CGContextRotateCTM(ctx, -(_rotateLabels * (M_PI/180)));
            [[self.labels objectAtIndex:i] drawAtPoint:CGPointZero withFont:self.scaleFont];
            CGContextRestoreGState(ctx);
        }
        
        else{
            [[self.labels objectAtIndex:i] drawAtPoint:CGPointMake(_yAxisPosX + i*_valueHop -20 + _valueHop/2, _xAxisPosY + self.scaleFont.pointSize-10) withFont:self.scaleFont];

        }
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint (ctx, _yAxisPosX + (i+1) * _valueHop, _xAxisPosY+3);
        
        //Check i isnt 0, so we dont go over the Y axis twice.
        CGContextSetLineWidth(ctx, self.scaleGridLineWidth);
        CGContextSetStrokeColorWithColor(ctx, [self.scaleGridLineColor CGColor]);
        CGContextAddLineToPoint (ctx, _yAxisPosX + (i+1) * _valueHop, 5);
        CGContextStrokePath(ctx);
        //CGContextClosePath(ctx);

       
    }
    
    //Y axis
    CGContextSetLineWidth(ctx, self.scaleLineWidth);
    CGContextSetStrokeColorWithColor(ctx, [self.scaleLineColor CGColor]);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint (ctx, _yAxisPosX, _xAxisPosY+5);
    CGContextAddLineToPoint(ctx, _yAxisPosX, 5);
    CGContextStrokePath(ctx);

    
//    ctx.textAlign = "right";
//    ctx.textBaseline = "middle";
    for (int j=0; j<_calculatedScale.steps; j++){
        CGContextBeginPath(ctx);
        CGContextMoveToPoint (ctx, _yAxisPosX-3, _xAxisPosY - ((j+1) * _scaleHop));
        if (self.scaleShowGridLines){
            CGContextSetLineWidth(ctx, self.scaleLineWidth);
            CGContextSetStrokeColorWithColor(ctx, [self.scaleGridLineColor CGColor]);
            CGContextAddLineToPoint(ctx, _yAxisPosX + _xAxisLength + 5, _xAxisPosY - ((j+1) * _scaleHop));
        }
        else{
            CGContextAddLineToPoint(ctx, _yAxisPosX-0.5, _xAxisPosY - ((j+1) * _scaleHop));
        }

//        CGContextFillPath(ctx);
        CGContextStrokePath(ctx);
//        CGContextClosePath(ctx);


        if (self.scaleShowLabels){
            [[_calculatedScale.labels objectAtIndex:j] drawAtPoint:CGPointMake(_yAxisPosX-24, _xAxisPosY - ((j+1) * _scaleHop)) withFont:self.scaleFont];
        }
    }
    
}
- (void) animateBars:(double)animFrameAmount percentComplete:(double)percentComplete{
    percentComplete +=animFrameAmount;
    [self animateFrame:percentComplete];
    if (percentComplete <= 1){
            [self animateBars:percentComplete percentComplete:percentComplete];
 
                    

    }
    else{
       //Animation complete
    }

}
- (void) animateFrame:(double)percentAnimComplete{
    _percentComplete +=_percentComplete;
    if (_percentComplete>=1.5) {
        [_scheduleTimer invalidate];
    }
    else{
        [self setNeedsDisplay];
    }

    

}
- (void) drawBar:(double) easeAdjustedAnimationPercent{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //CGContextClearRect(ctx, self.frame);
    CGContextSetLineWidth(ctx, self.barStrokeWidth);

    for (int i=0; i<[self.datasets count]; i++){
        SSBar * bar = [self.datasets objectAtIndex:i];
        CGContextSetFillColorWithColor(ctx, [bar.fillColor CGColor]);
        CGContextSetStrokeColorWithColor(ctx, [bar.strokeColor CGColor]);

        for (int j=0; j<[bar.barData count]; j++){
            double barOffset = _yAxisPosX + self.barValueSpacing + _valueHop*j + _barWidth*i + self.barDatasetSpacing*i + self.barStrokeWidth*i;
            CGContextBeginPath(ctx);

            CGContextMoveToPoint (ctx, barOffset, _xAxisPosY);
            double calculatedOffset = [self calculateBarOffset:[[bar.barData objectAtIndex:j]doubleValue] scaleHop:_scaleHop] ;
            CGContextAddLineToPoint(ctx, barOffset, _xAxisPosY - easeAdjustedAnimationPercent*calculatedOffset+(self.barStrokeWidth/2));
            CGContextAddLineToPoint(ctx, barOffset + _barWidth, _xAxisPosY - easeAdjustedAnimationPercent*calculatedOffset+(self.barStrokeWidth/2));
            CGContextAddLineToPoint(ctx, barOffset + _barWidth, _xAxisPosY);
            CGContextAddLineToPoint(ctx, barOffset, _xAxisPosY);

            if (self.barShowStroke) {
                CGContextDrawPath(ctx, kCGPathFillStroke);
//                CGContextStrokePath(ctx);
            }else{
                CGContextFillPath(ctx);
                CGContextClosePath(ctx);

            }


        }
    }
}
- (double) calculateBarOffset:(double) val scaleHop:(double)scaleHop{
    double outerValue = _calculatedScale.steps * _calculatedScale.stepValue;
    double adjustedValue = val - _calculatedScale.graphMin;
    double scalingFactor = [self CapValue:adjustedValue/outerValue maxValue:1 minValue:0];
    return (scaleHop*_calculatedScale.steps) * scalingFactor;
}
- (double) easingFunction:(double)t {
    t=t/1-1;
    return -1 * (t*t*t*t - 1);
}
- (double) CapValue:(double)valueToCap maxValue:(double) maxValue minValue:(double)minValue{

    if (!isnan(maxValue)) {
        if( valueToCap > maxValue ) {
            return maxValue;
        }
    }
    if (!isnan(minValue)) {
        if ( valueToCap < minValue ){
            return minValue;
        }
    }
    
    return valueToCap;
}
@end
