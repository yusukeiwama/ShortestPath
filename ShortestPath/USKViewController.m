//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKViewController.h"
#import "USKTSP.h"
#import "USKTSPExperimentManager.h"
#import "USKTSPVisualizer.h"

@interface USKViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pathImageView;

@end

@implementation USKViewController {
	PathInfo pathToDraw;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	USKTSPVisualizer *visualizer = [[USKTSPVisualizer alloc] init];
	visualizer.imageView = self.pathImageView;
	
	USKTSPExperimentManager *experimentManager = [[USKTSPExperimentManager alloc] init];
	experimentManager.visualizer = visualizer;
	
	[experimentManager doExperiment:USKTSPExperimentNN2opt];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
