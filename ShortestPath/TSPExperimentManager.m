//
//  USKTSPExperimentManager.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPExperimentManager.h"
#import "TSP.h"
#import "TSPVisualizer.h"

#define NUMBER_OF_SEEDS 10
#define OPTIMAL_BETA 5

static const int seeds[NUMBER_OF_SEEDS] = {101, 103, 107, 109, 113, 127, 131, 137, 139, 149};

@implementation TSPExperimentManager {
	NSArray *_allSampleNames;
}

- (void)doExperiment:(USKTSPExperiment)experiment
{
	switch (experiment) {
		case USKTSPExperimentNN:	       [self experimentNN];	 	  break;
		case USKTSPExperimentNN2opt:       [self experimentNN2opt];   break;
        case USKTSPExperimentAS:           [self experimentAS];       break;
        case USKTSPExperimentASTuningBeta: [self experimentASTuning]; break;
		case USKTSPExperimentOptimal:      [self experimentOptimal];  break;
		default:                                                      break;
	}
}

- (void)loadAllFileNames
{
	_allSampleNames = @[@"a280", @"ali535", @"att48", @"att532", @"bayg29", @"bays29", @"berlin52", @"bier127", @"brazil58", @"brd14051",	@"brg180", @"burma14", @"ch130", @"ch150", @"d198", @"d493", @"d657", @"d1291", @"d1655", @"d2103", @"d15112", @"d18512", @"dantzig42", @"dsj1000", @"eil51", @"eil76", @"eil101", @"fl417", @"fl1400", @"fl1577", @"fl3795", @"fnl4461", @"fri26", @"gil262", @"gr17", @"gr21", @"gr24", @"gr48", @"gr96", @"gr120", @"gr137", @"gr202", @"gr229", @"gr431", @"gr666", @"hk48", @"kroA100", @"kroB100", @"kroC100", @"kroD100", @"kroE100", @"kroA150", @"kroB150", @"kroA200", @"kroB200", @"lin105", @"lin318", @"linhp318", @"nrw1379", @"p654", @"pa561", @"pcb442", @"pcb1173", @"pcb3038", @"pla7397", @"pla33810", @"pla85900", @"pr76", @"pr107", @"pr124", @"pr136", @"pr144", @"pr152", @"pr226", @"pr264", @"pr299", @"pr439", @"pr1002", @"pr2392", @"rat99", @"rat195", @"rat575", @"rat783", @"rd100", @"rd400", @"rl1304", @"rl1323", @"rl1889", @"rl5915", @"rl5934", @"rl11849", @"si175", @"si535", @"si1032", @"st70", @"swiss42", @"ts225", @"tsp225", @"u159", @"u574", @"u724", @"u1060", @"u1432", @"u1817", @"u2152", @"u2319", @"ulysses16", @"ulysses22", @"usa13509", @"vm1084", @"vm1748"];
}

