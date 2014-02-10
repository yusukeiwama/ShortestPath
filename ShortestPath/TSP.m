//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "TSP.h"
#import "USKTrimmer.h"
#import "ViewController.h"

typedef struct _Neighbor {
	int	number;
	int distance;
} Neighbor;

int euclid_edgelen(Coordinate P, Coordinate Q)
{
	double dx = Q.x - P.x;
	double dy = Q.y - P.y;
	return (int)(sqrt(dx * dx + dy * dy) + 0.5);
}

// FIXME: something wrong...
int geo(Coordinate P, Coordinate Q)
{
    double PI = 3.141592;
    
    int deg, min;
    Coordinate geoP, geoQ;
    
    deg = P.x + 0.5;
    min = P.x - deg;
    geoP.x = PI * (deg + 5.0 * min / 3.0) / 180.0;
    
    deg = P.y + 0.5;
    min = P.y - deg;
    geoP.y = PI * (deg + 5.0 * min / 3.0) / 180.0;

    deg = Q.x + 0.5;
    min = Q.x - deg;
    geoQ.x = PI * (deg + 5.0 * min / 3.0) / 180.0;
    
    deg = Q.y + 0.5;
    min = Q.y - deg;
    geoQ.y = PI * (deg + 5.0 * min / 3.0) / 180.0;

//    geoP.x = M_PI * P.x / 180.0;
//    geoP.y = M_PI * P.y / 180.0;
//    geoQ.x = M_PI * Q.x / 180.0;
//    geoQ.y = M_PI * Q.y / 180.0;
    
    double q1 = cos(geoP.y - geoQ.y);
    double q2 = cos(geoP.x - geoQ.x);
    double q3 = cos(geoP.x + geoQ.x);
    
    double RRR = 6378.388;

    return (int)(RRR * acos (0.5 * ((1.0 + q1) * q2 - (1.0 - q1) * q3)) + 1.0);
    
//    double q1 = cos (geoQ.x) * sin(geoP.y - geoQ.y);
//    double q3 = sin((geoP.y - geoQ.y)/2.0);
//    double q4 = cos((geoP.y - geoQ.y)/2.0);
//    double q2 = sin(geoP.x + geoQ.x) * q3 * q3 - sin(geoP.x - geoQ.x) * q4 * q4;
//    double q5 = cos(geoP.x - geoQ.x) * q4 * q4 - cos(geoP.x + geoQ.x) * q3 * q3;
//    return (int) (RRR * atan2(sqrt(q1*q1 + q2*q2), q5) + 1.0);
}

int euclid_ceiling_edgelen(Coordinate P, Coordinate Q)
{
	double dx = Q.x - P.x;
	double dy = Q.y - P.y;
    return (int)ceil((sqrt(dx * dx + dy * dy)));
}

static int att_edgelen (Coordinate P, Coordinate Q)
{
    double dx = Q.x - P.x;
    double dy = Q.y - P.y;
    double rij = sqrt ((dx * dx + dy * dy) / 10.0);
    double tij = (double)(int)rij;
    int dij;
    
    if (tij < rij)
        dij = (int) tij + 1;
    else
        dij = (int) tij;
    return dij;
}

int compareDistances(const Neighbor *n1, const Neighbor *n2)
{
	return n1->distance - n2->distance;
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

@implementation TSP

@synthesize dimension       = n;
@synthesize nodes           = N;
@synthesize adjacencyMatrix = A;
@synthesize neighborMatrix  = NN;
// P means pheromone matrix.

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
            [self prepareQueues];
            Tour tour = [TSP optimalSolutionWithName:_information[@"NAME"]];
            if (tour.distance > 0 && [_information[@"EDGE_WEIGHT_TYPE"] isEqualToString:@"GEO"] == NO) {
                [_information setValue:[NSNumber numberWithInt:tour.distance] forKey:@"OPTIMAL_LENGTH"];
                _optimalTour = tour;
            } else { // distance is -1, if not available.
                [_information setValue:@"N/A" forKey:@"OPTIMAL_LENGTH"];
                _optimalTour.distance = OPTIMAL_TOUR_NOT_AVAILABLE;
                _optimalTour.route = NULL;
            }
            
//			[self printInformation];
//            [self printNodes];
//			[self printAdjecencyMatrix];
//            [self printNeighborMatrix];
		}
	}
        
	return self;
}

