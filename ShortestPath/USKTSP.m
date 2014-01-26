//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKTSP.h"

int distanceBetween(CGPoint A, CGPoint B)
{
	double dx = B.x - A.x;
	double dy = B.y - A.y;
	return (int)(sqrt(dx * dx + dy * dy) + 0.5);
}

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
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	int lineNumber = 0;
	while ([lines[lineNumber] rangeOfString:@"EOF"].location == NSNotFound) {
		if ([lines[lineNumber] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound
			|| [lines[lineNumber] rangeOfString:@"DISPLAY_DATA_SECTION"].location != NSNotFound) {
			// Read node coordinations.
			BOOL nodeCodeSection = NO;
			if ([lines[lineNumber] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound) {
				nodeCodeSection = YES;
			}
			lineNumber++;
			if ([[dictionary valueForKey:@"TYPE"] isEqualToString:@"TSP"]) {
				_nodes = calloc(_dimension, sizeof(TSPNode));
				int nodeIndex = 0;
				while (TRUE) {
					NSArray *nodeInfo = [[self trimmedStringWithString:lines[lineNumber]] componentsSeparatedByString:@" "];
					nodeInfo = [self trimmedArrayWithArray:nodeInfo];
					if (nodeInfo.count != 3) {
						break;
					}
					_nodes[nodeIndex].index			 = [nodeInfo[0] intValue];
					_nodes[nodeIndex].coordination.x = [nodeInfo[1] doubleValue];
					_nodes[nodeIndex].coordination.y = [nodeInfo[2] doubleValue];
					lineNumber++;
					nodeIndex++;
				}
			}
			if (nodeCodeSection) {
				[self computeAdjacencyMatrix];
			}
		} else if ([lines[lineNumber] rangeOfString:@"EDGE_WEIGHT_SECTION"].location != NSNotFound) {
			lineNumber++;
			// Read adjacency matrix.
			if ([[dictionary valueForKey:@"TYPE"] isEqualToString:@"TSP"]) {
				_adjacencyMatrix = calloc(_dimension * _dimension, sizeof(double));
				int nodeIndex = 0;
				while (TRUE) {
					NSArray *edgeWeights = [[self trimmedStringWithString:lines[lineNumber]] componentsSeparatedByString:@" "];
					edgeWeights = [self trimmedArrayWithArray:edgeWeights];
					// Read distances from node[nodeIndex].
					for (int i = 0; i < _dimension - nodeIndex - 1; i++) {
						_adjacencyMatrix[_dimension * nodeIndex + nodeIndex + 1 + i] = [edgeWeights[i] intValue];
					}
					// Copy upper triangle into lower triangle
					for (int i = 1; i < _dimension; i++) {
						for (int j = 0; j < i; j++) {
							_adjacencyMatrix[_dimension * i + j] = _adjacencyMatrix[_dimension * j + i];
						}
					}
					lineNumber++;
					nodeIndex++;
					if (edgeWeights.count == 1) {
						break;
					}
				}
			}
		} else {
			NSArray *components = [[self trimmedStringWithString:lines[lineNumber]] componentsSeparatedByString:@":"];
			NSString *key = [self trimmedStringWithString:components[0]];
			NSString *val = [self trimmedStringWithString:components[1]];
			[dictionary setValue:val forKey:key];
			if ([key isEqualToString:@"DIMENSION"]) {
				_dimension = [val intValue];
			}
			lineNumber++;
		}
	}
	_information = dictionary;
}

- (NSString *)trimmedStringWithString:(NSString *)string
{
	// Trim whitespace. (i.e. @" ch130" => @"ch130")
	return [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
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
		
		if ([[_information valueForKey:@"TYPE"] isEqualToString:@"TSP"]) { // Symmetry
			// Compute only upper triangle
			for (int i = 0; i < _dimension; i++) {
				for (int j = i + 1; j < _dimension; j++) {
					_adjacencyMatrix[_dimension * i + j] = distanceBetween(_nodes[i].coordination, _nodes[j].coordination);
				}
			}
			// Distance to the same node is 0
			for (int i = 0; i < _dimension; i++) {
				_adjacencyMatrix[_dimension * i + i] = 0;
			}
			// Copy upper triangle into lower triangle
			for (int i = 1; i < _dimension; i++) {
				for (int j = 0; j < i; j++) {
					_adjacencyMatrix[_dimension * i + j] = _adjacencyMatrix[_dimension * j + i];
				}
			}
		} else { // Asymmetry
			for (int i = 0; i < _dimension; i++) {
				for (int j = 0; j < _dimension; j++) {
					_adjacencyMatrix[_dimension * i + j] = distanceBetween(_nodes[i].coordination, _nodes[j].coordination);
				}
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

- (PathInfo)shortestPathByNNFrom:(int)start
{
	PathInfo shortestPath;
	int from, to;
	NSMutableArray *visited = [NSMutableArray array];
	int distance = 0;

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
	BOOL improved = YES;
	
	while (improved) {
		improved = NO;
		for (int i = 0; i < self.dimension - 2; i++) {
			for (int j = i + 1; j < self.dimension - 1; j++) {
				if (i == j) continue;
				newLength = path->length
				- self.adjacencyMatrix[self.dimension * (path->path[i]	   - 1)	+ (path->path[i + 1] - 1)]
				- self.adjacencyMatrix[self.dimension * (path->path[j]     - 1)	+ (path->path[j + 1] - 1)]
				+ self.adjacencyMatrix[self.dimension * (path->path[i]     - 1)	+ (path->path[j]     - 1)]
				+ self.adjacencyMatrix[self.dimension * (path->path[i + 1] - 1)	+ (path->path[j + 1] - 1)];
				if (newLength < path->length) {
					swapNodes(path->path, self.dimension, i, j);
					path->length = newLength;
					improved = YES;
				}
			}
		}
	}
}

#pragma mark - print methods

- (void)printInformation
{
	printf("========== FILE INFORMATION ==========\n");
	[self.information enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
		printf("%s: %s\n", [key cStringUsingEncoding:NSUTF8StringEncoding], [obj cStringUsingEncoding:NSUTF8StringEncoding]);
	}];
		
	printf("NODE_COORD_SECTION:\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%3d %13.2f %13.2f\n", self.nodes[i].index, self.nodes[i].coordination.x, self.nodes[i].coordination.y);
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
			printf("%4d ", ((int)self.adjacencyMatrix[self.dimension * i + j]));
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
			printf("%4d ", self.neighborMatrix[self.dimension * i + j].index);
		}
		printf("\n");
	}
	printf("\n");
	
	printf("========== NEIGHBOR DISTANCE MATRIX ==========\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", self.nodes[i].index);
		for (int j = 0; j < self.dimension - 1; j++) {
			printf("%4d ", (int)(self.neighborMatrix[self.dimension * i + j].distance));
		}
		printf("\n");
	}
	printf("\n");
}


- (void)printPath:(PathInfo)pathInfo
{
	printf("Path: ");
	for (int i = 0; i < self.dimension; i++) {
		printf("%d, ", pathInfo.path[i]);
	}
	printf("\nLength = %.1f", pathInfo.length);
}

#pragma mark - Release and Deconstruction methods

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