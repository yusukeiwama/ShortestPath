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
	int		index;
	CGPoint coordination;
} TSPNode;

typedef struct NeighborInfo {
	int		index;
	double	distance;
} NeighborInfo;


typedef struct PathInfo {
	double	length;
	int		*path;
} PathInfo;

@interface USKTSP : NSObject

@property (readonly) NSString	*filePath;

@property (readonly) NSString	*name;
@property (readonly) NSString	*comment;
@property (readonly) NSString	*type;
@property (readonly) NSInteger	dimension;
@property (readonly) NSString	*edgeWeightType;
@property (readonly) TSPNode	*nodes;

/// n by n lengths of arcs matrix (size of array is (numberOfNodes * numberOfNodes))
@property (readonly) double *adjacencyMatrix; // UNUSED (use neighborMatrix instead)

/// n by n-1 sorted neighbor maxtrix (vertical vector of sorted neighbors of each node)
@property (readonly) NeighborInfo *neighborMatrix;

+ (id)TSPWithFile:(NSString *)path;
- (id)initWithFile:(NSString *)path;

- (PathInfo)shortestPathByNearestNeighborFromStartNodeIndex:(int)startNodeIndex;

- (PathInfo)improvePathBy2opt:(PathInfo)exisingPath;


// AS ro must fix to 0.5
// 1 sample

@end

/*
 PathInfo will leak easily! 
 */