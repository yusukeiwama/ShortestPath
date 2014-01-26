//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKTSP.h"
#import "USKTrimmer.h"

NSDictionary *optimalLengthDictionary;

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
	int  *tmpPath = calloc(dimension, sizeof(int));
	
	int l = 0;
	for (int k = 0; k <= i; k++) {
		tmpPath[l] = path[k];
		l++;
	}
	for (int k = j; k > i; k--) {
		tmpPath[l] = path[k];
		l++;
	}
	for (int k = j + 1; k < dimension; k++) {
		tmpPath[l] = path[k];
		l++;
	}
	
	memcpy(path, tmpPath, dimension * sizeof(int));
	free(tmpPath);
}

@interface USKTSP ()
@end

@implementation USKTSP {
	NSDictionary *_optimalLengthDictionary;
}

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
		[USKTSP optimalSolutionWithName:@"rd100"];

	}
	return self;
}

#pragma mark - read file

// FIXME: FIX_EDGE_SECTION is not parsed (linhp318.tsp)
- (BOOL)readTSPDataFromFile:(NSString *)path
{
	// Split contents of file into lines.
	_filePath = path;
	NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [rawString componentsSeparatedByString:@"\n"];

	// Read basic information.
	NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
	int l = 0;
	while ([lines[l] rangeOfString:@"EOF"].location == NSNotFound) {
		if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound
			|| [lines[l] rangeOfString:@"DISPLAY_DATA_SECTION"].location != NSNotFound) {
			// Read node coordinations.
			BOOL nodeCodeSection = NO;
			if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound) {
				nodeCodeSection = YES;
			}
			l++;
			if ([[tmpDictionary valueForKey:@"TYPE"] isEqualToString:@"TSP"]) {
				_nodes = calloc(_dimension, sizeof(TSPNode));
				int nodeIndex = 0;
				while (TRUE) {
					NSArray *nodeInfo = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@" "];
					nodeInfo = [USKTrimmer trimmedArrayWithArray:nodeInfo];
					if (nodeInfo.count != 3) {
						break;
					}
					_nodes[nodeIndex].index			 = [nodeInfo[0] intValue];
					_nodes[nodeIndex].coordination.x = [nodeInfo[1] doubleValue];
					_nodes[nodeIndex].coordination.y = [nodeInfo[2] doubleValue];
					l++;
					nodeIndex++;
				}
			}
			if (nodeCodeSection) {
				[self computeAdjacencyMatrix];
			}
		} else if ([lines[l] rangeOfString:@"EDGE_WEIGHT_SECTION"].location != NSNotFound) {
			l++;
			// Read adjacency matrix.
			_adjacencyMatrix = calloc(_dimension * _dimension, sizeof(double));
			// Read edge weights.
			NSMutableArray *edgeWeights = [NSMutableArray array];
			while (TRUE) {
				NSArray *anEdgeWeights = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@" "];
				anEdgeWeights = [USKTrimmer trimmedArrayWithArray:anEdgeWeights];
				if ([anEdgeWeights[0] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]].location == NSNotFound) {
					// if there is no number in the first component in the line, break to read next information.
					break;
				}
				[edgeWeights addObjectsFromArray:anEdgeWeights];
				l++;
			}
			// Parse edge weights
			if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"FULL_MATRIX"]) {
				for (int i = 0; i < edgeWeights.count; i++) {
					_adjacencyMatrix[i] = [edgeWeights[i] intValue];
				}
			} else if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"UPPER_ROW"]) {
				int edgeWeightIndex = 0;
				for (int nodeIndex = 0; nodeIndex < _dimension; nodeIndex++) {
					for (int i = 0; i < _dimension - nodeIndex - 1; i++) {
						_adjacencyMatrix[_dimension * nodeIndex + nodeIndex + 1 + i] = [edgeWeights[edgeWeightIndex] intValue];
						edgeWeightIndex++;
					}
				}
				// Copy upper triangle into lower triangle
				for (int i = 1; i < _dimension; i++) {
					for (int j = 0; j < i; j++) {
						_adjacencyMatrix[_dimension * i + j] = _adjacencyMatrix[_dimension * j + i];
					}
				}
			} else if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"UPPER_DIAG_ROW"]) {
				int edgeWeightIndex = 0;
				for (int nodeIndex = 0; nodeIndex < _dimension; nodeIndex++) {
					for (int i = 0; i < _dimension - nodeIndex; i++) {
						_adjacencyMatrix[_dimension * nodeIndex + nodeIndex + i] = [edgeWeights[edgeWeightIndex] intValue];
						edgeWeightIndex++;
					}
				}
				// Copy upper triangle into lower triangle
				for (int i = 1; i < _dimension; i++) {
					for (int j = 0; j < i; j++) {
						_adjacencyMatrix[_dimension * i + j] = _adjacencyMatrix[_dimension * j + i];
					}
				}
			} else if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"LOWER_DIAG_ROW"]) {
				int edgeWeightIndex = 0;
				for (int nodeIndex = 0; nodeIndex < _dimension; nodeIndex++) {
					for (int i = 0; i < nodeIndex + 1; i++) {
						_adjacencyMatrix[_dimension * nodeIndex + i] = [edgeWeights[edgeWeightIndex] intValue];
						edgeWeightIndex++;
					}
				}
				// Copy lower triangle into upper triangle
				for (int i = 0; i < _dimension; i++) {
					for (int j = i + 1; j < _dimension; j++) {
						_adjacencyMatrix[_dimension * i + j] = _adjacencyMatrix[_dimension * j + i];
					}
				}
				
			}
		} else {
			NSArray *components = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@":"];
			NSString *key = [USKTrimmer trimmedStringWithString:components[0]];
			NSString *val = [USKTrimmer trimmedStringWithString:components[1]];
			[tmpDictionary setValue:val forKey:key];
			if ([key isEqualToString:@"DIMENSION"]) {
				_dimension = [val intValue];
			}
			l++;
		}
	}
	_information = tmpDictionary;

	return YES;
}

