//
//  USKTSPExperimentManager.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "USKTSPExperimentManager.h"
#import "USKTSP.h"
#import "USKTSPVisualizer.h"

// NSArray *array = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130"];

@implementation USKTSPExperimentManager

- (void)doExperiment:(USKTSPExperiment)experiment
{
	switch (experiment) {
		case USKTSPExperimentNN:	 [self experimentNN];		break;
		case USKTSPExperimentNN2opt: [self experimentNN2opt];	break;
		default:												break;
	}
}


#pragma mark - USKTSPExperiments

- (void)experimentNN
{

}

- (void)experimentNN2opt
{
	USKTSP *tsp = [USKTSP TSPWithFile:[[NSBundle mainBundle] pathForResource:@"eil51" ofType:@"tsp"]];
	
	double lengthSum = 0;
	PathInfo shortestPath = {MAXFLOAT, NULL};
	for (int i = 0; i < tsp.dimension; i++) {
		PathInfo shortPath = [tsp shortestPathByNNFrom:i + 1];
		printf("NN = %d, ", shortPath.length);
		[tsp improvePathBy2opt:&shortPath];
		if (shortPath.length < shortestPath.length) {
			[tsp freePath:shortestPath];
			shortestPath = shortPath;
		} else {
			[tsp freePath:shortPath];
		}
		lengthSum += shortPath.length;
		printf("2opt = %d\n", shortPath.length);
	}
	printf("\nAverage = %.3f\nShortest = %d\n", lengthSum / tsp.dimension, shortestPath.length);
	[tsp printPath:shortestPath];
	
	[self.visualizer drawPath:shortestPath ofTSP:tsp];
}


@end
