//
//  ShortestPathTests.m
//  ShortestPathTests
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSP.h"
#import "USKTrimmer.h"

@interface ShortestPathTests : XCTestCase

@end

@implementation ShortestPathTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//
///// Check if the shortest path length is longer than the optimal path.
//- (void)testNN
//{
//    NSString *sampleName = @"ch130";
//    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
//    
//    // Compute the shortest path.
//    Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
//    for (int i = 0; i < tsp.dimension; i++) {
//        Tour aTour = [tsp tourByNNFrom:i + 1 use2opt:NO];
//        if (aTour.distance < shortestTour.distance) {
//            memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
//            shortestTour.distance = aTour.distance;
//        }
//        free(aTour.route);
//    }
//    NSLog(@"%@: Distance = %d", sampleName, shortestTour.distance);
//    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= shortestTour.distance, @"Shorter than the optimal solution.");
//}
//
///// Check if the shortest path length is longer than the optimal path.
//- (void)testNN2opt
//{
//    NSString *sampleName = @"ch130";
//    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
//    
//    // Compute the shortest path.
//    Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
//    for (int i = 0; i < tsp.dimension; i++) {
//        Tour aTour = [tsp tourByNNFrom:i + 1 use2opt:YES];
//        [tsp improveTourBy2opt:&aTour];
//        if (aTour.distance < shortestTour.distance) {
//            memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
//            shortestTour.distance = aTour.distance;
//        }
//        free(aTour.route);
//    }
//    NSLog(@"%@: Distance = %d", sampleName, shortestTour.distance);
//    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= shortestTour.distance, @"Shorter than the optimal solution.");
//}

/// Check if the shortest path length is longer than the optimal path.
//- (void)testAS
//{
//    NSString *sampleName = @"ch130";
//    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
//
//    NSString *log;
//    // Compute the shortest path.
//    Tour tour = [tsp tourByASWithNumberOfAnt:tsp.dimension
//                          pheromoneInfluence:1
//                         transitionInfluence:2
//                        pheromoneEvaporation:0.5
//                                        seed:469049721
//                              noImproveLimit:1000
//                                maxIteration:1000
//                           candidateListSize:0
//                                     use2opt:NO
//                                CSVLogString:&log];
//    int loopCt = [[[[[USKTrimmer trimmedArrayWithArray:[log componentsSeparatedByString:@"\n"]] lastObject] componentsSeparatedByString:@","] firstObject] intValue];
//    NSLog(@"%@: Distance = %d, Loop = %d", sampleName, tour.distance, loopIndex + 1);
//    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= tour.distance, @"Shorter than the optimal solution.");
//}

///// Check if the shortest path length is longer than the optimal path.
//- (void)testASWithCandidateList
//{
//    NSString *sampleName = @"ch130";
//    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
//    
//    NSString *log;
//    // Compute the shortest path.
//    Tour tour = [tsp tourByASWithNumberOfAnt:tsp.dimension
//                          pheromoneInfluence:1
//                         transitionInfluence:2
//                        pheromoneEvaporation:0.5
//                                        seed:469049721
//                              noImproveLimit:1000
//                                maxIteration:1000
//                           candidateListSize:20
//                                     use2opt:NO
//                                CSVLogString:&log];
//    int loopCt = [[[[[USKTrimmer trimmedArrayWithArray:[log componentsSeparatedByString:@"\n"]] lastObject] componentsSeparatedByString:@","] firstObject] intValue];
//    NSLog(@"%@: Distance = %d, Loop = %d", sampleName, tour.distance, loopIndex + 1);
//    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= tour.distance, @"Shorter than the optimal solution.");
//}
//
///// Check if the shortest path length is longer than the optimal path.
//- (void)testMMAS
//{
//    NSString *sampleName = @"ch130";
//    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
// 
//    NSString *log;
//    // Compute the shortest path.
//    Tour tour = [tsp tourByMMASWithNumberOfAnt:tsp.dimension
//                            pheromoneInfluence:1
//                           transitionInfluence:2
//                          pheromoneEvaporation:0.2
//                               probabilityBest:0.05
//                                takeGlogalBest:NO
//                                          seed:469049721
//                                noImproveLimit:1000
//                                  maxIteration:1000
//                             candidateListSize:0
//                                       use2opt:NO
//                                     smoothing:0.0
//                                  CSVLogString:&log];
//    int loopCt = [[[[[USKTrimmer trimmedArrayWithArray:[log componentsSeparatedByString:@"\n"]] lastObject] componentsSeparatedByString:@","] firstObject] intValue];
//    NSLog(@"%@: Distance = %d, Loop = %d", sampleName, tour.distance, loopIndex + 1);
//    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= tour.distance, @"Shorter than the optimal solution.");
//}

