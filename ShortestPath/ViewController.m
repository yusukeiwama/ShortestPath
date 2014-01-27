//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "ViewController.h"
#import "TSP.h"
#import "TSPExperimentManager.h"
#import "TSPVisualizer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pathImageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	TSPVisualizer *visualizer = [[TSPVisualizer alloc] init];
	visualizer.imageView = self.pathImageView;
	
	TSPExperimentManager *experimentManager = [[TSPExperimentManager alloc] init];
	experimentManager.visualizer = visualizer;
	
	[experimentManager doExperiment:USKTSPExperimentNN2opt];
//    [experimentManager doExperiment:USKTSPExperimentOptimal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
