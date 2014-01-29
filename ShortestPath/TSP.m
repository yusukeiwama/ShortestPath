//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "TSP.h"
#import "USKTrimmer.h"

NSDictionary *optimalLengthDictionary;

typedef struct _Neighbor {
	int	number;
	int distance;
} Neighbor;

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

/// return (distance - A[i][i+1] - A[j][j+1] + A[i][j] + A[i+1][j+1])
int length2opt(Tour *tour, int *A, int n, int i, int j)
{
    int *r = tour->route;
    
	return tour->distance
    - A[(r[i]	- 1) * n + (r[i+1] - 1)]  // A[i  ][i+1]
	- A[(r[j]   - 1) * n + (r[j+1] - 1)]  // A[j  ][j+1]
	+ A[(r[i]   - 1) * n + (r[j]   - 1)]  // A[i  ][j  ]
	+ A[(r[i+1] - 1) * n + (r[j+1] - 1)]; // A[i+1][j+1]
}

void swap2opt(int *route, int d, int i, int j)
{
	int  *newRoute = calloc(d, sizeof(int));
	
	int l = 0;
	for (int k = 0;     k <= i; k++) newRoute[l++] = route[k]; // add node in order
	for (int k = j;     k >  i; k--) newRoute[l++] = route[k]; // add node in reverse order
	for (int k = j + 1; k <  d; k++) newRoute[l++] = route[k]; // add node in order
	
	memcpy(route, newRoute, d * sizeof(int));
	free(newRoute);
}

@interface TSP ()

@property (readonly) int	  *adjacencyMatrix;
@property (readonly) Neighbor *neighborMatrix;

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
//          [self printNodes];
//			[self printAdjecencyMatrix];
//			[self printNeighborMatrix];
		} else {
			return nil;
		}
	}
        
	return self;
}

+ (id)randomTSPWithDimension:(NSInteger)dimension seed:(unsigned int)seed
{
    if (dimension > MAX_DIMENSION) {
        dimension = MAX_DIMENSION;
    } else if (dimension < 3) {
        return nil;
    }
	return [[TSP alloc] initRandomTSPWithDimension:dimension seed:seed];
}