+ (id)randomTSPWithDimension:(int)dimension seed:(unsigned int)seed
{
    if (dimension > MAX_DIMENSION) {
        dimension = MAX_DIMENSION;
    } else if (dimension < 3) {
        return nil;
    }
	return [[TSP alloc] initRandomTSPWithDimension:dimension seed:seed];
}

- (id)initRandomTSPWithDimension:(int)dimension seed:(unsigned int)seed
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
        [self computeNeighborMatrix];
        [self prepareQueues];
	}
	return self;
}

#pragma mark - Queue management

-(void)prepareQueues
{
    self.operationQueue = [NSOperationQueue new];
    self.logQueue    = [USKQueue queueWithCapacity:50000];
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
		} else if ([lines[l] rangeOfString:@"EDGE_WEIGHT_SECTION"].location != NSNotFound) { // Found
			l++;
			// Read adjacency matrix.
			A = calloc(n * n, sizeof(int));
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
	Tour optimalPath = {OPTIMAL_TOUR_NOT_AVAILABLE, NULL};
	
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
				optimalPath.route = calloc(dimension + 1, sizeof(int));
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
                // Go back to the first node. (cycle's end node is the same as start node.)
                [path addObject:path[0]];
				// Set optimal path.
				optimalPath.route = [TSP intArrayFromArray:path];
			}
			l++;
		}
	}
    // Set optimal distance to OPTIMAL_TOUR_NOT_AVAILABLE even if it has optimal distance because it can't visualize a tour route.
//    if (optimalPath.route == NULL) {
//        optimalPath.distance = OPTIMAL_TOUR_NOT_AVAILABLE;
//    }

	return optimalPath;
}

#pragma mark - compute matrix

- (void)computeAdjacencyMatrix
{
	if (A == NULL) {
		A = calloc(n * n, sizeof(int));
		for (int i = 0; i < n; i++) {
			for (int j = 0; j < n; j++) {
                if ([self.information[@"EDGE_WEIGHT_TYPE"] isEqualToString:@"GEO"]) {
                    A[i * n + j] = geo(N[i].coord, N[j].coord);
                } else if ([self.information[@"EDGE_WEIGHT_TYPE"] isEqualToString:@"ATT"]) {
                    A[i * n + j] = att_edgelen(N[i].coord, N[j].coord);
                } else if ([self.information[@"EDGE_WEIGHT_TYPE"] isEqualToString:@"CEIL_2D"]) {
                    A[i * n + j] = euclid_ceiling_edgelen(N[i].coord, N[j].coord);
                } else if ([self.information[@"EDGE_WEIGHT_TYPE"] isEqualToString:@"EXPLICIT"]) {
                    // Already read from file.
                    printf("ex");
                } else { // EUC2D
                    A[i * n + j] = euclid_edgelen(N[i].coord, N[j].coord);
                }
			}
		}
	}
}

- (void)computeNeighborMatrix
{
	if (NN == NULL) {
		NN = calloc(n * n, sizeof(Neighbor));
		[self computeAdjacencyMatrix];
		
		for (int i = 0; i < n; i++) {
			for (int j = 0; j < n; j++) {
				// Copy adjacency matrix.
				NN[i * n + j].number   = j + 1;
				NN[i * n + j].distance = A[i * n + j];
			}
			
			// Ignore i == j element because the element is not a neighbor but itself.
			NN[i * n + i] = NN[i * n + n - 1];
			
			// Sort neighbors by distance, ignoring i == j element.
			qsort(&(NN[n * i + 0]), n - 1, sizeof(Neighbor), (int(*)(const void *, const void *))compareDistances);
		}
	}
}

#pragma mark - Algorithms
/*
 For performance reason, NN is computed in advance.
 i.e. pr2392 NN:1.7sec A:68sec
 */
int nearestNodeNumber(bool *visited, int from, int n, Neighbor *NN)
{
    int i = 0;
    int nearest;
    
    // Look up unvisited nearest node from NN matrix.
    do {
        nearest = NN[(from - 1) * n + i++].number;
    } while (visited[nearest - 1]);
    
    return nearest;
}

