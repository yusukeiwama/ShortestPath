//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "TSP.h"
#import "USKTrimmer.h"

// Cannot deal because of short of memory.
#define MAX_DIMENSION 10000

NSDictionary *optimalLengthDictionary;

int euc2D(CGPoint A, CGPoint B)
{
	double dx = B.x - A.x;
	double dy = B.y - A.y;
	return rint(sqrt(dx * dx + dy * dy));
}

int compareDistances(const Neighbor *a, const Neighbor *b)
{
	return ((Neighbor)(*a)).distance - ((Neighbor)(*b)).distance;
}

int length2opt(Tour *path, TSP *tsp, int i, int j)
{
	return  path->length
	- tsp.adjacencyMatrix[tsp.dimension * (path->route[i]	  - 1)	+ (path->route[i + 1] - 1)]
	- tsp.adjacencyMatrix[tsp.dimension * (path->route[j]     - 1)	+ (path->route[j + 1] - 1)]
	+ tsp.adjacencyMatrix[tsp.dimension * (path->route[i]     - 1)	+ (path->route[j]     - 1)]
	+ tsp.adjacencyMatrix[tsp.dimension * (path->route[i + 1] - 1)	+ (path->route[j + 1] - 1)];
}

void swap2opt(int *route, int d, int i, int j)
{
	int  *newRoute = calloc(d, sizeof(int));
	
	int l = 0;
	for (int k = 0;     k <= i; k++) newRoute[l++] = route[k];
	for (int k = j;     k >  i; k--) newRoute[l++] = route[k];
	for (int k = j + 1; k <  d; k++) newRoute[l++] = route[k];
	
	memcpy(route, newRoute, d * sizeof(int));
	free(newRoute);
}

@interface TSP ()
@end

@implementation TSP {
	NSDictionary *_optimalLengthDictionary;
}

#pragma mark - Constructors

+ (id)TSPWithFile:(NSString *)path
{
	return [[TSP alloc] initWithFile:path];
}

- (id)initWithFile:(NSString *)path
{
	self = [super init];
	if (self) {
		if ([self readTSPDataFromFile:path]) {
			[self computeNeighborMatrix];
			
//			[self printInformation];
//			[self printAdjecencyMatrix];
//			[self printNeighborMatrix];
		} else {
			return nil;
		}
	}
	return self;
}

+ (id)randomTSPWithDimension:(NSInteger)dimension
{
	return [[TSP alloc] initRandomTSPWithDimension:dimension];
}

- (id)initRandomTSPWithDimension:(NSInteger)dimension
{
	self = [super init];
	if (self) {
		srand((unsigned)time(NULL));
		
		_dimension = dimension;
		_nodes = calloc(dimension, sizeof(Node));
		for (int i = 0; i < dimension; i++) {
			CGPoint p = CGPointMake(100.0 * rand() / (RAND_MAX + 1.0), 100.0 * rand() / (RAND_MAX + 1.0));
			_nodes[i].number = i + 1;
			_nodes[i].coord  = p;
		}
		[self computeNeighborMatrix];
	}
	return self;
}

#pragma mark - read file

