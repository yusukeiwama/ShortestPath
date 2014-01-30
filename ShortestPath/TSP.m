//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "TSP.h"
#import "USKTrimmer.h"

int euc2D(Coordinate P, Coordinate Q)
{
	double dx = Q.x - P.x;
	double dy = Q.y - P.y;
	return (int)(sqrt(dx * dx + dy * dy) + 0.5);
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

@end

@implementation TSP

@synthesize dimension       = n;
@synthesize nodes           = N;
@synthesize adjacencyMatrix = A;

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
//			[self printInformation];
//          [self printNodes];
//			[self printAdjecencyMatrix];
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
		
		n = dimension;
		N = calloc(n, sizeof(Node));
		for (int i = 0; i < n; i++) {
			Coordinate p = {100.0 * rand() / (RAND_MAX + 1.0), 100.0 * rand() / (RAND_MAX + 1.0)};
			N[i].number  = i + 1;
			N[i].coord   = p;
		}
	}
	return self;
}

#pragma mark - read file

// FIXME: FIX_EDGE_SECTION is not parsed (linhp318.tsp)
// FIXME: unsupported EDGE_WEIGHT_FORMAT
- (bool)readTSPDataFromFile:(NSString *)path
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
			bool nodeCodeSection = false;
			if ([lines[l] rangeOfString:@"NODE_COORD_SECTION"].location != NSNotFound) { // Found
				nodeCodeSection = true;
			}
			l++;
			if ([[tmpDictionary valueForKey:@"TYPE"] isEqualToString:@"TSP"]) {
				N = calloc(n, sizeof(Node));
				int nodeIndex = 0;
				while (nodeIndex < n) {
					NSArray *nodeInfo = [[USKTrimmer trimmedStringWithString:lines[l]] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"	: "]];
					nodeInfo = [USKTrimmer trimmedArrayWithArray:nodeInfo];
					if (nodeInfo.count != 3) {
						break;
					}
					N[nodeIndex].number  = [nodeInfo[0] intValue];
					N[nodeIndex].coord.x = [nodeInfo[1] doubleValue];
					N[nodeIndex].coord.y = [nodeInfo[2] doubleValue];
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
			A = calloc(n * n, sizeof(double));
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
					A[i] = [edgeWeights[i] intValue];
				}
			} else if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"UPPER_ROW"]) {
				int edgeWeightIndex = 0;
				for (int nodeIndex = 0; nodeIndex < n; nodeIndex++) {
					for (int i = 0; i < n - nodeIndex - 1; i++) {
						A[n * nodeIndex + nodeIndex + 1 + i] = [edgeWeights[edgeWeightIndex] intValue];
						edgeWeightIndex++;
					}
				}
				// Copy upper triangle into lower triangle
				for (int i = 1; i < n; i++) {
					for (int j = 0; j < i; j++) {
						A[i * n + j] = A[j * n + i];
					}
				}
			} else if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"UPPER_DIAG_ROW"]) {
				int edgeWeightIndex = 0;
				for (int nodeIndex = 0; nodeIndex < n; nodeIndex++) {
					for (int i = 0; i < n - nodeIndex; i++) {
						A[n * nodeIndex + nodeIndex + i] = [edgeWeights[edgeWeightIndex] intValue];
						edgeWeightIndex++;
					}
				}
				// Copy upper triangle into lower triangle
				for (int i = 1; i < n; i++) {
					for (int j = 0; j < i; j++) {
						A[i * n + j] = A[j * n + i];
					}
				}
			} else if ([[tmpDictionary valueForKey:@"EDGE_WEIGHT_FORMAT"] isEqualToString:@"LOWER_DIAG_ROW"]) {
				int edgeWeightIndex = 0;
				for (int nodeIndex = 0; nodeIndex < n; nodeIndex++) {
					for (int i = 0; i < nodeIndex + 1; i++) {
						A[n * nodeIndex + i] = [edgeWeights[edgeWeightIndex] intValue];
						edgeWeightIndex++;
					}
				}
				// Copy lower triangle into upper triangle
				for (int i = 0; i < n; i++) {
					for (int j = i + 1; j < n; j++) {
						A[i * n + j] = A[j * n + i];
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
				n = [val intValue];
				if (n > MAX_DIMENSION) {
					return false;
				}
			}
			l++;
		}
	}
	_information = tmpDictionary;

	return true;
}


