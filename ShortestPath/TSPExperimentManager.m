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

// First 10 random number generated by rand() with srand(123456789).
static const int seeds[NUMBER_OF_SEEDS] = {469049721, 2053676357, 1781357515, 1206231778, 891865166, 141988902, 553144097, 236130416, 94122056, 1361431000};

@implementation TSPExperimentManager {
	NSArray *_availableSampleNames;
}

- (id)init
{
    self = [super init];
    if (self) {
        // All samples available in TSPLIB
//        self.sampleNames = @[@"a280", @"ali535", @"att48", @"att532", @"bayg29", @"bays29", @"berlin52", @"bier127", @"burma14", @"ch130", @"ch150", @"d198", @"d493", @"d657", @"d1291", @"d1655", @"d2103", @"dantzig42", @"dsj1000", @"eil51", @"eil76", @"eil101", @"fl417", @"fl1400", @"fl1577", @"gr96", @"gr120", @"gr137", @"gr202", @"gr229", @"gr431", @"gr666", @"kroA100", @"kroB100", @"kroC100", @"kroD100", @"kroE100", @"kroA150", @"kroB150", @"kroA200", @"kroB200", @"lin105", @"lin318",/* can't read @"linhp318",*/ @"nrw1379", @"p654", @"pa561", @"pcb442", @"pcb1173", @"pr76", @"pr107", @"pr124", @"pr136", @"pr144", @"pr152", @"pr226", @"pr264", @"pr299", @"pr439", @"pr1002", @"pr2392", @"rat99", @"rat195", @"rat575", @"rat783", @"rd100", @"rd400", @"rl1304", @"rl1323", @"rl1889", @"st70", @"ts225", @"tsp225", @"u159", @"u574", @"u724", @"u1060", @"u1432", @"u1817", @"u2152", @"u2319", @"ulysses16", @"ulysses22", @"vm1084", @"vm1748"];
        
        // Selected samples for app (too big problem result in heating!)
        self.sampleNames = @[@"att48", @"bays29", @"berlin52", @"bier127", @"burma14", @"ch130", @"ch150", @"dantzig42", @"eil51", @"eil76", @"eil101", @"gr120", @"kroA100", @"kroB100", @"kroC100", @"kroD100", @"kroE100", @"kroA150", @"kroB150", @"kroA200", @"kroB200", @"lin105", @"lin318", @"pr76", @"pr107", @"pr124", @"pr136", @"pr144", @"pr152", @"rat99", @"rat195", @"rd100", @"st70", @"ts225", @"tsp225"];

        self.solverNames = @[@"Nearest Neighbor", @"Ant System", @"Max-Min Ant System"];
    }
    return self;
}

- (void)doExperiment:(USKTSPExperiment)experiment
{
	switch (experiment) {
		case USKTSPExperimentNN:             [self experimentNN];	 	      break;
		case USKTSPExperimentNN2opt:         [self experimentNN2opt];         break;
        case USKTSPExperimentASTuning:       [self experimentASTuning];       break;
        case USKTSPExperimentAS:             [self experimentAS];             break;
        case USKTSPExperimentMMASTuning:     [self experimentMMASTuning];     break;
        case USKTSPExperimentMMAS:           [self experimentMMAS];           break;
        case USKTSPExperimentMMAS2optTuning: [self experimentMMAS2optTuning]; break;
        case USKTSPExperimentMMAS2opt:       [self experimentMMAS2opt];       break;
        case USKTSPExperimentTSPTrial:       [self experimentTSPTrial];       break;
		case USKTSPExperimentOptimal:        [self experimentOptimal];        break;
		default:                                                              break;
	}
}

+ (BOOL)writeString:(NSString *)string toFileNamed:(NSString *)fileName
{
	NSArray	 *filePaths   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [filePaths objectAtIndex:0];
	NSString *outputPath  = [documentDir stringByAppendingPathComponent:fileName];
	NSURL    *outputURL   = [NSURL fileURLWithPath:outputPath];
	// Example Path: /Users/yusukeiwama/Library/Application Support/iPhone Simulator/7.0.3/Applications/85BB258F-2ED0-464C-AD92-1C5D11012E67/Documents

    if (string) {
        if ([string writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
            NSLog(@"%@ is saved", fileName);
            return YES;
        } else {
            NSLog(@"Failed to save %@", fileName);
            return NO;
        }
    } else {
        NSLog(@"Failed to save %@. The string is nil.", fileName);
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
			Tour aTour = [tsp tourByNNFrom:i + 1
                                   use2opt:NO];
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
        [self.visualizer drawTour:longestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_NN_Longest.png", sampleName]];

        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_NN_Shortest.png", sampleName]];
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
			Tour aTour = [tsp tourByNNFrom:i + 1
                                   use2opt:YES];
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
        [self.visualizer drawTour:longestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_NN2opt_Longest.png", sampleName]];
        
        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_NN2opt_Shortest.png", sampleName]];
	}
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"NN2optData.csv"];
	[TSPExperimentManager writeString:statisticString toFileNamed:@"NN2optStatistics.csv"];
}

- (void)experimentASTuning
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, SEED\n" mutableCopy];
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
                                       noImproveLimit:1000
                                    candidateListSize:20
                                              use2opt:NO
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
        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_AS_beta%d.png", sampleName, b]];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"ASTuningBetaData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"ASTuningBetaStatistics.csv"];
}