- (id)initRandomTSPWithDimension:(NSInteger)dimension seed:(unsigned int)seed
{
	self = [super init];
	if (self) {
		srand(seed);
		
		_dimension = dimension;
		_nodes = calloc(dimension, sizeof(Node));
		for (int i = 0; i < dimension; i++) {
			CGPoint p = CGPointMake(100.0 * rand() / (RAND_MAX + 1.0),
                                    100.0 * rand() / (RAND_MAX + 1.0));
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
	NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [rawString componentsSeparatedByString:@"\n"];
	lines = [USKTrimmer trimmedArrayWithArray:lines];

	// Read basic information.
	NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
	int l = 0;
	while (l < lines.count && [lines[l] rangeOfString:@"EOF"].location == NSNotFound) {
		if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound // Found
			|| [lines[l] rangeOfString:@"DISPLAY_DATA_SECTION"].location != NSNotFound) { // Found
			// Read node coordinations.
			BOOL nodeCodeSection = NO;
			if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound) { // Found
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
		} else if ([lines[l] rangeOfString:@"EDGE_WEIGHT_SECTION"].location != NSNotFound) { // Found
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
		} else if ([lines[l] rangeOfString:@"FIXED_EDGES_SECTION"].location != NSNotFound) { // Found
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
	optimalPath.distance = [[optimalLengthDictionary valueForKey:name] intValue];
	
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
			if ([lines[l] rangeOfString:@"TOUR_SECTION"].location != NSNotFound) { // Found

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
						if ([lines[l] rangeOfString:@"-1"].location != NSNotFound) { // Found
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
	int from, to;
    int *visited = calloc(self.dimension + 1, sizeof(int));
	int distanceSum = 0;

	from = start;
    visited[0] = from;

    int i = 1;
    int k = 0;
	while (i < self.dimension) {
		for (int j = 0; j < self.dimension - 1; j++) {
			// Look up the nearest node where has not been visited yet.
			to = self.neighborMatrix[self.dimension * (from - 1) + j].number;
			
			// Check if the node has already been visited.
            for (k = 0; k < i; k++) {
                if (to == visited[k]) {
                    break;
                }
            }
            
            // If new node has not been visited, add it to visited.
            if (k == i) {
                visited[i++] = to;
                distanceSum += self.neighborMatrix[self.dimension * (from - 1) + j].distance;
                from = to;
                break;
            }
        }
	}
	// Go back to the start node
    visited[i] = start;
	distanceSum += self.adjacencyMatrix[self.dimension * (from - 1) + (start - 1)];

    Tour tour = {distanceSum, visited};
	
	return tour;
}

- (void)improveTourBy2opt:(Tour *)tour
{
	BOOL improved = YES;

	while (improved) {
		improved = NO;
		for (int i = 0; i < self.dimension - 1; i++) {
			for (int j = i + 1; j < self.dimension ; j++) {
				int newLength = length2opt(tour, self.adjacencyMatrix, self.dimension, i, j);
				if (newLength < tour->distance) {
					swap2opt(tour->route, self.dimension, i, j);
					tour->distance = newLength;
					improved = YES;
				}
			}
		}
	}
}

double iPow(double val, int pow)
{
    double powered = 1.0;
    for (int i = 0; i < pow; i++) {
        powered *= val;
    }
    return powered;
}

int nextNodeNumber(bool *visited, int from, int n, int a, int b, double *P, int *A)
{
    // Compute the denominator of the probability.
    double sumWeight = 0.0;
    for (int j = 0; j < n; j++) {
        if (visited[j] == NO) {
            sumWeight += iPow(P[(from - 1) * n + j], a) * iPow(1.0 / A[(from - 1) * n + j], b);
        }
    }

    int to = 0;
    if (sumWeight < DBL_MIN) { // No pheromone.
        // Select node randomly.
        int numberOfPossibleNode = 0;
        for (int j = 0; j < n; j++) {
            if (visited[j] == NO) {
                numberOfPossibleNode++;
            }
        }
        int targetOrder = numberOfPossibleNode * (double)rand() / (RAND_MAX + 1.0) + 1;
        int order = 0;
        int j = 0;
        while (order < targetOrder) {
            if (visited[j] == NO) {
                order++;
            }
            j++;
        }
        to = j;
        
    } else { // Pheromone exist.
        // Select node with probability.
        double targetWeight = sumWeight * (double)rand() / (RAND_MAX + 1.0);
        double weight = 0.0;
        int j = 0;
        while (weight < targetWeight) {
            if (visited[j] == NO) {
                weight += iPow(P[(from - 1) * n + j], a) * iPow(1.0 / A[(from - 1) * n + j], b);
            }
            j++;
        }
        to = j;
    }
    
    return to;
}

- (Tour)tourByASWithNumberOfAnt:(int)m
             pheromoneInfluence:(int)a
            transitionInfluence:(int)b
           pheromoneEvaporation:(double)r
                           seed:(unsigned int)seed
{
    srand(seed);
    
    int     n = self.dimension;
    int    *A = self.adjacencyMatrix;
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Initialize pheromone with average tour distance.
    int	totalDistance = 0;
    for (int i = 0; i < n; i++) {
        Tour aTour = [self tourByNNFrom:i + 1];
        totalDistance += aTour.distance;
        free(aTour.route);
    }
    double averateDistance = (double)totalDistance / n;
    double initialPheromone = m / averateDistance;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            P[i * n + j] = initialPheromone;
        }
    }
    
    // Generate solutions.
    Tour theShortestTour = {INT32_MAX, calloc(n, sizeof(int))};
    int noImproveCount = 0;
    while (noImproveCount < 1000) { // improve loop
        
        // Do ant tours.
        Tour tours[m];
        for (int k = 0; k < m; k++) { // ant loop
            tours[k].distance = 0;
            tours[k].route = calloc(n + 1, sizeof(int));
            // visited[i] is YES when node numbered i+1 was visited.
            bool *visited = calloc(n, sizeof(bool));
            int start = k % n + 1;
            tours[k].route[0] = start;
            visited[start - 1] = YES;
            int from = start;
            int to;
            for (int i = 1; i < n; i++) { // node loop
                to = nextNodeNumber(visited, from, n, a, b, P, A);
                tours[k].route[i] = to;
                visited[to - 1] = YES;
                tours[k].distance += A[(from - 1) * n + (to - 1)];
                from = to;
            }
            tours[k].route[n] = start;
            tours[k].distance += A[(from - 1) * n + (start - 1)];
            free(visited);
        }
        
        // Pheromone evaporation
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                P[i * n + j] *= (1.0 - r);
            }
        }
        
        // Pheromone update
        for (int k = 0; k < m; k++) {
            double pheromone = 1.0 / tours[k].distance;
            for (int i = 0; i < n; i++) {
                    P[(tours[k].route[i] - 1) * n + (tours[k].route[i+1] - 1)] += pheromone;
            }
        }
        
        // Find shortest path.
        Tour shortestTour = {INT32_MAX, NULL};
        for (int k = 0; k < m; k++) {
            if (tours[k].distance < shortestTour.distance) {
                free(shortestTour.route);
                shortestTour = tours[k];
            } else {
                free(tours[k].route);
            }
        }
        
        // Improve path.
        if (shortestTour.distance < theShortestTour.distance) {
            free(theShortestTour.route);
            theShortestTour = shortestTour;
            noImproveCount = 0;
        } else {
            free(shortestTour.route);
            noImproveCount++;
        }
    }
    
    return theShortestTour;
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
	printf("\n========== TSP INFORMATION ==========\n");
	[self.information enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
		printf("%s: %s\n", [key cStringUsingEncoding:NSUTF8StringEncoding], [obj cStringUsingEncoding:NSUTF8StringEncoding]);
	}];
		
}

- (void)printNodes
{
	if (_nodes != NULL) {
		printf("\n========== NODE COORDINATIONS ==========\n");
		for (int i = 0; i < self.dimension; i++) {
			printf("%5d: (%10.2f, %10.2f)\n", self.nodes[i].number, self.nodes[i].coord.x, self.nodes[i].coord.y);
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
	printf("Length = %d\n", Tour.distance);
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