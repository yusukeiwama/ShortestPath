//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKTSP.h"

int compareDistances(const NeighborInfo *a, const NeighborInfo *b)
{
	return ((NeighborInfo)(*a)).distance - ((NeighborInfo)(*b)).distance;
}

@implementation USKTSP

@synthesize name;
@synthesize comment;
@synthesize type;
@synthesize dimension;
@synthesize edgeWeightType;
@synthesize nodes;
@synthesize adjacencyMatrix;
@synthesize neighborMatrix;

- (id)initWithFilePath:(NSString *)path
{
	if (self = [super init]) {
		// Load TSP data file into contentString.
		NSString *contentString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
		
		// Get information from contentString.
		NSArray *information = [contentString componentsSeparatedByString:@"\n"];
//		NSLog(@"%@", information);
		name = [[information[0] componentsSeparatedByString:@":"][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
		comment = [[information[1] componentsSeparatedByString:@":"][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
		type = [[information[2] componentsSeparatedByString:@":"][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
		dimension = [[[information[3] componentsSeparatedByString:@":"][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] integerValue];
		edgeWeightType = [[information[4] componentsSeparatedByString:@":"][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];;
		
		// Prepare nodes.
		if ([type isEqualToString:@"TSP"]) {
			nodes = calloc(information.count - 8, sizeof(TSPNode));
			adjacencyMatrix = calloc(dimension * dimension, sizeof(double));
			neighborMatrix = calloc(dimension * dimension, sizeof(NeighborInfo));
			for (NSUInteger i = 0; i < information.count - 8; i++) {
				NSArray *nodeInfo = [information[i + 6] componentsSeparatedByString:@" "]; // 6 is offset in TSPData file
				nodes[i].nodeIndex = [nodeInfo[0] intValue] - 1; // convert to 0-origin
				nodes[i].coordination.x = [nodeInfo[1] doubleValue];
				nodes[i].coordination.y = [nodeInfo[2] doubleValue];
//				printf("%d %f %f\n", nodes[i].nodeID, nodes[i].coordination.x, nodes[i].coordination.y);
			}
//			[self prepareAdjacencyMatrix];
			[self prepareNeighborMatrix];
		}
		
		
	}
	
	return self;
}

- (void)prepareAdjacencyMatrix {
	if ([edgeWeightType isEqualToString:@"EUC_2D"]) {
		// Prepare weighted adjacency matrix
		for (int i = 0; i < dimension; i++) {
			for (int j = 0; j < dimension; j++) {
				double x1 = nodes[i].coordination.x;
				double x2 = nodes[j].coordination.x;
				double y1 = nodes[i].coordination.y;
				double y2 = nodes[i].coordination.y;
				adjacencyMatrix[dimension * i + j] = (int)(sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)) + 0.5);
//				printf("%03.1f\t", adjacencyMatrix[dimension * i + j]);
			}
//			printf("\n");
		}
	} else {
		NSLog(@"Unknown edge_weight_type");
	}
}

- (void)prepareNeighborMatrix
{
	if ([edgeWeightType isEqualToString:@"EUC_2D"]) {
		
		// Prepare weighted adjacency matrix
		for (int i = 0; i < dimension; i++) {
			for (int j = 0; j < dimension; j++) {
				double x1 = nodes[i].coordination.x;
				double x2 = nodes[j].coordination.x;
				double y1 = nodes[i].coordination.y;
				double y2 = nodes[j].coordination.y;
				adjacencyMatrix[dimension * i + j] = (int)(sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)) + 0.5);
				neighborMatrix[dimension * i + j].nodeIndex = nodes[j].nodeIndex;
				neighborMatrix[dimension * i + j].distance = adjacencyMatrix[dimension * i + j];
			}
			
			// ignore i == j element because the element is not a neighbor but itself.
			neighborMatrix[dimension * i + i] = neighborMatrix[dimension * i + dimension - 1];

			// Sort neighbors of node-i by distance.
			qsort(&(neighborMatrix[dimension * i + 0]), dimension - 1, sizeof(NeighborInfo), (int(*)(const void *, const void *))compareDistances);
		}
//		[self printNeighborMatrix];
		
	} else {
		NSLog(@"Unknown edge_weight_type");
	}
}

- (PathInfo)shortestPathByNearestNeighborFromStartNodeIndex:(int)startNodeIndex
{ // ノード番号は1始まりなので注意！！！！！
	PathInfo shortestPath;
	int fromNodeIndex, toNodeIndex;
	int *visitedNodeIndices = calloc(dimension, sizeof(int));
	double totalDistance = 0.0;

	// Prepare visited nodes array.
	for (int i = 0; i < dimension; i++) {
		visitedNodeIndices[i] = -1;	// -1 means no node is set.
	}
	fromNodeIndex = startNodeIndex;
	visitedNodeIndices[0] = startNodeIndex;
	int numberOfVisitedNodes = 1;

	// Find the shortest path by the nearest neighbor method.
	while (numberOfVisitedNodes < dimension) {
		for (int j = 0; j < dimension - 1; j++) {
			toNodeIndex = neighborMatrix[dimension * fromNodeIndex + j].nodeIndex;
			for (int i = 0; i < dimension; i++) {
				if (visitedNodeIndices[i] == -1) { // no more visited node
					break;
				}
				if (toNodeIndex == visitedNodeIndices[i]) { // toNodeID is already taken
					toNodeIndex = -1; // make toNodeID invalid(-1).
					break;
				}
			}
			if (toNodeIndex != -1) { // if toNodeID is valid
				visitedNodeIndices[numberOfVisitedNodes] = toNodeIndex;
				numberOfVisitedNodes++;
				totalDistance += neighborMatrix[dimension * fromNodeIndex + j].distance;
				fromNodeIndex = toNodeIndex;
				break;
			}
		}
	}
	totalDistance += adjacencyMatrix[dimension * fromNodeIndex + startNodeIndex]; // Go back to the start node
	
	shortestPath.path = visitedNodeIndices;
	shortestPath.length = totalDistance;
//	[self printPath:shortestPath];
	return shortestPath;
}

- (PathInfo)improvePathBy2opt
{
	PathInfo improvedPath;
	return improvedPath;
}

- (void)printNeighborMatrix
{
	for (int i = 0; i < dimension; i++) {
		for (int j = 0; j < dimension - 1; j++) {
			printf("%2d ", neighborMatrix[dimension * i + j].nodeIndex);
		}
		printf("\n");
	}
}

- (void)printAdjecencyMatrix
{
	for (int i = 0; i < dimension; i++) {
		for (int j = 0; j < dimension - 1; j++) {
			printf("%.1f ", neighborMatrix[dimension * i + j].distance);
		}
		printf("\n");
	}
}

- (void)printPath:(PathInfo)pathInfo
{
		printf("Shortest path is ...\n");
	for (int i = 0; i < dimension; i++) {
		printf("%2d ", pathInfo.path[i]);
	}
	printf("\nLength = %.1f", pathInfo.length);
}

- (void)dealloc
{
	free(nodes);
	free(adjacencyMatrix);
}

@end