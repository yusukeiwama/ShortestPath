//
//  USKTSP.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

/*
 What's TSP?:
 Given a set of n nodes and distances for each pair of nodes,
 find a roundtrip of minimal total length visiting each node exactly once.
 The distance from node i to node j is the same as from node j to node i.
 */

#import <Foundation/Foundation.h>

typedef struct Node {
	int		number;
	CGPoint coord;
} Node;

typedef struct Neighbor {
	int		number;     // node number
	int 	distance;
} Neighbor;

typedef struct Tour {
	int 	length;		// total length
	int		*route;		// node numbers
} Tour;

@interface TSP : NSObject

@property (readonly) NSString	  *filePath;
@property (readonly) NSDictionary *information;
@property (readonly) int		  dimension;
@property (readonly) Node         *nodes;
/// n by n weighted adjacency matrix
@property (readonly) int		  *adjacencyMatrix;
/// n by n-1 sorted neighbor maxtrix (vertical vector of sorted neighbors of each node)
@property (readonly) Neighbor     *neighborMatrix;

+ (id)TSPWithFile:(NSString *)path;
- (id)initWithFile:(NSString *)path;

+ (id)randomTSPWithDimension:(NSInteger)dimension;

/**
 *  Compute the shortest path by Nearest Neighbor method. It may not be the optimal path.
 *
 *  @param Start Index of the node to start from.
 *
 *  @return Path information for the shortest path.
 */
- (Tour)tourByNNFrom:(int)start;

- (void)improveTourBy2opt:(Tour *)tour;

/**
 *  Return the optimal solution by reading files.
 *
 *  @param name problem name of the TSP.
 *
 *  @return optimal path. If there is no path information, returns NULL.
 */
+ (Tour)optimalSolutionWithName:(NSString *)name;

+ (void)printPath:(Tour)pathInfo ofTSP:(TSP *)tsp;


// AS ro must fix to 0.5
// 1 sample

@end

/*
 PathInfo will leak easily! 
 */