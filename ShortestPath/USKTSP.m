//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

/* 
 A SAMPLE OF SYMMETRIC TRAVELING SALESMAN PROBLEM (TSP) FILE
 
 NAME: ch130
 TYPE: TSP
 COMMENT: 130 city problem (Churritz)
 DIMENSION: 130
 EDGE_WEIGHT_TYPE: EUC_2D
 NODE_COORD_SECTION
 1 334.5909245845 161.7809319139
 2 397.6446634067 262.8165330708
 ...
 129 178.1107815614 104.6905805938
 130 403.2874386776 205.8971749407
 EOF
 */

/* 
 A SAMPLE OF OPTIMAL SOLUTION FILE

 NAME : ch130.opt.tour
 COMMENT : Length 6110
 TYPE : TOUR
 DIMENSION : 130
 TOUR_SECTION
 1
 41
 ...
 71
 -1
 */

#import "USKTSP.h"

int compareDistances(const NeighborInfo *a, const NeighborInfo *b)
{
	return ((NeighborInfo)(*a)).distance - ((NeighborInfo)(*b)).distance;
}

//PathInfo swapNodes(PathInfo *path, int i, int j)
//{
//	
//}

@interface USKTSP ()
@end


@implementation USKTSP

+ (id)TSPWithFile:(NSString *)path
{
	return [[USKTSP alloc] initWithFile:path];
}

- (id)initWithFile:(NSString *)path
{
	self = [super init];
	if (self) {
		[self readTSPDataFromFile:path];

		[self computeAdjacencyMatrix];
		[self computeNeighborMatrix];
		
		[self printInformation];
		[self printAdjecencyMatrix];
		[self printNeighborMatrix];

	}
	return self;
}

- (void)readTSPDataFromFile:(NSString *)path
{
	_filePath = path;
	NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [rawString componentsSeparatedByString:@"\n"];

	// Read basic information.
	int i = 0;
	while ([lines[i] rangeOfString:@"NODE_COORD_SECTION"].location == NSNotFound) {
		NSArray *components = [lines[i] componentsSeparatedByString:@":"];
		NSString *key = [self trimmedStringFromString:components[0]];
		NSString *val = [self trimmedStringFromString:components[1]];
		[self storeValueString:val forKey:key];
		i++;
	}
	
	// Read node coordinations.
	if ([_type isEqualToString:@"TSP"]) {
		_nodes = calloc(lines.count - 8, sizeof(TSPNode));
		
		int i = 0;
		int offset = 6;
		while ([lines[i + offset] rangeOfString:@"EOF"].location == NSNotFound) {
			NSArray *nodeInfo = [lines[i + offset] componentsSeparatedByString:@" "];
			_nodes[i].index			 = [nodeInfo[0] intValue];
			_nodes[i].coordination.x = [nodeInfo[1] doubleValue];
			_nodes[i].coordination.y = [nodeInfo[2] doubleValue];
			i++;
		}
	}
}

- (NSString *)trimmedStringFromString:(NSString *)string
{
	// Trim whitespace. (i.e. @" ch130" => @"ch130")
	return [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
}

- (void)storeValueString:(NSString *)valueString forKey:(NSString *)key
{
	if ([key isEqualToString:@"NAME"])					_name			= valueString;
	else if ([key isEqualToString:@"COMMENT"])			_comment		= valueString;
	else if ([key isEqualToString:@"TYPE"])				_type			= valueString;
	else if ([key isEqualToString:@"DIMENSION"])		_dimension		= [valueString integerValue];
	else if ([key isEqualToString:@"EDGE_WEIGHT_TYPE"])	_edgeWeightType	= valueString;
}

- (void)computeAdjacencyMatrix
{
	if (self.adjacencyMatrix == NULL) {
		_adjacencyMatrix = calloc(_dimension * _dimension, sizeof(double));
	}
	
	if ([_edgeWeightType isEqualToString:@"EUC_2D"]) {
		for (int i = 0; i < _dimension; i++) {
			for (int j = 0; j < _dimension; j++) {
				double x1 = _nodes[i].coordination.x;
				double x2 = _nodes[j].coordination.x;
				double y1 = _nodes[i].coordination.y;
				double y2 = _nodes[i].coordination.y;
				_adjacencyMatrix[_dimension * i + j] = (int)(sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)) + 0.5);
			}
		}
	} else {
		NSLog(@"Unknown edge_weight_type");
	}
}

- (void)computeNeighborMatrix
{
	if (self.neighborMatrix == NULL) {
		_neighborMatrix = calloc(_dimension * _dimension, sizeof(NeighborInfo));
	}
	
	if ([_edgeWeightType isEqualToString:@"EUC_2D"]) {
		for (int i = 0; i < _dimension; i++) {
			for (int j = 0; j < _dimension; j++) {
				double x1 = _nodes[i].coordination.x;
				double x2 = _nodes[j].coordination.x;
				double y1 = _nodes[i].coordination.y;
				double y2 = _nodes[j].coordination.y;
				_adjacencyMatrix[_dimension * i + j] = (int)(sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)) + 0.5);
				_neighborMatrix[_dimension * i + j].index	 = _nodes[j].index;
				_neighborMatrix[_dimension * i + j].distance = _adjacencyMatrix[_dimension * i + j];
			}
			
			// ignore i == j element because the element is not a neighbor but itself.
			_neighborMatrix[_dimension * i + i] = _neighborMatrix[_dimension * i + _dimension - 1];

			// Sort neighbors of node-i by distance.
			qsort(&(_neighborMatrix[_dimension * i + 0]), _dimension - 1, sizeof(NeighborInfo), (int(*)(const void *, const void *))compareDistances);
		}
	} else {
		NSLog(@"Unknown edge_weight_type");
	}
}