- (Tour)tourByNNFrom:(int)start use2opt:(BOOL)use2opt
{
    if (self.client.currentSolverType == TSPSolverTypeNN) {
        [self.logQueue enqueue:@{@"Log": [NSString stringWithFormat:@"The nearest neighbor algorithm began.\nRoute: %d ", start]}];
    }
    
    Tour tour     = {0, calloc(n + 1, sizeof(int))};
    bool *visited = calloc(n, sizeof(bool));
    
    tour.route[0]      = start;
    visited[start - 1] = true;
    
    int from = start;
    for (int i = 1; i < n; i++) {
        // Look up the nearest node number.
        int to = nearestNodeNumber(visited, from, n, NN);
        tour.distance   += A[(from - 1) * n + (to - 1)];
        tour.route[i]   =  to;
        visited[to - 1] =  true;
        from = to;
        if (self.client.currentSolverType == TSPSolverTypeNN) {
            // Copy current tour
            Tour *tourLog_p  = calloc(1,     sizeof(Tour));
            tourLog_p->route = calloc(n + 1, sizeof(int));
            tourLog_p->distance = tour.distance;
            memcpy(tourLog_p->route, tour.route, (n + 1) * sizeof(int));
            [self.logQueue enqueue:@{@"Log":  [NSString stringWithFormat:@"%d ", to],
                                     @"Tour": [NSValue valueWithPointer:tourLog_p]}];
        }
    }
    free(visited);
    // Go back to the start node.
    tour.distance += A[(from - 1) * n + (start - 1)];
    tour.route[n] =  start;

    // Enqueue log.
    if (self.client.currentSolverType == TSPSolverTypeNN) {
        // Copy current tour
        Tour *tourLog_p  = calloc(1,     sizeof(Tour));
        tourLog_p->route = calloc(n + 1, sizeof(int));
        tourLog_p->distance = tour.distance;
        memcpy(tourLog_p->route, tour.route, (n + 1) * sizeof(int));
        NSString *resultString = @"";
        if (self.optimalTour.distance > 0) {
            resultString = [NSString stringWithFormat:@"(%+5.2f%% from optimal: %d)", tour.distance * 100.0 / self.optimalTour.distance - 100.0, self.optimalTour.distance];
        }
        [self.logQueue enqueue:@{@"Log":  [NSString stringWithFormat:@"%d \nDistance: %d%@\n\n", start, tour.distance, resultString],
                                 @"Tour": [NSValue valueWithPointer:tourLog_p]}];
    }
    
    if (use2opt) {
        [self improveTourBy2opt:&tour];
        
        // Enqueue log.
        if (self.client.currentSolverType == TSPSolverTypeNN) {
            NSMutableString *routeString = [NSMutableString string];
            for (int i = 0; i <= n; i++) {
                [routeString appendFormat:@" %d", tour.route[i]];
            }
            // Copy tour
            Tour *tourLog_p  = calloc(1,     sizeof(Tour));
            tourLog_p->route = calloc(n + 1, sizeof(int));
            tourLog_p->distance = tour.distance;
            memcpy(tourLog_p->route, tour.route, (n + 1) * sizeof(int));
            NSString *resultString = @"";
            if (self.optimalTour.distance > 0) {
                resultString = [NSString stringWithFormat:@"(%+5.2f%% from optimal: %d)", tour.distance * 100.0 / self.optimalTour.distance - 100.0, self.optimalTour.distance];
            }
            [self.logQueue enqueue:@{@"Log": [NSString stringWithFormat:@"Improved route:%@\nDistance: %d%@\n\n", routeString, tour.distance, resultString],
                                     @"Tour": [NSValue valueWithPointer:tourLog_p]}];
        }
    }
    
    return tour;
}