+ (BOOL)writeString:(NSString *)string toFileNamed:(NSString *)fileName
{
	NSArray	 *filePaths   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [filePaths objectAtIndex:0];
	NSString *outputPath  = [documentDir stringByAppendingPathComponent:fileName];
	NSURL    *outputURL   = [NSURL fileURLWithPath:outputPath];
	// Example Path: /Users/yusukeiwama/Library/Application Support/iPhone Simulator/7.0.3/Applications/85BB258F-2ED0-464C-AD92-1C5D11012E67/Documents

	if ([string writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
		NSLog(@"%@ is saved", fileName);
		return YES;
	} else {
		NSLog(@"Failed to save %@", fileName);
		return NO;
	}
}

#pragma mark - USKTSPExperiments

- (void)experimentNN
{
	NSMutableString *dataString		 = [@"NAME, DIMENSION, START_NODE, LENGTH\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];

    NSArray *sampleNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130"];
	for (NSString *sampleName in sampleNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		
		// Compute average path length.
		int	lengthSum = 0;
		Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
		Tour longestTour  = {0,         calloc(tsp.dimension, sizeof(int))};
		int lengths[tsp.dimension];
		for (int i = 0; i < tsp.dimension; i++) {
			Tour aTour = [tsp tourByNNFrom:i + 1];
			lengths[i] = aTour.distance;
			lengthSum += aTour.distance;
			[dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d\n", sampleName, tsp.dimension, i + 1, aTour.distance]];
			if (aTour.distance > longestTour.distance) {
                memcpy(longestTour.route, aTour.route, tsp.dimension * sizeof(int));
                longestTour.distance = aTour.distance;
			}
			if (aTour.distance < shortestTour.distance) {
			    memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
                shortestTour.distance = aTour.distance;
			}
            free(aTour.route);
		}
		double averageLength = (double)lengthSum / tsp.dimension;
		
		// Compute standard deviation.
		double deviationSumSquare = 0.0;
		for (int i = 0; i < tsp.dimension; i++) {
			deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
		}
		double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
		[statisticString appendFormat:@"%@, %d, %d, %.0f, %d, %.0f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
        
		// Visualize the shortest path.
		[self.visualizer PNGWithPath:longestTour ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN_Longest.png", sampleName] withStyle:TSPVisualizationStyleLight];
		[self.visualizer PNGWithPath:shortestTour ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN_Shortest.png", sampleName] withStyle:TSPVisualizationStyleLight];
	}
	
	// Export data
	[TSPExperimentManager writeString:dataString	  toFileNamed:@"NNData.csv"];
	[TSPExperimentManager writeString:statisticString toFileNamed:@"NNStatistics.csv"];
}

/**
 Solves sample TSPs by Nearest Neighbor(NN) AND 2-opt.
 Computes NN from each nodes, so number of computation is 'dimension' for each sample TSP.
 Exports average path length and its standard deviation in CSV format.
 */
- (void)experimentNN2opt
{
	NSMutableString *dataString		 = [@"NAME, DIMENSION, START_NODE, LENGTH\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];

    NSArray *sampleNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130"];
	for (NSString *sampleName in sampleNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		
		// Compute average path length.
		int	lengthSum = 0;
		Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
		Tour longestTour  = {0,         calloc(tsp.dimension, sizeof(int))};
		int lengths[tsp.dimension];
		for (int i = 0; i < tsp.dimension; i++) {
			Tour aTour = [tsp tourByNNFrom:i + 1];
			[tsp improveTourBy2opt:&aTour];
			lengths[i] = aTour.distance;
			lengthSum += aTour.distance;
			[dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d\n", sampleName, tsp.dimension, i + 1, aTour.distance]];
			if (aTour.distance > longestTour.distance) {
                memcpy(longestTour.route, aTour.route, tsp.dimension * sizeof(int));
                longestTour.distance = aTour.distance;
			}
			if (aTour.distance < shortestTour.distance) {
			    memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
                shortestTour.distance = aTour.distance;
			}
            free(aTour.route);
		}
		double averageLength = (double)lengthSum / tsp.dimension;
		
		// Compute standard deviation.
		double deviationSumSquare = 0.0;
		for (int i = 0; i < tsp.dimension; i++) {
			deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
		}
		double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
		[statisticString appendFormat:@"%@, %d, %d, %.0f, %d, %.0f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];

		// Visualize the shortest path.
		[self.visualizer PNGWithPath:longestTour ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN2opt_Longest.png", sampleName] withStyle:TSPVisualizationStyleLight];
		[self.visualizer PNGWithPath:shortestTour ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN2opt_Shortest.png", sampleName] withStyle:TSPVisualizationStyleLight];
	}
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"NN2optData.csv"];
	[TSPExperimentManager writeString:statisticString toFileNamed:@"NN2optStatistics.csv"];
}

- (void)experimentASTuning
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RO, SEED\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, BETA, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];

    NSString *sampleName = @"eil51";
    for (int b = 2; b <= 5; b++) {
        TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
        int	lengthSum = 0;
        int lengths[NUMBER_OF_SEEDS];
        Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
        Tour longestTour  = {0,         calloc(tsp.dimension, sizeof(int))};
        
        for (int ri = 0; ri < NUMBER_OF_SEEDS; ri++) {
            // Compute average path length.
            int m = tsp.dimension;
            int a = 1;
            double ro = 0.5;
            Tour aTour = [tsp tourByASWithNumberOfAnt:tsp.dimension
                                  pheromoneInfluence:a
                                 transitionInfluence:b
                                pheromoneEvaporation:ro
                                                seed:seeds[ri]
                                         CSVLogString:NULL];
            lengths[ri] = aTour.distance;
			lengthSum += aTour.distance;
            [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %d\n", sampleName, tsp.dimension, aTour.distance, m, a, b, ro, seeds[ri]]];

			if (aTour.distance > longestTour.distance) {
                memcpy(longestTour.route, aTour.route, tsp.dimension * sizeof(int));
                longestTour.distance = aTour.distance;
			}
			if (aTour.distance < shortestTour.distance) {
			    memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
                shortestTour.distance = aTour.distance;
			}

            free(aTour.route);
        }
        double averageLength = (double)lengthSum / NUMBER_OF_SEEDS;
        
        // Compute standard deviation.
        double deviationSumSquare = 0.0;
        for (int i = 0; i < NUMBER_OF_SEEDS; i++) {
            deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
        }
        double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
        [statisticString appendFormat:@"%@, %d, %d, %d, %.2f, %d, %.2f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, b, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
        
        
        // Visualize the shortest path.
        [self.visualizer PNGWithPath:shortestTour ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_AS_beta%d.png", sampleName, b] withStyle:TSPVisualizationStyleLight];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"ASTuningBetaData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"ASTuningBetaStatistics.csv"];
}

- (void)experimentAS
{
    NSMutableString *dataString	     = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RO, SEED\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, BETA, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];

    NSArray *sampleNames = @[@"pr76", @"rat99", @"kroA100", @"ch130"];
    for (NSString *sampleName in sampleNames) {
        TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
        int	lengthSum = 0;
        int lengths[NUMBER_OF_SEEDS];
        Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
        Tour longestTour  = {0,         calloc(tsp.dimension, sizeof(int))};
        NSString *shortestLog;
        for (int ri = 0; ri < NUMBER_OF_SEEDS; ri++) {
            // Compute average path length.
            int m = tsp.dimension;
            int a = 1;
            double ro = 0.5;
            NSString *log;
            Tour aTour = [tsp tourByASWithNumberOfAnt:tsp.dimension
                                   pheromoneInfluence:a
                                  transitionInfluence:OPTIMAL_BETA
                                 pheromoneEvaporation:ro
                                                 seed:seeds[ri]
                                         CSVLogString:&log];
            lengths[ri] = aTour.distance;
			lengthSum += aTour.distance;
            [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %d\n", sampleName, tsp.dimension, aTour.distance, m, a, OPTIMAL_BETA, ro, seeds[ri]]];
            
			if (aTour.distance > longestTour.distance) {
                memcpy(longestTour.route, aTour.route, tsp.dimension * sizeof(int));
                longestTour.distance = aTour.distance;
			}
			if (aTour.distance < shortestTour.distance) {
			    memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
                shortestTour.distance = aTour.distance;
                shortestLog = log;
			}
            
            free(aTour.route);
        }
        double averageLength = (double)lengthSum / NUMBER_OF_SEEDS;
        
        // Compute standard deviation.
        double deviationSumSquare = 0.0;
        for (int i = 0; i < NUMBER_OF_SEEDS; i++) {
            deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
        }
        double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
        [statisticString appendFormat:@"%@, %d, %d, %d, %.2f, %d, %.2f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, OPTIMAL_BETA, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
        
        // Visualize the shortest path.
        [self.visualizer PNGWithPath:shortestTour ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_AS_beta%d.png", sampleName, OPTIMAL_BETA] withStyle:TSPVisualizationStyleLight];
        
        // Export iteration best tour distances log.
        [TSPExperimentManager writeString:shortestLog toFileNamed:[NSString stringWithFormat:@"%@_ASLog.csv", sampleName]];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"ASData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"ASStatistics.csv"];

}

- (void)experimentOptimal
{
	[self loadAllFileNames];
	for (NSString *sampleName in _allSampleNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		Tour anOptimalPath = [TSP optimalSolutionWithName:sampleName];
		[self.visualizer PNGWithPath:anOptimalPath ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_Optimal.png", sampleName] withStyle:TSPVisualizationStyleDark];
		free(anOptimalPath.route);
	}
}


@end
