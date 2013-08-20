
#import <Foundation/Foundation.h>

@interface SSScale : NSObject
/*
 steps : config.scaleSteps,
 stepValue : config.scaleStepWidth,
 graphMin : config.scaleStartValue,
 labels : []
 */

@property (nonatomic, assign) double steps;
@property (nonatomic, assign) double stepValue;
@property (nonatomic, assign) double graphMin;
@property (nonatomic, retain) NSMutableArray * labels;

@end
