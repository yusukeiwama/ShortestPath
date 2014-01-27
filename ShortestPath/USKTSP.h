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

typedef struct TSPNode {
	int		number;
	CGPoint coord;
} TSPNode;

typedef struct NeighborInfo {
	int		nodeNumber;
	int 	distance;
} NeighborInfo;


typedef struct PathInfo {
	int 	length;
	int		*path;
} PathInfo;

@interface USKTSP : NSObject

@property (readonly) NSString	  *filePath;
@property (readonly) NSDictionary *information;
@property (readonly) int		  dimension;
@property (readonly) TSPNode      *nodes;
@property (readonly) int		  *adjacencyMatrix;

/// n by n-1 sorted neighbor maxtrix (vertical vector of sorted neighbors of each node)
@property (readonly) NeighborInfo *neighborMatrix;

+ (id)TSPWithFile:(NSString *)path;
- (id)initWithFile:(NSString *)path;

+ (id)randomTSPWithDimension:(NSInteger)d;

- (void)freePath:(PathInfo)path;

/**
 *  Compute the shortest path by Nearest Neighbor method. It may not be the optimal path.
 *
 *  @param Start Index of the node to start from.
 *
 *  @return Path information for the shortest path.
 */
- (PathInfo)shortestPathByNNFrom:(int)start;

- (void)improvePathBy2opt:(PathInfo *)path;

- (void)printPath:(PathInfo)pathInfo;


// AS ro must fix to 0.5
// 1 sample

@end

/*
 PathInfo will leak easily! 
 */