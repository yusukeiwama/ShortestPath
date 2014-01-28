//
//  USKTSP.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_DIMENSION 3000

typedef struct _Node {
	int		number;
	CGPoint coord;
} Node;

typedef struct _Tour {
	int distance;
	int	*route;
} Tour;

@interface TSP : NSObject

@property (readonly) NSDictionary *information;
@property (readonly) int		  dimension;
@property (readonly) Node         *nodes;

#pragma mark - Constructors

+ (id)TSPWithFile:(NSString *)path;
- (id)initWithFile:(NSString *)path;
+ (id)randomTSPWithDimension:(NSInteger)dimension;

#pragma mark - TSP Solver Algorithms

/*
 What's TSP?:
 Given a set of n nodes and distances for each pair of nodes,
 find a roundtrip of minimal total length visiting each node exactly once.
 The distance from node i to node j is the same as from node j to node i.
 */

/**
 Compute the shortest path by Nearest Neighbor method. It may not be the optimal path.
 @param start Start node number.
 @return The result tour.
 */
- (Tour)tourByNNFrom:(int)start;

/**
 Improve the tour by 2-opt method. It removes crossing of the route by swapping mechanism.
 @param tour The tour to be improved.
 */
- (void)improveTourBy2opt:(Tour *)tour;

/**
 Compute the shortest path by Ant System. The global best solution deposits pheromone on every iteration along with all the other ants. It may not be the optimal path. The recommended values are as follows. numberOfAnt = tsp.dimension, alpha = 1, beta = 2 ~ 5, ro = 0.5.
 @param numberOfAnt The number of ants.
 @param alpha       A parameter to control the influence of pheromone.
 @param beta        A parameter to control the influence of the desirability of state transition. (a priori knowledge, typically 1/dxy, where dxy is the distance between node x and node y)
 @param ro          The pheromone evaporatin coefficient. The rate of pheromone evaporation.
 @return The result tour.
 */
- (Tour)tourByASWithNumberOfAnt:(int)numberOfAnt
             pheromoneInfluence:(int)alpha
            transitionInfluence:(int)beta
           pheromoneEvaporation:(double)ro;

/**
 Return the optimal solution by reading files.
 @param  name problem name of the TSP.
 @return optimal path. If there is no path information, returns NULL.
 */
+ (Tour)optimalSolutionWithName:(NSString *)name;

@end
