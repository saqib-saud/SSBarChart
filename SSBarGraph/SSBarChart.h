
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SSBar.h"

typedef struct {
    double maxValue;
    double minValue;
    double maxSteps;
    double minSteps;
} ValueBounds;
@interface SSBarChart : UIView
@property (nonatomic,retain)NSMutableArray * labels;
@property (nonatomic,retain)NSMutableArray * datasets;

//Configurations
@property (nonatomic, assign) BOOL scaleOverlay;
@property (nonatomic, assign) BOOL scaleOverride;
@property (nonatomic, assign) BOOL scaleShowLabels;
@property (nonatomic, retain) NSString * scaleLabel;
@property (nonatomic, assign) double scaleSteps;
@property (nonatomic, assign) double scaleStepWidth;
@property (nonatomic, assign) double scaleStartValue;
@property (nonatomic, retain) UIFont * scaleFont;
@property (nonatomic, retain) UIColor * scaleLineColor;
@property (nonatomic, assign) int scaleLineWidth;
@property (nonatomic, assign) BOOL scaleShowGridLines;
@property (nonatomic, retain) UIColor * scaleGridLineColor;
@property (nonatomic, assign) int scaleGridLineWidth;
@property (nonatomic, assign) BOOL barShowStroke;
@property (nonatomic, assign) int barStrokeWidth;
@property (nonatomic, assign) int barValueSpacing;
@property (nonatomic, assign) int barDatasetSpacing;
@property (nonatomic, assign) BOOL animation;




- (id) initWithFrame:(CGRect)frame Labels:(NSString*)firstObj, ...;
- (void) reloadData;
@end
