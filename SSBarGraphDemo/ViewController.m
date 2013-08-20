//
//  ViewController.m
//  SSBarGraphDemo
//
//  Created by Saqib on 8/20/13.
//
//

#import "ViewController.h"
#import "SSBarChart.h"
#import "SSBar.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.barChart =[[SSBarChart alloc] initWithFrame:CGRectMake(0, 0, 480 , 320) Labels:@"January",@"February",@"March",@"April",@"May",@"June",@"July",nil];
    self.barChart.labels = [[NSMutableArray alloc] initWithObjects:@"January",@"February",@"March",@"April",@"May",@"June",@"July",nil];
    
    NSMutableArray * datasets = [NSMutableArray new];
    {
        SSBar * bar = [SSBar new];
        bar.barData= [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:65 ],[NSNumber numberWithInt:59 ],[NSNumber numberWithInt:90 ],[NSNumber numberWithInt:81 ],[NSNumber numberWithInt:56 ],[NSNumber numberWithInt:55 ],[NSNumber numberWithInt:40 ],nil];
        bar.fillColor = [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
        bar.strokeColor =[UIColor lightGrayColor];
        [datasets addObject:bar];
        
    }
    
    {
        SSBar * bar = [SSBar new];
        bar.barData= [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:28 ],[NSNumber numberWithInt:48 ],[NSNumber numberWithInt:40 ],[NSNumber numberWithInt:19 ],[NSNumber numberWithInt:96 ],[NSNumber numberWithInt:27 ],[NSNumber numberWithInt:100 ],nil];
        bar.fillColor = [UIColor colorWithRed:203.0/255.0 green:221.0/255.0 blue:231.0/255.0 alpha:1.0];
        bar.strokeColor =[UIColor colorWithRed:151.0/255.0 green:187.0/255.0 blue:206.0/255.0 alpha:1.0];
        [datasets addObject:bar];
        
    }
    
    
    self.barChart.datasets=datasets;//Adding bars
    self.barChart.backgroundColor = [UIColor whiteColor];
    self.barChart.scaleGridLineColor =[UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
    [self.view addSubview:self.barChart];
    [self.barChart reloadData];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.barChart reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