+ (Tour)optimalSolutionWithName:(NSString *)name
{
	Tour optimalPath = {-1, NULL};
	
	// Read optimal lengths from file
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

    NSDictionary *optimalLengthDictionary = tmpDictionary;
    
	// Look up optimal length dictionary for the specified name.
	optimalPath.distance = [[optimalLengthDictionary valueForKey:name] intValue];
	
	// Read optimal path from file.
	rawString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"opt.tour"] encoding:NSASCIIStringEncoding error:nil];
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
	if (A == NULL) {
		A = calloc(n * n, sizeof(int));
		for (int i = 0; i < n; i++) {
			for (int j = 0; j < n; j++) {
				A[i * n + j] = euc2D(N[i].coord, N[j].coord);
			}
		}
	}
}

#pragma mark - Algorithms

int nearestNodeNumber(bool *visited, int from, int n, int *A)
{
    int number;
    int shortestDistance = INT32_MAX;
    for (int i = 0; i < n; i++) {
        if (visited[i] == false) {
            int distance = A[(from - 1) * n + i];
            if (distance < shortestDistance) {
                number           = i + 1;
                shortestDistance = distance;
            }
        }
    }
    return number;
}

- (Tour)tourByNNFrom:(int)start
{
    Tour tour     = {0, calloc(n + 1, sizeof(int))};
    bool *visited = calloc(n, sizeof(bool));

    tour.route[0]      = start;
    visited[start - 1] = true;
    
    int from = start;
    for (int i = 1; i < n; i++) {
        int to = nearestNodeNumber(visited, from, n, A);
        tour.distance   += A[(from - 1) * n + (to - 1)];
        tour.route[i]   =  to;
        visited[to - 1] =  true;
        from = to;
    }
    tour.distance += A[(from - 1) * n + (start - 1)];
    tour.route[n] =  start;

    return tour;
}

