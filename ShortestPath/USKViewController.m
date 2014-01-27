//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKViewController.h"
#import "TSP.h"
#import "TSPExperimentManager.h"
#import "TSPVisualizer.h"

@interface USKViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pathImageView;

@end

@implementation USKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	TSPVisualizer *visualizer = [[TSPVisualizer alloc] init];
	visualizer.imageView = self.pathImageView;
	
	TSPExperimentManager *experimentManager = [[TSPExperimentManager alloc] init];
	experimentManager.visualizer = visualizer;
	
	[experimentManager doExperiment:USKTSPExperimentNN2opt];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