- (PathInfo)shortestPathByNearestNeighborFromStartNodeIndex:(int)start
{
	PathInfo shortestPath;
	int from, to;
	NSMutableArray *visited = [NSMutableArray array];
	double totalDistance = 0.0;

	from = start;
	[visited addObject:[NSNumber numberWithInt:from]];

	while (visited.count < self.dimension) {
		for (int j = 0; j < self.dimension - 1; j++) {
			// Look up the nearest node.
			to = self.neighborMatrix[self.dimension * (from - 1) + j].index;
			
			// Check if the node has already been visited.
			if ([visited containsObject:[NSNumber numberWithInt:to]]) { // visited
				continue;
			} else { // not visited yet
				[visited addObject:[NSNumber numberWithInt:to]];
				totalDistance += self.neighborMatrix[self.dimension * (from - 1) + j].distance;
				from = to;
				break;
			}
		}
	}
	totalDistance += self.adjacencyMatrix[self.dimension * (from - 1) + start]; // Go back to the start node
	
	shortestPath.path	= [self intArrayFromArray:visited];
	shortestPath.length	= totalDistance;
	[self printPath:shortestPath];
	return shortestPath;
}

- (int *)intArrayFromArray:(NSArray *)array
{
	int *arr = calloc(array.count, sizeof(int));
	for (int i = 0; i < array.count; i++) {
		arr[i] = [((NSNumber *)array[i]) intValue];
	}
	return arr;
}

- (PathInfo)improvePathBy2opt:(PathInfo)exisingPath
{
	PathInfo improvedPath, newPath;
	BOOL improved = NO;
	
	improvedPath = exisingPath;
	do {
		for (int i = 0; i < self.dimension - 2; i++) {
			for (int j = i + 1; j < self.dimension - 1; j++) {
//				newPath = swapNodes(&improvedPath, i, j);
				newPath.length = improvedPath.length
				- self.adjacencyMatrix[self.dimension * i		+ (i + 1)]
				- self.adjacencyMatrix[self.dimension * j		+ (j + 1)]
				+ self.adjacencyMatrix[self.dimension * i		+ j]
				+ self.adjacencyMatrix[self.dimension * (i + 1)	+ (j + 1)];
				if (newPath.length < improvedPath.length) {
					improvedPath = newPath;
					improved = YES;
				}
			}
		}
	} while (improved);
	
	return improvedPath;
}

- (void)printInformation
{
	printf("========== FILE INFORMATION ==========\n");
	printf("NAME:             %s\n", [self.name cStringUsingEncoding:NSUTF8StringEncoding]);
	printf("COMMENT:          %s\n", [self.comment cStringUsingEncoding:NSUTF8StringEncoding]);
	printf("TYPE:             %s\n", [self.type cStringUsingEncoding:NSUTF8StringEncoding]);
	printf("DIMENSION:        %d\n", self.dimension);
	printf("EDGE_WEIGHT_TYPE: %s\n", [self.edgeWeightType cStringUsingEncoding:NSUTF8StringEncoding]);
	printf("NODE_COORD_SECTION:\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%3d %21.10f %21.10f\n", self.nodes[i].index, self.nodes[i].coordination.x, self.nodes[i].coordination.y);
	}
	printf("\n");
}

- (void)printAdjecencyMatrix
{
	printf("========== WEIGHTED ADJECENCY MATRIX ==========\n");
	printf("      ");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d ", self.nodes[i].index);
	}
	printf("\n");
	
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", self.nodes[i].index);
		for (int j = 0; j < self.dimension; j++) {
			printf("%4.1f ", self.adjacencyMatrix[self.dimension * i + j]);
		}
		printf("\n");
	}
	printf("\n");
}

- (void)printNeighborMatrix
{
	printf("========== NEIGHBOR INDEX MATRIX ==========\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", self.nodes[i].index);
		for (int j = 0; j < self.dimension - 1; j++) {
			printf("%2d ", self.neighborMatrix[self.dimension * i + j].index);
		}
		printf("\n");
	}
	printf("\n");
	
	printf("========== NEIGHBOR DISTANCE MATRIX ==========\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", self.nodes[i].index);
		for (int j = 0; j < self.dimension - 1; j++) {
			printf("%4.1f ", self.neighborMatrix[self.dimension * i + j].distance);
		}
		printf("\n");
	}
	printf("\n");
}



- (void)printPath:(PathInfo)pathInfo
{
	printf("Shortest path is ...\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%2d ", pathInfo.path[i]);
	}
	printf("\nLength = %.1f", pathInfo.length);
}

- (void)dealloc
{
	free(_nodes);
	free(_adjacencyMatrix);
}

@end