// FIXME: FIX_EDGE_SECTION is not parsed (linhp318.tsp)
// FIXME: unsupported EDGE_WEIGHT_FORMAT
- (BOOL)readTSPDataFromFile:(NSString *)path
{
	// Split contents of file into lines.
	_filePath = path;
	NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [rawString componentsSeparatedByString:@"\n"];
	lines = [USKTrimmer trimmedArrayWithArray:lines];

	// Read basic information.
	NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
	int l = 0;
	while (l < lines.count && [lines[l] rangeOfString:@"EOF"].location == NSNotFound) {
		if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound
			|| [lines[l] rangeOfString:@"DISPLAY_DATA_SECTION"].location != NSNotFound) {
			// Read node coordinations.
			BOOL nodeCodeSection = NO;
			if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound) {
				nodeCodeSection = YES;
			}
			l++;
			if ([[tmpDictionary valueForKey:@"TYPE"] isEqualToString:@"TSP"]) {
				_nodes = calloc(_dimension, sizeof(Node));
				int nodeIndex = 0;
				while (nodeIndex < _dimension) {
					NSArray *nodeInfo = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"	: "]];
					nodeInfo = [USKTrimmer trimmedArrayWithArray:nodeInfo];
					if (nodeInfo.count != 3) {
						break;
					}
					_nodes[nodeIndex].number  = [nodeInfo[0] intValue];
					_nodes[nodeIndex].coord.x = [nodeInfo[1] doubleValue];
					_nodes[nodeIndex].coord.y = [nodeInfo[2] doubleValue];
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
		} else if ([lines[l] rangeOfString:@"FIXED_EDGES_SECTION"].location != NSNotFound) {
			// !!!: Ignoring...
			while ([lines[l] rangeOfString:@"-1"].location == NSNotFound) {
				l++;
			}
			l++;
		} else {
			NSArray *components = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@":"];
			NSString *key = [USKTrimmer trimmedStringWithString:components[0]];
			NSString *val = [USKTrimmer trimmedStringWithString:components[1]];
			[tmpDictionary setValue:val forKey:key];
			if ([key isEqualToString:@"DIMENSION"]) {
				_dimension = [val intValue];
				if (_dimension > MAX_DIMENSION) {
					return NO;
				}
			}
			l++;
		}
	}
	_information = tmpDictionary;

	return YES;
}


+ (Tour)optimalSolutionWithName:(NSString *)name
{
	Tour optimalPath = {-1, NULL};
	
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
		
		while ([lines[l] rangeOfString:@"EOF"].location == NSNotFound
			   && [lines[l] rangeOfString:@"-1"].location == NSNotFound
			   && l < lines.count) {
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
				optimalPath.route = calloc(dimension, sizeof(int));
				// Read path
				NSMutableArray *path = [NSMutableArray array];
				while (TRUE) {
					l++;
					NSArray *aPath = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByString:@" "];
					aPath = [USKTrimmer trimmedArrayWithArray:aPath];
					if (path.count == dimension) {
						if ([lines[l] rangeOfString:@"-1"].location != NSNotFound) {
							l--;
						}
						break;
					}
					[path addObjectsFromArray:aPath];
				}
				// Set optimal path.
				optimalPath.route = [TSP intArrayFromArray:path];
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
		_adjacencyMatrix = calloc(_dimension * _dimension, sizeof(int));
		for (int i = 0; i < _dimension; i++) {
			for (int j = 0; j < _dimension; j++) {
				_adjacencyMatrix[_dimension * i + j] = euc2D(_nodes[i].coord, _nodes[j].coord);
			}
		}
	}
}

- (void)computeNeighborMatrix
{
	if (self.neighborMatrix == NULL) {
		_neighborMatrix = calloc(_dimension * _dimension, sizeof(Neighbor));
		[self computeAdjacencyMatrix];
		
		for (int i = 0; i < _dimension; i++) {
			for (int j = 0; j < _dimension; j++) {
				// Copy adjacency matrix.
				_neighborMatrix[_dimension * i + j].number = j + 1;
				_neighborMatrix[_dimension * i + j].distance   = _adjacencyMatrix[_dimension * i + j];
			}
			
			// ignore i == j element because the element is not a neighbor but itself.
			_neighborMatrix[_dimension * i + i] = _neighborMatrix[_dimension * i + _dimension - 1];
			
			// Sort neighbors  by distance.
			qsort(&(_neighborMatrix[_dimension * i + 0]), _dimension - 1, sizeof(Neighbor), (int(*)(const void *, const void *))compareDistances);
		}
	}
}

#pragma mark - Algorithms

