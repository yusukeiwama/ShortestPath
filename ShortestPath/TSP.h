//
//  USKTSP.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_DIMENSION 3000

/*
 Optimal solution can be different according to which type used.
 i.e. tsp225.tsp (float:3919, double:3916)
*/
typedef struct _Coordinate {
    double x;
    double y;
} Coordinate;

typedef struct _Node {
	int		number;
	Coordinate   coord;
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
+ (id)randomTSPWithDimension:(NSInteger)dimension seed:(unsigned)seed;

/**
 Return the optimal solution of the sample file.
 @param  name problem name of the TSP.
 @return optimal path. If there is no path information, returns NULL.
 */
+ (Tour)optimalSolutionWithName:(NSString *)name;

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
 Compute the shortest path by Ant System. The global best solution deposits pheromone on every iteration along with all the other ants. It may not be the optimal path. The recommended values are as follows. numberOfAnt = tsp.dimension, alpha = 1, beta = 2 ~ 5, rho = 0.5.
 @param numberOfAnt The number of ants.
 @param alpha       A parameter to control the influence of pheromone.
 @param beta        A parameter to control the influence of the desirability of state transition. (a priori knowledge, typically 1/dxy, where dxy is the distance between node x and node y)
 @param rho         The pheromone evaporatin coefficient. The rate of pheromone evaporation.
 @param seed        Seed to generate random number.
 @param limit       The number of iteration without improvement to break.
 @param size        The number of closest nodes to be candidates. If less than or equal to 0, a candidate list won't be used.
 @param log         Iteration best tour distances in CSV format.
 @return The result tour.
 */
- (Tour)tourByASWithNumberOfAnt:(int)numberOfAnt
             pheromoneInfluence:(int)alpha
            transitionInfluence:(int)beta
           pheromoneEvaporation:(double)rho
                           seed:(unsigned)seed
                 noImproveLimit:(int)limit
              candidateListSize:(int)size
                   CSVLogString:(NSString *__autoreleasing *)log;

/**
 Compute the shortest path by Max-Min Ant System. Only global best or iteration best tour deposites pheromone. It may not be the optimal path. The recommended values are as follows. numberOfAnt = tsp.dimension, alpha = 1, beta = 2 ~ 5, rho = 0.02, pBest = 0.05.
 @param numberOfAnt The number of ants.
 @param alpha       A parameter to control the influence of pheromone.
 @param beta        A parameter to control the influence of the desirability of state transition. (a priori knowledge, typically 1/dxy, where dxy is the distance between node x and node y)
 @param rho         The pheromone evaporatin coefficient. The rate of pheromone evaporation.
 @param pBest       The parameter to compute minimum pheromone.
 @param seed        Seed to generate random number.
 @param limit       The number of iteration without improvement to break.
 @param size        The number of closest nodes to be candidates. If less than or equal to 0, a candidate list won't be used.
 @param log         Iteration best tour distances in CSV format.
 @return The result tour.
 */
- (Tour)tourByMMASWithNumberOfAnt:(int)numberOfAnt
               pheromoneInfluence:(int)alpha
              transitionInfluence:(int)beta
             pheromoneEvaporation:(double)rho
                  probabilityBest:(double)pBest
                             seed:(unsigned)seed
                   noImproveLimit:(int)limit
                candidateListSize:(int)size
                     CSVLogString:(NSString *__autoreleasing *)log;


/**
 Compute the shortest path by Max-Min Ant System with 2-opt. Only global best or iteration best tour deposites pheromone. It may not be the optimal path.
 @param numberOfAnt The number of ants.
 @param alpha       A parameter to control the influence of pheromone.
 @param beta        A parameter to control the influence of the desirability of state transition. (a priori knowledge, typically 1/dxy, where dxy is the distance between node x and node y)
 @param rho         The pheromone evaporatin coefficient. The rate of pheromone evaporation.
 @param pBest       The parameter to compute minimum pheromone.
 @param seed        Seed to generate random number.
 @param limit       The number of iteration without improvement to break.
 @param size        The number of closest nodes to be candidates. If less than or equal to 0, a candidate list won't be used.
 @param log         Iteration best tour distances in CSV format.
 @return The result tour.
 */
- (Tour)tourByMMAS2optWithNumberOfAnt:(int)numberOfAnt
                   pheromoneInfluence:(int)alpha
                  transitionInfluence:(int)beta
                 pheromoneEvaporation:(double)rho
                      probabilityBest:(double)pBest
                                 seed:(unsigned)seed
                       noImproveLimit:(int)limit
                    candidateListSize:(int)size
                         CSVLogString:(NSString *__autoreleasing *)log;

@end
