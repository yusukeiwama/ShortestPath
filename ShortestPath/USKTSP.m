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

void swapNodes(int *path, int dimension, int i, int j)
{
	int  *newPath = calloc(dimension, sizeof(int));
	
	int l = 0;
	for (int k = 0; k <= i; k++) {
		newPath[l] = path[k];
		l++;
	}
	for (int k = j; k >= i + 1; k--) {
		newPath[l] = path[k];
		l++;
	}
	for (int k = j + 1; k < dimension; k++) {
		newPath[l] = path[k];
		l++;
	}
	
	memcpy(path, newPath, dimension * sizeof(int));
}

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
	// Split contents of file into lines.
	_filePath = path;
	NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [rawString componentsSeparatedByString:@"\n"];

	// Read basic information.
	int i = 0;
	while ([lines[i] rangeOfString:@"NODE_COORD_SECTION"].location == NSNotFound) {
		NSArray *components = [[self trimmedStringWithString:lines[i]] componentsSeparatedByString:@":"];
		NSString *key = [self trimmedStringWithString:components[0]];
		NSString *val = [self trimmedStringWithString:components[1]];
		[self storeValueString:val forKey:key];
		i++;
	}
	
	// Read node coordinations.
	if ([_type isEqualToString:@"TSP"]) {
		_nodes = calloc(lines.count - 8, sizeof(TSPNode));
		
		int i = 0;
		int offset = 6;
		while ([lines[i + offset] rangeOfString:@"EOF"].location == NSNotFound) {
			NSArray *nodeInfo = [[self trimmedStringWithString:lines[i + offset]] componentsSeparatedByString:@" "];
			nodeInfo = [self trimmedArrayWithArray:nodeInfo];
			_nodes[i].index			 = [nodeInfo[0] intValue];
			_nodes[i].coordination.x = [nodeInfo[1] doubleValue];
			_nodes[i].coordination.y = [nodeInfo[2] doubleValue];
			i++;
		}
	}
}

- (NSString *)trimmedStringWithString:(NSString *)string
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

- (NSArray *)trimmedArrayWithArray:(NSArray *)array
{
	NSMutableArray *mutableArray = [NSMutableArray array];
	for (int i = 0; i < array.count; i++) {
		NSString *string = array[i];
		if ([string isEqualToString:@""] == NO) {
			[mutableArray addObject:array[i]];
		}
	}
	return mutableArray;
}

- (void)computeAdjacencyMatrix
{
	if (self.adjacencyMatrix == NULL) {
		_adjacencyMatrix = calloc(_dimension * _dimension, sizeof(double));
		
		for (int i = 0; i < _dimension; i++) {
			for (int j = 0; j < _dimension; j++) {
				_adjacencyMatrix[_dimension * i + j] = [self distanceBetween:_nodes[i].coordination and:_nodes[j].coordination];
			}
		}
	}
}

- (void)computeNeighborMatrix
{
	if (self.neighborMatrix == NULL) {
		_neighborMatrix = calloc(_dimension * _dimension, sizeof(NeighborInfo));
		[self computeAdjacencyMatrix];
		
		for (int i = 0; i < _dimension; i++) {
			for (int j = 0; j < _dimension; j++) {
				// Copy adjacency matrix.
				_neighborMatrix[_dimension * i + j].index	 = _nodes[j].index;
				_neighborMatrix[_dimension * i + j].distance = _adjacencyMatrix[_dimension * i + j];
			}
			
			// ignore i == j element because the element is not a neighbor but itself.
			_neighborMatrix[_dimension * i + i] = _neighborMatrix[_dimension * i + _dimension - 1];
			
			// Sort neighbors  by distance.
			qsort(&(_neighborMatrix[_dimension * i + 0]), _dimension - 1, sizeof(NeighborInfo), (int(*)(const void *, const void *))compareDistances);
		}
	}
}

- (int)distanceBetween:(CGPoint)A and:(CGPoint)B
{
	return (int)(sqrt((B.x - A.x) * (B.x - A.x) + (B.y- A.y) * (B.y - A.y)) + 0.5);
}


- (PathInfo)shortestPathByNNFrom:(int)start
{
	PathInfo shortestPath;
	int from, to;
	NSMutableArray *visited = [NSMutableArray array];
	double distance = 0.0;

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
				distance += self.neighborMatrix[self.dimension * (from - 1) + j].distance;
				from = to;
				break;
			}
		}
	}
	distance += self.adjacencyMatrix[self.dimension * (from - 1) + start]; // Go back to the start node
	
	shortestPath.path	= [self intArrayFromArray:visited];
	shortestPath.length	= distance;
	
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

- (void)improvePathBy2opt:(PathInfo *)path
{
	double newLength;
	BOOL improved = NO;
	
//	do {
		for (int i = 0; i < self.dimension - 2; i++) {
			for (int j = i + 1; j < self.dimension - 1; j++) {
				if (i == j) continue;
				newLength = path->length
				- self.adjacencyMatrix[self.dimension * (path->path[i]	  - 1)	+ (path->path[i + 1] - 1)]
				- self.adjacencyMatrix[self.dimension * (path->path[j]     - 1)	+ (path->path[j + 1] - 1)]
				+ self.adjacencyMatrix[self.dimension * (path->path[i]     - 1)	+ (path->path[j]     - 1)]
				+ self.adjacencyMatrix[self.dimension * (path->path[i + 1] - 1)	+ (path->path[j + 1] - 1)];
				if (newLength < path->length) {
					swapNodes(path->path, self.dimension, i, j);
					path->length = newLength;
					improved = YES;
				} else {
					improved = NO;
				}
			}
		}
//	} while (improved);
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
	printf("========== SHORTEST PATH ==========\n");
	printf("Path: ");
	for (int i = 0; i < self.dimension; i++) {
		printf("%d, ", pathInfo.path[i]);
	}
	printf("\nLength = %.1f", pathInfo.length);
}

- (void)freePath:(PathInfo)path
{
	if (path.path) {
		free(path.path);
	}
}

- (void)dealloc
{
	if (_nodes)				free(_nodes);
	if (_adjacencyMatrix)	free(_adjacencyMatrix);
	if (_neighborMatrix)	free(_neighborMatrix);
}

@end