/// Check if the shortest path length is longer than the optimal path.
//- (void)testMMASWithCandidateList
//{
//    NSString *sampleName = @"ch130";
//    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
//    
//    NSString *log;
//    // Compute the shortest path.
//    Tour tour = [tsp tourByMMASWithNumberOfAnt:tsp.dimension
//                            pheromoneInfluence:1
//                           transitionInfluence:2
//                          pheromoneEvaporation:0.2
//                               probabilityBest:0.05
//                                takeGlogalBest:NO
//                                          seed:469049721
//                                noImproveLimit:1000
//                                  maxIteration:1000
//                             candidateListSize:20
//                                       use2opt:NO
//                                     smoothing:0.0
//                                  CSVLogString:&log];
//    int loopCt = [[[[[USKTrimmer trimmedArrayWithArray:[log componentsSeparatedByString:@"\n"]] lastObject] componentsSeparatedByString:@","] firstObject] intValue];
//    NSLog(@"%@: Distance = %d, Loop = %d", sampleName, tour.distance, loopIndex + 1);
//    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= tour.distance, @"Shorter than the optimal solution.");
//}

/// Check if the shortest path length is longer than the optimal path.
- (void)testMMAS2opt
{
    NSString *sampleName = @"ch130";
    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
    
    NSString *log;
    // Compute the shortest path.
    Tour tour = [tsp tourByMMASWithNumberOfAnt:25
                            pheromoneInfluence:1
                           transitionInfluence:4
                          pheromoneEvaporation:0.2
                               probabilityBest:0.05
                                takeGlogalBest:NO
                                          seed:469049721
                                noImproveLimit:1000
                                  maxIteration:1000
                             candidateListSize:tsp.dimension
                                       use2opt:YES
                                     smoothing:0.0
                                  CSVLogString:&log];
    int loopIndex = [[[[[USKTrimmer trimmedArrayWithArray:[log componentsSeparatedByString:@"\n"]] lastObject] componentsSeparatedByString:@","] firstObject] intValue];
    NSLog(@"%@: Distance = %d, Loop = %d", sampleName, tour.distance, loopIndex + 1);
    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= tour.distance, @"Shorter than the optimal solution.");
}

/// Check if the shortest path length is longer than the optimal path.
- (void)testMMAS2optWithCandidateList
{
    NSString *sampleName = @"ch130";
    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
    
    NSString *log;
    // Compute the shortest path.
    Tour tour = [tsp tourByMMASWithNumberOfAnt:25
                            pheromoneInfluence:1
                           transitionInfluence:4
                          pheromoneEvaporation:0.2
                               probabilityBest:0.05
                                takeGlogalBest:NO
                                          seed:469049721
                                noImproveLimit:1000
                                  maxIteration:1000
                             candidateListSize:20
                                       use2opt:YES
                                     smoothing:0.0
                                  CSVLogString:&log];
    int loopIndex = [[[[[USKTrimmer trimmedArrayWithArray:[log componentsSeparatedByString:@"\n"]] lastObject] componentsSeparatedByString:@","] firstObject] intValue];
    NSLog(@"%@: Distance = %d, Loop = %d", sampleName, tour.distance, loopIndex + 1);
    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance <= tour.distance, @"Shorter than the optimal solution.");
}


@end