- (Tour)tourByNNFrom:(int)start
{
	Tour tour;
	int from, to;
    int *visited = calloc(self.dimension + 1, sizeof(int));
	int distanceSum = 0;

	from = start;
    visited[0] = from;

    int i = 1;
	while (i < self.dimension) { // visited count loop
		for (int j = 0; j < self.dimension - 1; j++) { // neighbor loop
        loop:
			// Look up the nearest node.
			to = self.neighborMatrix[self.dimension * (from - 1) + j].number;
			
			// Check if the node has already been visited.
            for (int k = 0; k < i; k++) { // visited check loop
                if (to == visited[k]) {
                    j++;
                    goto loop;
                }
            }
            // if not visited yet
            visited[i++] = to;
            distanceSum += self.neighborMatrix[self.dimension * (from - 1) + j].distance;
            from = to;
            break;
        }
	}
	// Go back to the start node
    visited[i] = start;
	distanceSum += self.adjacencyMatrix[self.dimension * (from - 1) + (start - 1)];
	
	tour.route	= visited;
	tour.length	= distanceSum;
	
	return tour;
}

- (void)improveTourBy2opt:(Tour *)tour
{
	int  newLength;
	BOOL improved = YES;

	while (improved) {
		improved = NO;
		for (int i = 0; i < self.dimension - 1; i++) {
			for (int j = i + 1; j < self.dimension ; j++) {
				if (i == j) continue;
				newLength = length2opt(tour, self, i, j);
				if (newLength < tour->length) {
					swap2opt(tour->route, self.dimension, i, j);
					tour->length = newLength;
					improved = YES;
				}
			}
		}
	}
}

#pragma mark - utility methods

+ (int *)intArrayFromArray:(NSArray *)array
{
	int *arr = calloc(array.count, sizeof(int));
	for (int i = 0; i < array.count; i++) {
		arr[i] = [((NSNumber *)array[i]) intValue];
	}
	return arr;
}

#pragma mark - print methods

- (void)printInformation
{
	printf("\n========== FILE INFORMATION ==========\n");
	[self.information enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
		printf("%s: %s\n", [key cStringUsingEncoding:NSUTF8StringEncoding], [obj cStringUsingEncoding:NSUTF8StringEncoding]);
	}];
		
	if (_nodes != NULL) {
		printf("NODE_COORD_SECTION:\n");
		for (int i = 0; i < self.dimension; i++) {
			printf("%3d %13.2f %13.2f\n", self.nodes[i].number, self.nodes[i].coord.x, self.nodes[i].coord.y);
		}
	}
}

- (void)printAdjecencyMatrix
{
	printf("\n========== WEIGHTED ADJECENCY MATRIX ==========\n");
	printf("      ");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d ", i + 1);
	}
	printf("\n");
	
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", i + 1);
		for (int j = 0; j < self.dimension; j++) {
			printf("%4d ", self.adjacencyMatrix[self.dimension * i + j]);
		}
		printf("\n");
	}
}

- (void)printNeighborMatrix
{
	printf("\n========== NEIGHBOR INDEX MATRIX ==========\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", i + 1);
		for (int j = 0; j < self.dimension - 1; j++) {
			printf("%4d ", self.neighborMatrix[self.dimension * i + j].number);
		}
		printf("\n");
	}
	
	printf("\n========== NEIGHBOR DISTANCE MATRIX ==========\n");
	for (int i = 0; i < self.dimension; i++) {
		printf("%4d: ", i + 1);
		for (int j = 0; j < self.dimension - 1; j++) {
			printf("%4d ", (int)(self.neighborMatrix[self.dimension * i + j].distance));
		}
		printf("\n");
	}
}


+ (void)printPath:(Tour)Tour ofTSP:(TSP *)tsp
{
	printf("\n========== PATH ==========\n");
	printf("Length = %d\n", Tour.length);
	if (Tour.route == NULL) {
		return;
	}
	printf("Path: ");
	for (int i = 0; i < tsp.dimension; i++) {
		printf("%4d ", Tour.route[i]);
	}
}

#pragma mark - Deconstruction

- (void)dealloc
{
	if (_nodes)				free(_nodes);
	if (_adjacencyMatrix)	free(_adjacencyMatrix);
	if (_neighborMatrix)	free(_neighborMatrix);
}

@end