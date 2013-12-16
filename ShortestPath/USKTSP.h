//
//  USKTSP.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct TSPNode {
	int nodeIndex;
	CGPoint coordination;
} TSPNode;

typedef struct NeighborInfo {
	int nodeIndex;
	double distance;
} NeighborInfo;

typedef struct PathInfo {
	double length;
	int *path;
} PathInfo;

@interface USKTSP : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *comment;
@property (readonly) NSString *type;
@property (readonly) NSUInteger dimension;
@property (readonly) NSString *edgeWeightType;
@property (readonly) TSPNode *nodes;
/// n by n lengths of arcs matrix (size of array is (numberOfNodes * numberOfNodes))
@property (readonly) double *adjacencyMatrix; // UNUSED (use neighborMatrix instead)
/// n by n-1 sorted neighbor maxtrix (vertical vector of sorted neighbors of each node)
@property (readonly) NeighborInfo *neighborMatrix;

/**
 initialize with specified TSP data file.
 @param path input file path
 */
- (id)initWithFilePath:(NSString *)path;

- (PathInfo)shortestPathByNearestNeighborFromStartNodeIndex:(int)startNodeIndex;

- (PathInfo)improvePathBy2opt;


// AS ro must fix to 0.5
// 1 sample

@end

/*
 PathInfo will leak easily! 
 */