- (void)improveTourBy2opt:(Tour *)tour
{
	bool improved = true;
	while (improved) {
		improved = false;
		for (int i = 0; i < n - 1; i++) {
			for (int j = i + 1; j < n ; j++) {
				int newLength = length2opt(tour, A, n, i, j);
				if (newLength < tour->distance) {
					swap2opt(tour->route, n, i, j);
					tour->distance = newLength;
					improved = true;
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

void initializePheromone(double pheromone, int n, double *P)
{
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            P[i * n + j] = pheromone;
        }
    }
}

int nextNodeNumber(bool *visited, int from, int n, int a, int b, double *P, int *A)
{
    // Compute the denominator of the probability.
    double sumWeight = 0.0;
    for (int j = 0; j < n; j++) {
        if (visited[j] == false) {
            sumWeight += iPow(P[(from - 1) * n + j], a) * iPow(1.0 / A[(from - 1) * n + j], b);
        }
    }
    
    int to = 0;
    if (sumWeight < DBL_MIN) { // No pheromone.
        // Select node randomly.
        int numberOfPossibleNode = 0;
        for (int j = 0; j < n; j++) {
            if (visited[j] == false) {
                numberOfPossibleNode++;
            }
        }
        int targetOrder = numberOfPossibleNode * (double)rand() / (RAND_MAX + 1.0) + 1;
        int order = 0;
        int j = 0;
        while (order < targetOrder) {
            if (visited[j] == false) {
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
            if (visited[j] == false) {
                weight += iPow(P[(from - 1) * n + j], a) * iPow(1.0 / A[(from - 1) * n + j], b);
            }
            j++;
        }
        to = j;
    }
    
    return to;
}

Tour antTour(int k, int n, int *A, double *P, int a, int b)
{
    // Initialize a tour.
    Tour tour = {0, calloc(n + 1, sizeof(int))};
    
    // visited[i] is true when node numbered i+1 was visited.
    bool *visited = calloc(n, sizeof(bool));
    
    // Set ant on start node.
    int start = k % n + 1;
    tour.route[0]  = start;
    visited[start - 1] = true;
    
    // Do transition with probability.
    int from = start;
    for (int i = 1; i < n; i++) { // node loop
        int to = nextNodeNumber(visited, from, n, a, b, P, A);
        tour.distance += A[(from - 1) * n + (to - 1)];
        tour.route[i] =  to;
        visited[to - 1] = true;
        from = to;
    }
    // Go back to the start node.
    tour.distance += A[(from - 1) * n + (start - 1)];
    tour.route[n] =  start;
    
    free(visited);
    
    return tour;
};

bool takeBetterTour(Tour canditateTour, Tour *bestSoFarTour_p)
{
    if (canditateTour.distance < bestSoFarTour_p->distance) {
        free(bestSoFarTour_p->route);
        *bestSoFarTour_p = canditateTour;
        return true;
    } else {
        free(canditateTour.route);
        return false;
    }
}

void evaporatePheromone(double r, int n, double *P)
{
    // Pheromone evaporation
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            P[i * n + j] *= (1.0 - r);
        }
    }
}

void depositPheromone(Tour tour, int n, double *P)
{
    double pheromone = 1.0 / tour.distance;
    for (int i = 0; i < n; i++) {
        int from = tour.route[i];
        int to   = tour.route[i + 1];
        P[(from - 1) * n + (to - 1)] += pheromone;
    }
}

- (Tour)tourByASWithNumberOfAnt:(int)m
             pheromoneInfluence:(int)a
            transitionInfluence:(int)b
           pheromoneEvaporation:(double)r
                           seed:(unsigned int)seed
                 noImproveLimit:(int)limit
                   CSVLogString:(NSString *__autoreleasing *)log
{
    srand(seed);
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Initialize pheromone with average tour distance.
    int	totalDistance = 0;
    for (int i = 0; i < n; i++) {
        Tour aTour = [self tourByNNFrom:i + 1];
        totalDistance += aTour.distance;
        free(aTour.route);
    }
    double averageDistance  = (double)totalDistance / n;
    double initialPheromone = m / averageDistance;
    initializePheromone(initialPheromone, n, P);
    
    // Generate solutions.
    Tour globalBest      = {INT32_MAX, calloc(n + 1, sizeof(int))};
    int  noImproveCount  = 0;
    int  loop            = 0;
    NSMutableString *csv = [@"LOOP, DISTANCE\n" mutableCopy];
    while (noImproveCount < limit) { // improve loop
        loop++;
        
        // Do ant tours.
        Tour tours[m];
        for (int k = 0; k < m; k++) {
            tours[k] = antTour(k, n, A, P, a, b);
        }
        
        // Update pheromone
        evaporatePheromone(r, n, P);
        for (int k = 0; k < m; k++) {
            depositPheromone(tours[k], n, P);
        }
        
        // Find iteration best tour.
        Tour iterationBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
        for (int k = 0; k < m; k++) {
            takeBetterTour(tours[k], &iterationBest);
        }
        
        // Update global best tour.
        if (takeBetterTour(iterationBest, &globalBest)) {
            noImproveCount = 0;
        } else {
            noImproveCount++;
        }

        [csv appendFormat:@"%d, %d\n", loop, globalBest.distance];
    }
    
    // Export iteration best tour distances in CSV format.
    if (log) {
        *log = csv;
    }
    
    return globalBest;
}

void limitPheromoneRange(int opt, double r, int n, double pB, double *P)
{
    // Update max and min of pheromone.
    double max = 1.0 / (r * opt);
    double min = ((1 - pow(pB, 1.0 / n)) / (n / 2.0 * pow(pB, 1.0 / n))) * max;
    
    // Fix pheromone amount between min and max.
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (P[i * n + j] < min) {
                P[i * n + j] = min;
            } else if (P[i * n + j] > max) {
                P[i * n + j] = max;
            }
        }
    }
}