- (void)experimentAS
{
    NSMutableString *dataString	     = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, SEED\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];

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
            int beta = 2;
            double ro = 0.5;
            NSString *log;
            Tour aTour = [tsp tourByASWithNumberOfAnt:tsp.dimension
                                   pheromoneInfluence:a
                                  transitionInfluence:beta
                                 pheromoneEvaporation:ro
                                                 seed:seeds[ri]
                                       noImproveLimit:1000
                                    candidateListSize:20
                                              use2opt:NO
                                         CSVLogString:&log];
            lengths[ri] = aTour.distance;
			lengthSum += aTour.distance;
            [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %d\n", sampleName, tsp.dimension, aTour.distance, m, a, beta, ro, seeds[ri]]];
            
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
        [statisticString appendFormat:@"%@, %d, %d, %.2f, %d, %.2f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
        
        // Visualize the shortest path.
        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_AS.png", sampleName]];
        
        // Export iteration best tour distances log.
        [TSPExperimentManager writeString:shortestLog toFileNamed:[NSString stringWithFormat:@"%@_ASLog.csv", sampleName]];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"ASData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"ASStatistics.csv"];
}

- (void)experimentMMASTuning
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, SEED\n" mutableCopy];
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
            int      m = tsp.dimension;
            int      a = 1;
            double   r = 0.02;
            Tour aTour = [tsp tourByMMASWithNumberOfAnt:tsp.dimension
                                     pheromoneInfluence:a
                                    transitionInfluence:b
                                   pheromoneEvaporation:r
                                        probabilityBest:0.05
                                         takeGlogalBest:NO
                                                   seed:seeds[ri]
                                         noImproveLimit:1000
                                      candidateListSize:20
                                                use2opt:NO
                                              smoothing:0.5
                                           CSVLogString:NULL];
            lengths[ri] = aTour.distance;
			lengthSum += aTour.distance;
            [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %d\n", sampleName, tsp.dimension, aTour.distance, m, a, b, r, seeds[ri]]];
            
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
        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_MMAS_beta%d.png", sampleName, b]];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"MMASTuningBetaData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"MMASTuningBetaStatistics.csv"];
}