- (void)improveTourBy2opt:(Tour *)tour_p
{
    // Enqueue log.
    if (self.client.currentSolverType == TSPSolverTypeNN) {
        [self.logQueue enqueue:@{@"Log": @"2-opt algorithm began.\n"}];
    }
    
    // O(n^3)
	bool improved = true;
	while (improved) {
		improved = false;
		for (int i = 0; i < n - 1; i++) {
			for (int j = i + 1; j < n ; j++) {
				int newLength = length2opt(tour_p, A, n, i, j);
				if (newLength < tour_p->distance) {
					swap2opt(tour_p->route, n, i, j);
					tour_p->distance = newLength;
					improved = true;
                    // Enqueue log.
                    if (self.client.currentSolverType == TSPSolverTypeNN) {
                        // Copy tour
                        Tour *tourLog_p  = calloc(1,     sizeof(Tour));
                        tourLog_p->route = calloc(n + 1, sizeof(int));
                        tourLog_p->distance = tour_p->distance;
                        memcpy(tourLog_p->route, tour_p->route, (n + 1) * sizeof(int));
                        [self.logQueue enqueue:@{@"Log": [NSString stringWithFormat:@"Reverse order between %d and %d.\n", tour_p->route[j], tour_p->route[i+1]],
                                                 @"Tour": [NSValue valueWithPointer:tourLog_p]}];
                    }
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

double pheromoneWeight(int from, int to, int n, int a, int b, double *P, int *A)
{
    return iPow(P[(from - 1) * n + (to - 1)], a) * iPow(1.0 / A[(from - 1) * n + (to - 1)], b);
}

int nextNodeNumber(bool *visited, int from, int n, int a, int b, double *P, int *A, Neighbor *NN, int numCandidates)
{
    if (numCandidates > n) {
        numCandidates = n; // Correspontds to solving without Candidate List
    } else if (numCandidates < 1) {
        return nearestNodeNumber(visited, from, n, NN); // Same as NN
    }
    
    /*
     When using Candidate List, there are 4 case.
     case 1: Intersection is empty and pheromone exist => select the unused edge which has the most pheromone weight.
     case 2: Intersection is empty and no pheromone => select node randomly from all unvisited nodes.
     case 3: Intersection is not empty and no pheromone => select node randomly from intersection.
     case 4: Intersection is not empty and pheromone exist => select node with probability from intersection.
     */
    
    // Get candidate list and the number of elements in intersection.
    int candidates[numCandidates];
    int numberOfElementsInIntersection = 0;
    for (int i = 0; i < numCandidates; i++) {
        candidates[i] = NN[(from - 1) * n + i].number;
        if (visited[candidates[i] - 1] == false) {
            numberOfElementsInIntersection++;
        }
    }
    
    if (numberOfElementsInIntersection == 0) { // Intersection is empty.
        // case 1: select the unused edge which has the most pheromone weight.
        // Find the node to which the edge has the most pheromone weight.
        double maxWeight = DBL_MIN;
        int maxWeightNodeNumber = 0;
        for (int i = 0; i < n; i++) {
            int to = i + 1;
            if (visited[to - 1] == false) {
                double aWeight = pheromoneWeight(from, to, n, a, b, P, A);
                if (aWeight > maxWeight) {
                    maxWeight = aWeight;
                    maxWeightNodeNumber = i + 1;
                }
            }
        }
        if (maxWeightNodeNumber != 0) {
            return maxWeightNodeNumber;
        }
        
        // No intersection and no pheromone.
        // case 2: select node randomly from all unvisited nodes.
        int numberOfUnvisitedNodes = 0;
        for (int i = 0; i < n; i++) {
            if (visited[i] == false) {
                numberOfUnvisitedNodes++;
            }
        }
        int targetOrder = numberOfUnvisitedNodes * (double)rand() / (RAND_MAX + 1.0) + 1;
        int order = 0;
        int targetNodeNumber = 1;
        while (order != targetOrder) {
            if (visited[targetNodeNumber - 1] == false) {
                order++;
            }
            targetNodeNumber++;
        }
        targetNodeNumber--;
        return targetNodeNumber;
        
    } else { // Intersection exists.
        // Get intersection.
        int intersectionIndex = 0;
        int intersection[numberOfElementsInIntersection];
        bzero(intersection, numberOfElementsInIntersection * sizeof(int));
        for (int i = 0; i < numCandidates; i++) {
            if (visited[candidates[i] - 1] == false) {
                intersection[intersectionIndex++] = candidates[i];
            }
        }
        
        // Compute sum weight of intersection.
        double sumWeight = 0.0;
        for (int i = 0; i < numberOfElementsInIntersection; i++) {
            sumWeight += pheromoneWeight(from, intersection[i], n, a, b, P, A);
        }
        
        if (sumWeight < DBL_MIN) { // No pheromone.
            // case 3: select node randomly from intersection.
            int targetIndex = numberOfElementsInIntersection * (double)rand() / (RAND_MAX + 1.0);
            return intersection[targetIndex];
            
        } else { // Pheromone exist.
            // case 4: select with probability from intersection.
            double targetWeight = sumWeight * (double)rand() / (RAND_MAX + 1.0);
            double weight = 0.0;
            int targetIndex = 0;
            while (weight < targetWeight) {
                weight += pheromoneWeight(from, intersection[targetIndex++], n, a, b, P, A);
            }
            targetIndex--;
            return intersection[targetIndex];
        }
        
    }
}

Tour antTour(int k, int n, int *A, Neighbor *NN, double *P, int a, int b, int c)
{
    // Initialize a tour.
    Tour tour = {0, calloc(n + 1, sizeof(int))};
    
    // visited[i] is true when node numbered i+1 was visited.
    bool *visited = calloc(n, sizeof(bool));
    
    // Set ant on start node.
    int start = k % n + 1;
    tour.route[0]  = start;
    visited[start - 1] = true;
    
    // Do transition with probability. O(n^2)
    int from = start;
    for (int i = 1; i < n; i++) { // node loop
        int to = nextNodeNumber(visited, from, n, a, b, P, A, NN, c);
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

bool takeBetterTour(Tour candidateTour, Tour *bestSoFarTour_p)
{
    if (candidateTour.distance < bestSoFarTour_p->distance) {
        free(bestSoFarTour_p->route);
        *bestSoFarTour_p = candidateTour;
        return true;
    } else {
        free(candidateTour.route);
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
        // pheromone matrix has to be symmetry in symmetry TSP.
        P[(to - 1) * n + (from - 1)] += pheromone;
    }
}

- (Tour)tourByASWithNumberOfAnt:(int)m
             pheromoneInfluence:(int)alpha
            transitionInfluence:(int)beta
           pheromoneEvaporation:(double)rho
                           seed:(unsigned int)seed
                 noImproveLimit:(int)limit
                   maxIteration:(int)maxIteration
              candidateListSize:(int)numCandidates
                        use2opt:(BOOL)use2opt
                   CSVLogString:(NSString *__autoreleasing *)log

{
    if (self.client.currentSolverType == TSPSolverTypeAS) {
        [self.logQueue enqueue:@{@"Log": @"Ant System algorism began.\n"}];
    }
    
    srand(seed);
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Initialize pheromone with average tour distance.
    int	totalDistance = 0;
    int initialLoop = (n > m) ? m : n; // set initial loop count to m. if m is larger than n, then use n.
    for (int i = 0; i < initialLoop; i++) {
        Tour aTour = [self tourByNNFrom:i + 1 use2opt:use2opt];
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
    Tour *tours = calloc(m, sizeof(Tour));
    while (
           noImproveCount < limit
           && loop < maxIteration
           && self.aborted == NO
           && globalBest.distance != self.optimalTour.distance
           ) { // improve loop
        
        NSMutableDictionary *logsForThisLoop = [NSMutableDictionary dictionary];
        
        // Do ant tours concurrently. O(m * n^2)
        dispatch_apply(m, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t k){
            [self.operationQueue addOperationWithBlock:^{
                tours[k] = antTour((int)k, n, A, NN, P, alpha, beta, numCandidates);
                if (use2opt) {
                    [self improveTourBy2opt:&(tours[k])];
                }
            }];
        });
        [self.operationQueue waitUntilAllOperationsAreFinished];
        
        // Update pheromone O(m * n^2)
        evaporatePheromone(rho, n, P);
        for (int k = 0; k < m; k++) {
            depositPheromone(tours[k], n, P);
        }
        
        // Enqueue pheromone matrix.
        if (self.client.currentSolverType == TSPSolverTypeAS) {
            // Copy upper triangle matrix of current pheromone.
            double *PLog = calloc(n * (n - 1) / 2, sizeof(double));
            int p = 0;
            for (int i = 0; i < n; i++) {
                for (int j = i + 1; j < n; j++) {
                    PLog[p++] = P[i * n + j];
                }
            }
            [logsForThisLoop addEntriesFromDictionary:@{@"Pheromone": [NSValue valueWithPointer:PLog]}];
        }
        
        // Find iteration best tour.
        Tour iterationBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
        for (int k = 0; k < m; k++) {
            takeBetterTour(tours[k], &iterationBest);
        }
        
        // Update global best tour.
        if (takeBetterTour(iterationBest, &globalBest)) {
            noImproveCount = 0;
            // Enqueue tour log.
            if (self.client.currentSolverType == TSPSolverTypeAS) {
                // Copy global best.
                Tour *tourLog_p     = calloc(1, sizeof(Tour));
                tourLog_p->route    = calloc(n + 1, sizeof(int));
                tourLog_p->distance = globalBest.distance;
                for (int i = 0; i <= n; i++) {
                    tourLog_p->route[i] = globalBest.route[i];
                }
                [logsForThisLoop addEntriesFromDictionary:@{@"Log": [NSString stringWithFormat:@"New global best distance: %d.\n", tourLog_p->distance],
                                                            @"Tour": [NSValue valueWithPointer:tourLog_p]}];
            }
        } else {
            noImproveCount++;
        }

        [self.logQueue enqueue:logsForThisLoop];
        [csv appendFormat:@"%d, %d\n", loop, globalBest.distance];

        loop++;
    }
    free(tours);
    
    // Export iteration best tour distance history in CSV format.
    if (log) {
        *log = csv;
    }
    if (self.client.currentSolverType == TSPSolverTypeAS) {
        // Enqueue special log if optimal solution is found.
        if (globalBest.distance == self.optimalTour.distance) {
            [self.logQueue enqueue:@{@"Log": @"Found optimal solution!\n"}];
        }
        
        NSMutableString *routeString = [NSMutableString string];
        for (int i = 0; i <= n; i++) {
            [routeString appendFormat:@" %d", globalBest.route[i]];
        }
        NSString *resultString = @"";
        if (self.optimalTour.distance > 0) {
            resultString = [NSString stringWithFormat:@"(%+5.2f%% from optimal: %d)", globalBest.distance * 100.0 / self.optimalTour.distance - 100.0, self.optimalTour.distance];
        }
        [self.logQueue enqueue:@{@"Log": [NSString stringWithFormat:@"Best route: %@\nDistance: %d%@\nNumber of loops: %d\n\n", routeString, globalBest.distance, resultString, loop]}];
    }
    
    return globalBest;
}

void limitPheromoneRange(int opt, double rho, int n, double pBest, double *P)
{
    // Update max and min of pheromone.
    double max = 1.0 / (rho * opt);
    double min = ((1.0 - pow(pBest, 1.0 / n)) / ((n / 2.0 - 1.0) * pow(pBest, 1.0 / n))) * max;
    
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

bool pheromoneTrailSmoothing(double delta, int opt, double rho, int n, double *P)
{
    if (delta == 0) {
        return NO;
    }
    /*
     Pheromone matrix element on first loop after initialization always have only two possible values
     because there is only a iteration best tour and all the rest are not.
     So, its average number of pheromone-rich nodes is always just 2.
    */
    static BOOL isFirstLoopAfterInitialization = YES;
    if (isFirstLoopAfterInitialization) {
        isFirstLoopAfterInitialization = NO;
        return NO;
    }

    // Set the threshold for smoothing.
    double lambda = 2.04;
    
    // Compute average number of pheromone-rich edge.
    double averageNumRichEdge = 0.0;
    double max = DBL_MIN;
    double min = DBL_MAX;
    for (int i = 0; i < n; i++) { // for all nodes
        // Find max and min pheromone from node i+1 to node j+1.
        for (int j = 0; j < n; j++) { // for all j+1 destination nodes
            if (i == j) {
                continue;
            }
            if (P[i * n + j] > max) {
                max = P[i * n + j];
            }
            if (P[i * n + j] < min) {
                min = P[i * n + j];
            }
        }
        // Count the number of edges that has enough pheromone.
        int numRichEdge = 0;
        for (int j = 0; j < n; j++) {
            if (P[i * n + j] >= min + 0.05 * (max - min)) numRichEdge++;
        }
        averageNumRichEdge += numRichEdge;
    }
    averageNumRichEdge /= n;

    // If pheromone trail is convergent, smooth it.
    if (averageNumRichEdge < lambda) {
        isFirstLoopAfterInitialization = YES;
        double globalMaxPheromone = 1 / (opt * rho);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                P[i * n + j] = P[i * n + j] + delta * (globalMaxPheromone - P[i * n + j]);
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (Tour)tourByMMASWithNumberOfAnt:(int)m
               pheromoneInfluence:(int)alpha
              transitionInfluence:(int)beta
             pheromoneEvaporation:(double)rho
                  probabilityBest:(double)pBest
                   takeGlogalBest:(BOOL)takeGlobalBest
                             seed:(unsigned int)seed
                   noImproveLimit:(int)limit
                     maxIteration:(int)maxIteration
                candidateListSize:(int)numCandidates
                          use2opt:(BOOL)use2opt
                        smoothing:(double)delta
                     CSVLogString:(NSString *__autoreleasing *)log
{
    if (self.client.currentSolverType == TSPSolverTypeMMAS) {
        [self.logQueue enqueue:@{@"Log": @"Max-Min Ant System algorism began.\n"}];
    }
    
    srand(seed);
    
    if (numCandidates > n) {
        numCandidates = n;
    }
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Compute initial best tour by NN.
    Tour initialBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
    
    int initialLoop = (n > m) ? m : n; // set initial loop count to m. if m is larger than n, then use n.
    for (int i = 0; i < initialLoop; i++) {
        Tour aTour = [self tourByNNFrom:i + 1 use2opt:use2opt];
        takeBetterTour(aTour, &initialBest);
    }
    
    // Initialize pheromone with max pheromone.
    double initialPheromone = 1.0 / (rho * initialBest.distance);
    initializePheromone(initialPheromone, n, P);
    free(initialBest.route);
    
    // Generate solutions.
    Tour globalBest      = {INT32_MAX, calloc(n + 1, sizeof(int))};
    int  noImproveCount  = 0;
    int  loop            = 0;
    NSMutableString *csv = [@"LOOP, DISTANCE\n" mutableCopy];
//    Tour tours[m]; // Cannot refer to declaration with a variably modified type inside block.
    Tour *tours = calloc(m, sizeof(Tour));
    while (
           noImproveCount < limit
           && loop < maxIteration
           && self.aborted == NO
           && globalBest.distance != self.optimalTour.distance
           ) {
        
        NSMutableDictionary *logsForThisLoop = [NSMutableDictionary dictionary];
        NSMutableString *logStringForThisLoop = [NSMutableString string];
        
        // Do ant tours concurrently. O(n^2)
        dispatch_apply(m, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t k){
            [self.operationQueue addOperationWithBlock:^{
                tours[k] = antTour((int)k, n, A, NN, P, alpha, beta, numCandidates); // O(n^2)
                if (use2opt) {
                    [self improveTourBy2opt:&(tours[k])]; // O(n^2)
                }
            }];
        });
        [self.operationQueue waitUntilAllOperationsAreFinished];
        
        // Find iteration best tour.
        Tour iterationBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
        for (int k = 0; k < m; k++) {
            takeBetterTour(tours[k], &iterationBest);
        }
        
        if (takeGlobalBest == NO) {
            // Update pheromone with iteration best
            evaporatePheromone(rho, n, P);
            depositPheromone(iterationBest, n, P);
            limitPheromoneRange(iterationBest.distance, rho, n, pBest, P);
        }
        
        // Update global best tour.
        if (takeBetterTour(iterationBest, &globalBest)) {
            noImproveCount = 0;
            // Enqueue tour log.
            if (self.client.currentSolverType == TSPSolverTypeMMAS) {
                // Copy global best.
                Tour *tourLog_p     = calloc(1,     sizeof(Tour));
                tourLog_p->route    = calloc(n + 1, sizeof(int));
                tourLog_p->distance = globalBest.distance;
                memcpy(tourLog_p->route, globalBest.route, (n + 1) * sizeof(int));
                [logStringForThisLoop appendFormat:@"New global best distance: %d.\n", tourLog_p->distance];
                [logsForThisLoop addEntriesFromDictionary:@{@"Tour": [NSValue valueWithPointer:tourLog_p]}];
            }
        } else {
            noImproveCount++;
        }
        
        if (takeGlobalBest) {
            // Update pheromone
            evaporatePheromone(rho, n, P);
            depositPheromone(globalBest, n, P);
            limitPheromoneRange(globalBest.distance, rho, n, pBest, P);
        }
        
        if (pheromoneTrailSmoothing(delta, globalBest.distance, rho, n, P)) { // O(n^2)
            [logStringForThisLoop appendFormat:@"Did pheromone trail smoothing.\n"];
        }
        
        // Get pheromone log.
        if (self.client.currentSolverType == TSPSolverTypeMMAS) {
            // Copy upper triangle matrix of current pheromone.
            double *PLog = calloc(n * (n - 1) / 2, sizeof(double));
            int p = 0;
            for (int i = 0; i < n; i++) {
                for (int j = i + 1; j < n; j++) {
                    PLog[p++] = P[i * n + j];
                }
            }
            [logsForThisLoop addEntriesFromDictionary:@{@"Pheromone": [NSValue valueWithPointer:PLog]}];
        }
        
        // Enqueue logs.
        [logsForThisLoop addEntriesFromDictionary:@{@"Log": logStringForThisLoop}];
        [self.logQueue enqueue:logsForThisLoop];
        [csv appendFormat:@"%d, %d\n", loop, globalBest.distance];

        loop++;
    }
    free(tours);
    
    // Export iteration best tour distances in CSV format.
    if (log) {
        *log = csv;
    }
    if (self.client.currentSolverType == TSPSolverTypeMMAS) {
        // Enqueue special log if optimal solution is found.
        if (globalBest.distance == self.optimalTour.distance) {
            [self.logQueue enqueue:@{@"Log": @"Found optimal solution!\n"}];
        }
        
        NSMutableString *routeString = [NSMutableString string];
        for (int i = 0; i <= n; i++) {
            [routeString appendFormat:@" %d", globalBest.route[i]];
        }
        NSString *resultString = @"";
        if (self.optimalTour.distance > 0) {
            resultString = [NSString stringWithFormat:@"(%+5.2f%% from optimal: %d)", globalBest.distance * 100.0 / self.optimalTour.distance - 100.0, self.optimalTour.distance];
        }
        [self.logQueue enqueue:@{@"Log": [NSString stringWithFormat:@"Best route: %@\nDistance: %d%@\nNumber of loops: %d\n\n", routeString, globalBest.distance, resultString, loop]}];
    }
    
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
	printf("\n=============== TSP INFORMATION ================\n");
    printf("%s: %s\n", "NAME", [[self.information objectForKey:@"NAME"] cStringUsingEncoding:NSUTF8StringEncoding]);
	[self.information enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        if ([key isEqualToString:@"NAME"] == NO) {
            printf("%s: %s\n", [key cStringUsingEncoding:NSUTF8StringEncoding], [obj cStringUsingEncoding:NSUTF8StringEncoding]);
        }
	}];
}

- (NSString *)informationString
{
    NSMutableString *string = [NSMutableString string];

    [string appendString:@"========== TSP INFORMATION ==========\n"];
    [string appendString:[NSString stringWithFormat:@"%s: %s\n", "NAME", [[self.information objectForKey:@"NAME"] cStringUsingEncoding:NSUTF8StringEncoding]]];
	[self.information enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        if ([key isEqualToString:@"NAME"] == NO) {
            [string appendString:[NSString stringWithFormat:@"%@: %@\n", key, obj]];
        }
	}];
    [string appendString:@"=====================================\n\n"];

    return string;
}

- (void)printNodes
{
	if (N != NULL) {
		printf("\n============== NODE COORDINATIONS ==============\n");
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
	if (N)  free(N);
	if (A)	free(A);
    if (NN) free(NN);
}

@end