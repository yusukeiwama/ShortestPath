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

- (void)testNN
{
	TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:@"TSPData/eil51" ofType:@"tsp"]];
	Tour shortestPath = [tsp tourByNNFrom:1];
	
	int expectedPath[51] = {1, 32, 11, 38, 5, 49, 9, 50, 16, 2, 29, 21, 34, 30, 10, 39, 33, 45, 15, 44, 37, 17, 4, 18, 47, 12, 46, 51, 27, 48, 8, 26, 31, 28, 3, 20, 35, 36, 22, 6, 14, 25, 13, 41, 19, 42, 40, 24, 23, 7, 43};
	
	for (int i = 0; i < tsp.dimension; i++) {
		XCTAssertEqual(shortestPath.route[i], expectedPath[i], @"Wrong path.");
	}
}

- (void)testNN2opt
{
    NSArray *sampleFileNames = @[@"eil51", @"pr76", @"rat99", @"kroA100", @"ch130", @"tsp225"];
    
    for (NSString *sampleName in sampleFileNames) {
        TSP *tsp = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
        
        // Compute average path length.
        Tour shortPath = {INT32_MAX, calloc(tsp.dimension, sizeof(int))};
        for (int i = 0; i < tsp.dimension; i++) {
            Tour aPath = [tsp tourByNNFrom:i + 1];
            [tsp improveTourBy2opt:&aPath];
            if (aPath.length < shortPath.length) {
                memcpy(shortPath.route, aPath.route, tsp.dimension * sizeof(int));
                shortPath.length = aPath.length;
            }
            free(aPath.route);
        }
        
        XCTAssertTrue([TSP optimalSolutionWithName:sampleName].length < shortPath.length, @"Shorter than the optimal solution.");
    }
}

@end
