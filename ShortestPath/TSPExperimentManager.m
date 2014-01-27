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

@implementation TSPExperimentManager {
	NSArray *_sampleFileNames;
	NSArray *_allFileNames;
}

- (void)doExperiment:(USKTSPExperiment)experiment
{
	switch (experiment) {
		case USKTSPExperimentNN:	  [self experimentNN];		break;
		case USKTSPExperimentNN2opt:  [self experimentNN2opt];	break;
		case USKTSPExperimentOptimal: [self experimentOptimal]; break;
		default:												break;
	}
}

- (void)loadSampleFileNames
{
	_sampleFileNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130", @"tsp225"];
}

- (void)loadAllFileNames
{
	_allFileNames = @[@"a280", @"ali535", @"att48", @"att532", @"bayg29", @"bays29", @"berlin52", @"bier127", @"brazil58", @"brd14051",	@"brg180", @"burma14", @"ch130", @"ch150", @"d198", @"d493", @"d657", @"d1291", @"d1655", @"d2103", @"d15112", @"d18512", @"dantzig42", @"dsj1000", @"eil51", @"eil76", @"eil101", @"fl417", @"fl1400", @"fl1577", @"fl3795", @"fnl4461", @"fri26", @"gil262", @"gr17", @"gr21", @"gr24", @"gr48", @"gr96", @"gr120", @"gr137", @"gr202", @"gr229", @"gr431", @"gr666", @"hk48", @"kroA100", @"kroB100", @"kroC100", @"kroD100", @"kroE100", @"kroA150", @"kroB150", @"kroA200", @"kroB200", @"lin105", @"lin318", @"linhp318", @"nrw1379", @"p654", @"pa561", @"pcb442", @"pcb1173", @"pcb3038", @"pla7397", @"pla33810", @"pla85900", @"pr76", @"pr107", @"pr124", @"pr136", @"pr144", @"pr152", @"pr226", @"pr264", @"pr299", @"pr439", @"pr1002", @"pr2392", @"rat99", @"rat195", @"rat575", @"rat783", @"rd100", @"rd400", @"rl1304", @"rl1323", @"rl1889", @"rl5915", @"rl5934", @"rl11849", @"si175", @"si535", @"si1032", @"st70", @"swiss42", @"ts225", @"tsp225", @"u159", @"u574", @"u724", @"u1060", @"u1432", @"u1817", @"u2152", @"u2319", @"ulysses16", @"ulysses22", @"usa13509", @"vm1084", @"vm1748"];
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
	
	[self loadSampleFileNames];
	for (NSString *sampleName in _sampleFileNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		
		// Compute average path length.
		int	lengthSum = 0;
		Tour shortPath = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
		Tour longPath  = {0,         calloc(tsp.dimension, sizeof(int))};
		int lengths[tsp.dimension];
		for (int i = 0; i < tsp.dimension; i++) {
			Tour aPath = [tsp tourByNNFrom:i + 1];
			lengths[i] = aPath.length;
			lengthSum += aPath.length;
			[dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d\n", sampleName, tsp.dimension, i + 1, aPath.length]];
			if (aPath.length > longPath.length) {
                memcpy(longPath.route, aPath.route, tsp.dimension * sizeof(int));
                longPath.length = aPath.length;
			}
			if (aPath.length < shortPath.length) {
			    memcpy(shortPath.route, aPath.route, tsp.dimension * sizeof(int));
                shortPath.length = aPath.length;
			}
            free(aPath.route);
		}
		double averageLength = (double)lengthSum / tsp.dimension;

		
		// Compute standard deviation.
		double deviationSumSquare = 0.0;
		for (int i = 0; i < tsp.dimension; i++) {
			deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
		}
		double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
		[statisticString appendFormat:@"%@, %d, %d, %.0f, %d, %.0f\n", sampleName, [TSP optimalSolutionWithName:sampleName].length, shortPath.length, averageLength, longPath.length, standardDeviation];
		
		// Visualize the shortest path.
		[self.visualizer PNGWithPath:longPath ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN_Long.png", sampleName] withStyle:TSPVisualizationStylePrinting];
		[self.visualizer PNGWithPath:shortPath ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN_Short.png", sampleName] withStyle:TSPVisualizationStylePrinting];
	}
	
	// Export data
	[TSPExperimentManager writeString:dataString		 toFileNamed:@"NNData.csv"];
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
	
	[self loadSampleFileNames];
	for (NSString *sampleName in _sampleFileNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		
		// Compute average path length.
		int	lengthSum = 0;
		Tour shortPath = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
		Tour longPath  = {0,         calloc(tsp.dimension, sizeof(int))};
		int lengths[tsp.dimension];
		for (int i = 0; i < tsp.dimension; i++) {
			Tour aPath = [tsp tourByNNFrom:i + 1];
			[tsp improveTourBy2opt:&aPath];
			lengths[i] = aPath.length;
			lengthSum += aPath.length;
			[dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d\n", sampleName, tsp.dimension, i + 1, aPath.length]];
			if (aPath.length > longPath.length) {
                memcpy(longPath.route, aPath.route, tsp.dimension * sizeof(int));
                longPath.length = aPath.length;
			}
			if (aPath.length < shortPath.length) {
			    memcpy(shortPath.route, aPath.route, tsp.dimension * sizeof(int));
                shortPath.length = aPath.length;
			}
            free(aPath.route);
		}
		double averageLength = (double)lengthSum / tsp.dimension;
		
		// Compute standard deviation.
		double deviationSumSquare = 0.0;
		for (int i = 0; i < tsp.dimension; i++) {
			deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
		}
		double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
		[statisticString appendFormat:@"%@, %d, %d, %.0f, %d, %.0f\n", sampleName, [TSP optimalSolutionWithName:sampleName].length, shortPath.length, averageLength, longPath.length, standardDeviation];

		// Visualize the shortest path.
		[self.visualizer PNGWithPath:longPath ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN2opt_Long.png", sampleName] withStyle:TSPVisualizationStylePrinting];
		[self.visualizer PNGWithPath:shortPath ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_NN2opt_Short.png", sampleName] withStyle:TSPVisualizationStyleMidnight];
	}
	
	// Export data
	[TSPExperimentManager writeString:dataString		 toFileNamed:@"NN2optData.csv"];
	[TSPExperimentManager writeString:statisticString toFileNamed:@"NN2optStatistics.csv"];
}

- (void)experimentOptimal
{
	[self loadAllFileNames];
	for (NSString *sampleName in _allFileNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		Tour anOptimalPath = [TSP optimalSolutionWithName:sampleName];
		[self.visualizer PNGWithPath:anOptimalPath ofTSP:tsp toFileNamed:[NSString stringWithFormat:@"%@_Optimal.png", sampleName] withStyle:TSPVisualizationStyleMidnight];
		free(anOptimalPath.route);
	}
}


@end
