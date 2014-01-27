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

@implementation USKTSPExperimentManager {
	NSArray *_sampleFileNames;
}

- (void)doExperiment:(USKTSPExperiment)experiment
{
	switch (experiment) {
		case USKTSPExperimentNN:	 [self experimentNN];		break;
		case USKTSPExperimentNN2opt: [self experimentNN2opt];	break;
		default:												break;
	}
}

- (void)loadSampleFileNames
{
	_sampleFileNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130"];
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
		return NO;
	}
}

#pragma mark - USKTSPExperiments

- (void)experimentNN
{
	NSMutableString *dataString		 = [@"NAME, DIMENSION, START_NODE, LENGTH\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];
	
	[self loadSampleFileNames];
	for (NSString *fileName in _sampleFileNames) {
		USKTSP *tsp = [USKTSP TSPWithFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"tsp"]];
		
		// Compute average path length.
		int	lengthSum = 0;
		int shortest  = INT32_MAX;
		int longest   = 0;
		int lengths[tsp.dimension];
		for (int i = 0; i < tsp.dimension; i++) {
			PathInfo aPath = [tsp shortestPathByNNFrom:i + 1];
			lengths[i] = aPath.length;
			lengthSum += aPath.length;
			[dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d\n", fileName, tsp.dimension, i + 1, aPath.length]];
			if (aPath.length < shortest) shortest = aPath.length;
			if (aPath.length > longest)  longest  = aPath.length;
			[USKTSP freePath:aPath];
		}
		double averageLength = (double)lengthSum / tsp.dimension;
		
		// Compute standard deviation.
		double deviationSumSquare = 0.0;
		for (int i = 0; i < tsp.dimension; i++) {
			deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
		}
		double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
		[statisticString appendFormat:@"%@, %d, %d, %.0f, %d, %.0f\n", fileName, [USKTSP optimalSolutionWithName:fileName].length, shortest, averageLength, longest, standardDeviation];
	}
	
	// Export data
	[USKTSPExperimentManager writeString:dataString		 toFileNamed:@"NNData.csv"];
	[USKTSPExperimentManager writeString:statisticString toFileNamed:@"NNStatistics.csv"];
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
	for (NSString *fileName in _sampleFileNames) {
		USKTSP *tsp = [USKTSP TSPWithFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"tsp"]];
		
		// Compute average path length.
		int	lengthSum = 0;
		int shortest  = INT32_MAX;
		int longest   = 0;
		int lengths[tsp.dimension];
		for (int i = 0; i < tsp.dimension; i++) {
			PathInfo aPath = [tsp shortestPathByNNFrom:i + 1];
			[tsp improvePathBy2opt:&aPath];
			lengths[i] = aPath.length;
			lengthSum += aPath.length;
			[dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d\n", fileName, tsp.dimension, i + 1, aPath.length]];
			if (aPath.length < shortest) shortest = aPath.length;
			if (aPath.length > longest)  longest  = aPath.length;
			[USKTSP freePath:aPath];
		}
		double averageLength = (double)lengthSum / tsp.dimension;
		
		// Compute standard deviation.
		double deviationSumSquare = 0.0;
		for (int i = 0; i < tsp.dimension; i++) {
			deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
		}
		double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
		[statisticString appendFormat:@"%@, %d, %d, %.0f, %d, %.0f\n", fileName, [USKTSP optimalSolutionWithName:fileName].length, shortest, averageLength, longest, standardDeviation];
	}
	
	// Export data
	[USKTSPExperimentManager writeString:dataString		 toFileNamed:@"NN2optData.csv"];
	[USKTSPExperimentManager writeString:statisticString toFileNamed:@"NN2optStatistics.csv"];
}


@end