- (void)experimentMMAS
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, SEED\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];
    
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
            int    m     = tsp.dimension;
            int    alpha = 1;
            int    beta  = 4;
            double rho   = 0.02;
            NSString *log;
            Tour aTour = [tsp tourByMMASWithNumberOfAnt:tsp.dimension
                                     pheromoneInfluence:alpha
                                    transitionInfluence:beta
                                   pheromoneEvaporation:rho
                                        probabilityBest:0.05
                                         takeGlogalBest:NO
                                                   seed:seeds[ri]
                                         noImproveLimit:1000
                                      candidateListSize:20
                                                use2opt:NO
                                              smoothing:0.5
                                           CSVLogString:&log];
            lengths[ri] = aTour.distance;
			lengthSum += aTour.distance;
            [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %d\n", sampleName, tsp.dimension, aTour.distance, m, alpha, beta, rho, seeds[ri]]];
            
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
        [statisticString appendFormat:@"%@, %d, %d, %.2f, %d, %.2f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
        
        // Visualize the shortest path.
        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_MMAS.png", sampleName]];

        // Export iteration best tour distances log.
        [TSPExperimentManager writeString:shortestLog toFileNamed:[NSString stringWithFormat:@"%@_MMASLog.csv", sampleName]];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"MMASData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"MMASStatistics.csv"];
}

- (void)experimentMMAS2optTuning
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, PBEST, SEED, LIMIT\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA, RHO, PBEST\n" mutableCopy];
    
    NSArray *sampleNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130"];
	for (NSString *sampleName in sampleNames) {
        TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
        double rho[6]   = {0.01, 0.02, 0.1, 0.2, 0.5, 0.8};
        double pBest[6] = {0.001, 0.005, 0.01, 0.05, 0.1, 0.5};
        Tour globalBest = {INT32_MAX, calloc(tsp.dimension + 1, sizeof(int))};
        for (int r = 0; r < 6; r++) {
            for (int p = 0; p < 6; p++) {
                int  lengths[NUMBER_OF_SEEDS];
                int	 lengthSum    = 0;
                Tour iterationBest  = {INT32_MAX, calloc(tsp.dimension + 1, sizeof(int))};
                Tour iterationWorst = {0,         calloc(tsp.dimension + 1, sizeof(int))};
                for (int ri = 0; ri < NUMBER_OF_SEEDS; ri++) {
                    // Compute average path length.
                    int      m = 25;
                    int  alpha = 1;
                    int   beta = 4;
                    int  limit = 200;
                    Tour aTour = [tsp tourByMMASWithNumberOfAnt:m
                                             pheromoneInfluence:alpha
                                            transitionInfluence:beta
                                           pheromoneEvaporation:rho[r]
                                                probabilityBest:pBest[p]
                                                 takeGlogalBest:NO
                                                           seed:seeds[ri]
                                                 noImproveLimit:limit
                                                  candidateListSize:20
                                                            use2opt:YES
                                                      smoothing:0.5
                                                   CSVLogString:NULL];
                    lengths[ri] =  aTour.distance;
                    lengthSum   += aTour.distance;
                    [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %.2f, %d, %d\n", sampleName, m, aTour.distance, m, alpha, beta, rho[r], pBest[p], seeds[ri], limit]];
                    
                    // Update iteration best and worst. (not assign but memcpy to simplify free-related code.)
                    if (aTour.distance > iterationWorst.distance) {
                        memcpy(iterationWorst.route, aTour.route, tsp.dimension * sizeof(int));
                        iterationWorst.distance = aTour.distance;
                    }
                    if (aTour.distance < iterationBest.distance) {
                        memcpy(iterationBest.route, aTour.route, tsp.dimension * sizeof(int));
                        iterationBest.distance = aTour.distance;
                    }
                    free(aTour.route);
                }
                // Compute statistics.
                double averageLength = (double)lengthSum / NUMBER_OF_SEEDS;
                double deviationSumSquare = 0.0;
                for (int i = 0; i < NUMBER_OF_SEEDS; i++) {
                    deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
                }
                double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
                [statisticString appendFormat:@"%@, %d, %d, %.2f, %d, %.2f, %.4f, %.4f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, iterationBest.distance, averageLength, iterationWorst.distance, standardDeviation, rho[r], pBest[p]];

                // Update global best (not assign but memcpy to simplify free-related code.)
                if (iterationBest.distance < globalBest.distance) {
                    memcpy(globalBest.route, iterationBest.route, tsp.dimension * sizeof(int));
                    globalBest.distance = iterationBest.distance;
                }
                free(iterationBest.route);
                free(iterationWorst.route);
            }
        }
        // Visualize the shortest path.
        [self.visualizer drawTour:globalBest withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_MMAS2opt.png", sampleName]];

        free(globalBest.route);
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"MMAS2optTuningData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"MMAS2optTuningStatistics.csv"];
}

- (void)experimentMMAS2opt
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, PBEST, SEED, LIMIT\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];
    
    NSArray *sampleNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130"];
	for (NSString *sampleName in sampleNames) {
        TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];

        int  lengths[NUMBER_OF_SEEDS];
        int	 lengthSum     = 0;
        Tour shortestTour  = {INT32_MAX, calloc(tsp.dimension + 1, sizeof(int))};
        Tour longestTour   = {0,         calloc(tsp.dimension + 1, sizeof(int))};
        NSString *shortestLog;
        for (int ri = 0; ri < NUMBER_OF_SEEDS; ri++) {
            // Compute average path length.
            int    m     = 25;
            int    alpha = 1;
            int    beta  = 5;
            double rho   = 0.1;
            double pBest = 0.1;
            int    limit = 200;
            NSString *log;
            Tour aTour = [tsp tourByMMASWithNumberOfAnt:m
                                         pheromoneInfluence:alpha
                                        transitionInfluence:beta
                                       pheromoneEvaporation:rho
                                            probabilityBest:pBest
                                         takeGlogalBest:NO
                                                       seed:seeds[ri]
                                             noImproveLimit:limit
                                          candidateListSize:20
                                                    use2opt:YES
                                              smoothing:0.5
                                               CSVLogString:&log];
            lengths[ri] =  aTour.distance;
            lengthSum   += aTour.distance;
            [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %.2f, %d, %d\n", sampleName, m, aTour.distance, m, alpha, beta, rho, pBest, seeds[ri], limit]];
            
            // Update iteration best and worst. (not assign but memcpy to simplify free-related code.)
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
        // Compute statistics.
        double averageLength      = (double)lengthSum / NUMBER_OF_SEEDS;
        double deviationSumSquare = 0.0;
        for (int i = 0; i < NUMBER_OF_SEEDS; i++) {
            deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
        }
        double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
        [statisticString appendFormat:@"%@, %d, %d, %.2f, %d, %.2f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
        
        // Visualize the shortest path.
        [self.visualizer drawTour:shortestTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_MMAS2opt.png", sampleName]];
        
        free(shortestTour.route);
        
        // Export iteration best tour distances log.
        [TSPExperimentManager writeString:shortestLog toFileNamed:[NSString stringWithFormat:@"%@_MMAS2optLog.csv", sampleName]];
    }
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"MMAS2optData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"MMAS2optStatistics.csv"];
}

- (void)experimentTSPTrial
{
    NSMutableString *dataString      = [@"NAME, DIMENSION, LENGTH, M, ALPHA, BETA, RHO, PBEST, SEED, LIMIT\n" mutableCopy];
	NSMutableString *statisticString = [@"NAME, OPTIMAL, SHORTEST, AVE, LONGEST, SIGMA\n" mutableCopy];
    
    NSString *sampleName = @"tsp225";

    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
    
    int  lengths[NUMBER_OF_SEEDS];
    int	 lengthSum     = 0;
    Tour shortestTour  = {INT32_MAX, calloc(tsp.dimension + 1, sizeof(int))};
    Tour longestTour   = {0,         calloc(tsp.dimension + 1, sizeof(int))};
    NSString *shortestLog;
    
    // MMAS2opt
    for (int ri = 0; ri < NUMBER_OF_SEEDS; ri++) {
        // Compute average path length.
        int    m     = 25;
        int    alpha = 1;
        int    beta  = 5;
        double rho   = 0.2;
        double pBest = 0.005;
        int    limit = 200;
        NSString *log;
        Tour aTour = [tsp tourByMMASWithNumberOfAnt:m
                                     pheromoneInfluence:alpha
                                    transitionInfluence:beta
                                   pheromoneEvaporation:rho
                                        probabilityBest:pBest
                                     takeGlogalBest:NO
                                                   seed:seeds[ri]
                                         noImproveLimit:limit
                                      candidateListSize:20
                                                use2opt:YES
                                          smoothing:0.5
                                           CSVLogString:&log];
        lengths[ri] =  aTour.distance;
        lengthSum   += aTour.distance;
        [dataString appendString:[NSString stringWithFormat:@"%@, %d, %d, %d, %d, %d, %.2f, %.4f, %d, %d\n", sampleName, m, aTour.distance, m, alpha, beta, rho, pBest, seeds[ri], limit]];
        
        // Update iteration best and worst. (not assign but memcpy to simplify free-related code.)
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
    // Compute statistics.
    double averageLength      = (double)lengthSum / NUMBER_OF_SEEDS;
    double deviationSumSquare = 0.0;
    for (int i = 0; i < NUMBER_OF_SEEDS; i++) {
        deviationSumSquare += (lengths[i] - averageLength) * (lengths[i] - averageLength);
    }
    double standardDeviation = sqrt(deviationSumSquare / tsp.dimension);
    [statisticString appendFormat:@"%@, %d, %d, %.2f, %d, %.2f\n", sampleName, [TSP optimalSolutionWithName:sampleName].distance, shortestTour.distance, averageLength, longestTour.distance, standardDeviation];
    
    // Visualize the shortest path.
    [self.visualizer drawTour:shortestTour withTSP:tsp];
    [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_MMAS2opt.png", sampleName]];
    
    free(shortestTour.route);
    
    // Export iteration best tour distances log.
    [TSPExperimentManager writeString:shortestLog toFileNamed:[NSString stringWithFormat:@"%@_MMAS2optLog.csv", sampleName]];
	
	// Export data
	[TSPExperimentManager writeString:dataString      toFileNamed:@"MMAS2optTSPTrialData.csv"];
    [TSPExperimentManager writeString:statisticString toFileNamed:@"MMAS2optTSPTrialStatistics.csv"];
}

- (void)experimentOptimal
{
	for (NSString *sampleName in self.sampleNames) {
		TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
		Tour anOptimalTour = [TSP optimalSolutionWithName:sampleName];
        [self.visualizer drawTour:anOptimalTour withTSP:tsp];
        [self.visualizer PNGWithImageOnImageView:self.visualizer.view.tourImageView fileName:[NSString stringWithFormat:@"%@_Optimal.png", sampleName]];
		free(anOptimalTour.route);
	}
}

@end
