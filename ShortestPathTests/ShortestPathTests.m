//
//  ShortestPathTests.m
//  ShortestPathTests
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSP.h"

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


/// Check if the shortest path length is longer than the optimal path.
- (void)testNN
{
    NSString *sampleName = @"eil51";
    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
    
    // Compute the shortest path.
    Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
    for (int i = 0; i < tsp.dimension; i++) {
        Tour aTour = [tsp tourByNNFrom:i + 1];
        if (aTour.distance < shortestTour.distance) {
            memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
            shortestTour.distance = aTour.distance;
        }
        free(aTour.route);
    }
    
    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance < shortestTour.distance, @"Shorter than the optimal solution.");
}

/// Check if the shortest path length is longer than the optimal path.
- (void)testNN2opt
{
    NSString *sampleName = @"eil51";
    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
    
    // Compute the shortest path.
    Tour shortestTour = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
    for (int i = 0; i < tsp.dimension; i++) {
        Tour aTour = [tsp tourByNNFrom:i + 1];
        [tsp improveTourBy2opt:&aTour];
        if (aTour.distance < shortestTour.distance) {
            memcpy(shortestTour.route, aTour.route, tsp.dimension * sizeof(int));
            shortestTour.distance = aTour.distance;
        }
        free(aTour.route);
    }
    
    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance < shortestTour.distance, @"Shorter than the optimal solution.");
}

/// Check if the shortest path length is longer than the optimal path.
- (void)testAS
{
    NSString *sampleName = @"eil51";
    TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
    
    // Compute the shortest path.
    Tour tour = [tsp tourByASWithNumberOfAnt:tsp.dimension
                          pheromoneInfluence:1
                         transitionInfluence:2
                        pheromoneEvaporation:0.5
                                        seed:101
                                CSVLogString:NULL];
    
    // Check if the shortest path length is longer than the optimal path.
    XCTAssertTrue([TSP optimalSolutionWithName:sampleName].distance < tour.distance, @"Shorter than the optimal solution.");
}

@end
