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
	
    BOOL test = NO;
    if (!test) {
        TSPVisualizer *visualizer = [[TSPVisualizer alloc] init];
        visualizer.imageView = self.pathImageView;
        
        TSPExperimentManager *experimentManager = [[TSPExperimentManager alloc] init];
        experimentManager.visualizer = visualizer;
        
        
        srand((unsigned)time(NULL));
        
        TSP *tsp  = [TSP randomTSPWithDimension:14 seed:rand()];
        Tour tour = [tsp tourByMMAS2optWithNumberOfAnt:25
                                    pheromoneInfluence:1
                                   transitionInfluence:4
                                  pheromoneEvaporation:0.02
                                       probabilityBest:0.001
                                                  seed:rand()
                                        noImproveLimit:200
                                     candidateListSize:20
                                          CSVLogString:NULL];
        [visualizer drawNodesWithTSP:tsp withStyle:TSPVisualizationStyleLight];
//        [visualizer drawPath:tour ofTSP:tsp withStyle:TSPVisualizationStyleLight];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
