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
	
    BOOL test = YES;
    if (!test) {
        TSPVisualizer *visualizer = [[TSPVisualizer alloc] init];
        visualizer.imageView = self.pathImageView;
        
        TSPExperimentManager *experimentManager = [[TSPExperimentManager alloc] init];
        experimentManager.visualizer = visualizer;
        
        
        NSString *sampleName = @"pr76";
        TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
        
        // Compute the shortest path.
        Tour tour = [tsp tourByMMAS2optWithNumberOfAnt:25
                                    pheromoneInfluence:1
                                   transitionInfluence:4
                                  pheromoneEvaporation:0.01
                                       probabilityBest:0.001
                                                  seed:469049721
                                        noImproveLimit:200
                                     candidateListSize:20
                                          CSVLogString:NULL];
        
//         Tour tour = [tsp tourByNNFrom:1];
//        [tsp improveTourBy2opt:&tour];
        
        [visualizer drawPath:tour ofTSP:tsp withStyle:TSPVisualizationStyleLight];
        printf("distance = %d\n", tour.distance);
        
        //	[experimentManager doExperiment:USKTSPExperimentTSPTrial];
        
        //    TSP *tsp  = [TSP randomTSPWithDimension:1000];
        //    Tour tour = [tsp tourByNNFrom:100];
        //    [tsp improveTourBy2opt:&tour];
        //    [visualizer drawPath:tour ofTSP:tsp withStyle:TSPVisualizationStyleDark];    

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