- (Tour)tourByMMASWithNumberOfAnt:(int)m
               pheromoneInfluence:(int)a
              transitionInfluence:(int)b
             pheromoneEvaporation:(double)r
                  probabilityBest:(double)pB
                             seed:(unsigned int)seed
                   noImproveLimit:(int)limit
                     CSVLogString:(NSString *__autoreleasing *)log
{
    srand(seed);
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Compute initial best tour by NN.
    Tour initialBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
    for (int i = 0; i < n; i++) {
        Tour aTour = [self tourByNNFrom:i + 1];
        takeBetterTour(aTour, &initialBest);
    }

    // Initialize pheromone with max pheromone.
    double pheromoneMax = 1.0 / (r * initialBest.distance);
    initializePheromone(pheromoneMax, n, P);
    free(initialBest.route);
    
    // Generate solutions.
    Tour globalBest      = {INT32_MAX, calloc(n + 1, sizeof(int))};
    int  noImproveCount  = 0;
    int  loop            = 0;
    NSMutableString *csv = [@"LOOP, DISTANCE\n" mutableCopy];
    while (noImproveCount < limit) {
        
        // Do ant tours.
        Tour tours[m];
        for (int k = 0; k < m; k++) {
            tours[k] = antTour(k, n, A, P, a, b);
        }
        
        // Find iteration best tour.
        Tour iterationBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
        for (int k = 0; k < m; k++) {
            takeBetterTour(tours[k], &iterationBest);
        }
        
        // Update global best tour.
        if (takeBetterTour(iterationBest, &globalBest)) {
            noImproveCount = 0;
        } else {
            noImproveCount++;
        }

        [csv appendFormat:@"%d, %d\n", ++loop, globalBest.distance];
        
        // Update pheromone
        evaporatePheromone(r, n, P);
        depositPheromone(globalBest, n, P);
        limitPheromoneRange(globalBest.distance, r, n, pB, P);
    }
    
    // Export iteration best tour distances in CSV format.
    if (log) {
        *log = csv;
    }
    
    return globalBest;
}

- (Tour)tourByMMAS2optWithNumberOfAnt:(int)m
                   pheromoneInfluence:(int)a
                  transitionInfluence:(int)b
                 pheromoneEvaporation:(double)r
                      probabilityBest:(double)pB
                                 seed:(unsigned int)seed
                       noImproveLimit:(int)limit
                         CSVLogString:(NSString *__autoreleasing *)log
{
    srand(seed);
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Compute initial best tour by NN.
    Tour initialBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
    for (int i = 0; i < n; i++) {
        Tour aTour = [self tourByNNFrom:i + 1];
        takeBetterTour(aTour, &initialBest);
    }
    
    // Initialize pheromone with max pheromone.
    double initialPheromone = 1.0 / (r * initialBest.distance);
    initializePheromone(initialPheromone, n, P);
    free(initialBest.route);
    
    // Generate solutions.
    Tour globalBest      = {INT32_MAX, calloc(n + 1, sizeof(int))};
    int  noImproveCount  = 0;
    int  loop            = 0;
    NSMutableString *csv = [@"LOOP, DISTANCE\n" mutableCopy];
    while (noImproveCount < limit) {

        // Do ant tours.
        Tour tours[m];
        for (int k = 0; k < m; k++) {
            tours[k] = antTour(k, n, A, P, a, b);

            // Improve using 2-opt
            [self improveTourBy2opt:&(tours[k])];
        }
        
        // Find iteration best tour.
        Tour iterationBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
        for (int k = 0; k < m; k++) {
            takeBetterTour(tours[k], &iterationBest);
        }
        
        // Update global best tour.
        if (takeBetterTour(iterationBest, &globalBest)) {
            noImproveCount = 0;
        } else {
            noImproveCount++;
        }
        [csv appendFormat:@"%d, %d\n", ++loop, globalBest.distance];
        
        // Update pheromone
        evaporatePheromone(r, n, P);
        depositPheromone(globalBest, n, P);
        limitPheromoneRange(globalBest.distance, r, n, pB, P);
    }
    
    // Export iteration best tour distances in CSV format.
    if (log) {
        *log = csv;
    }
    
    printf("globalBest.distance = %d\n", globalBest.distance);
    
    return globalBest;
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
	if (N != NULL) {
		printf("\n========== NODE COORDINATIONS ==========\n");
		for (int i = 0; i < n; i++) {
			printf("%5d: (%10.2f, %10.2f)\n", self.nodes[i].number, self.nodes[i].coord.x, self.nodes[i].coord.y);
		}
	}
}

- (void)printAdjecencyMatrix
{
	printf("\n========== WEIGHTED ADJECENCY MATRIX ==========\n");
	printf("      ");
	for (int i = 0; i < n; i++) {
		printf("%4d ", i + 1);
	}
	printf("\n");
	
	for (int i = 0; i < n; i++) {
		printf("%4d: ", i + 1);
		for (int j = 0; j < n; j++) {
			printf("%4d ", self.adjacencyMatrix[i * n + j]);
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
	if (N)  free(N);
	if (A)	free(A);
}

@end