/**
 *  Return the optimal solution by reading files.
 *
 *  @param name problem name of the TSP.
 *
 *  @return optimal path. If there is no path information, returns NULL.
 */
+ (PathInfo)optimalSolutionWithName:(NSString *)name
{
	PathInfo optimalPath;
	
	// Read optimal lengths from file
	if (optimalLengthDictionary == nil) {
		NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
		NSString *rawString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"optimalSolutions" ofType:@"txt"] encoding:NSASCIIStringEncoding error:nil];
		NSArray *lines = [rawString componentsSeparatedByString:@"\n"];
		
		int l = 0;
		while ([lines[l] rangeOfString:@"EOF"].location == NSNotFound) {
			NSArray *components = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@":"];
			components = [USKTrimmer trimmedArrayWithArray:components];
			NSString *key = [USKTrimmer trimmedStringWithString:components[0]];
			NSString *val = [USKTrimmer trimmedStringWithString:components[1]];
			[tmpDictionary setValue:val forKey:key];
			l++;
		}
		optimalLengthDictionary = tmpDictionary;
	}
	// Look up optimal length dictionary for the specified name.
	optimalPath.length = [[optimalLengthDictionary valueForKey:name] intValue];
	
	// Read optimal path from file.
	NSString *rawString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"opt.tour"] encoding:NSASCIIStringEncoding error:nil];
	if (rawString) {
		NSArray *lines = [rawString componentsSeparatedByString:@"\n"];
		
		// Look up TOUR_SECTION
		int l = 0;
		int dimension = 0;
		while ([lines[l] rangeOfString:@"EOF"].location == NSNotFound) {
			if ([lines[l] rangeOfString:@"TOUR_SECTION"].location != NSNotFound) {
					// Read .tsp file to get dimenison.
					NSString *tspString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"tsp"] encoding:NSASCIIStringEncoding error:nil];
					NSArray *tspLines = [tspString componentsSeparatedByString:@"\n"];

					int tl = 0;
					while ([tspLines[tl] rangeOfString:@"DIMENSION"].location == NSNotFound) {
						tl++;
					}
					NSArray *components = [[USKTrimmer trimmedStringWithString:tspLines[tl]] componentsSeparatedByString:@":"];
					dimension = [[USKTrimmer trimmedStringWithString:components[1]] intValue];
				
				// Read path
				l++;
				optimalPath.path = calloc(dimension, sizeof(int));
				// Read path
				NSMutableArray *path = [NSMutableArray array];
				while (TRUE) {
					NSArray *aPath = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@" "];
					aPath = [USKTrimmer trimmedArrayWithArray:aPath];
					if (path.count == dimension) {
						break;
					}
					[path addObjectsFromArray:aPath];
					l++;
				}
				// Set optimal path.
				optimalPath.path = [USKTSP intArrayFromArray:path];
			}
			l++;
		}
	}

	return optimalPath;
}

#pragma mark - compute matrix

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
				_neighborMatrix[_dimension * i + j].index	 = j + 1;
				_neighborMatrix[_dimension * i + j].distance = _adjacencyMatrix[_dimension * i + j];
			}
			
			// ignore i == j element because the element is not a neighbor but itself.
			_neighborMatrix[_dimension * i + i] = _neighborMatrix[_dimension * i + _dimension - 1];
			
			// Sort neighbors  by distance.
			qsort(&(_neighborMatrix[_dimension * i + 0]), _dimension - 1, sizeof(NeighborInfo), (int(*)(const void *, const void *))compareDistances);
		}
	}
}

#pragma mark - Algorithms

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
	
	shortestPath.path	= [USKTSP intArrayFromArray:visited];
	shortestPath.length	= distance;
	
	return shortestPath;
}

+ (int *)intArrayFromArray:(NSArray *)array
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
		
	if (_nodes != NULL) {
		printf("NODE_COORD_SECTION:\n");
		for (int i = 0; i < self.dimension; i++) {
			printf("%3d %13.2f %13.2f\n", self.nodes[i].index, self.nodes[i].coordination.x, self.nodes[i].coordination.y);
		}
		printf("\n");
	}
}

- (void)printAdjecencyMatrix
{
	printf("========== WEIGHTED ADJECENCY MATRIX ==========\n");
	printf("      ");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d ", i + 1);
	}
	printf("\n");
	
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", i + 1);
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
		printf("%4d: ", i + 1);
		for (int j = 0; j < self.dimension - 1; j++) {
			printf("%4d ", self.neighborMatrix[self.dimension * i + j].index);
		}
		printf("\n");
	}
	printf("\n");
	
	printf("========== NEIGHBOR DISTANCE MATRIX ==========\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", i + 1);
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