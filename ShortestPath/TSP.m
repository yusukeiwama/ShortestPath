//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "TSP.h"
#import "USKTrimmer.h"

typedef struct _Neighbor {
	int	number;
	int distance;
} Neighbor;

int euc2D(Coordinate P, Coordinate Q)
{
	double dx = Q.x - P.x;
	double dy = Q.y - P.y;
	return (int)(sqrt(dx * dx + dy * dy) + 0.5);
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
//            [self printNodes];
//			[self printAdjecencyMatrix];
//            [self printNeighborMatrix];
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
        [self computeNeighborMatrix];
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

- (void)computeNeighborMatrix
{
	if (NN == NULL) {
		NN = calloc(n * n, sizeof(Neighbor));
		[self computeAdjacencyMatrix];
		
		for (int i = 0; i < n; i++) {
			for (int j = 0; j < n; j++) {
				// Copy adjacency matrix.
				NN[i * n + j].number = j + 1;
				NN[i * n + j].distance   = A[i * n + j];
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
    Tour tour     = {0, calloc(n + 1, sizeof(int))};
    bool *visited = calloc(n, sizeof(bool));
    
    tour.route[0]      = start;
    visited[start - 1] = true;
    
    int from = start;
    for (int i = 1; i < n; i++) {
        int to = nearestNodeNumber(visited, from, n, NN);
        tour.distance   += A[(from - 1) * n + (to - 1)];
        tour.route[i]   =  to;
        visited[to - 1] =  true;
        from = to;
    }
    tour.distance += A[(from - 1) * n + (start - 1)];
    tour.route[n] =  start;
    
    if (use2opt) {
        [self improveTourBy2opt:&tour];
    }
    
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

double pheromoneWeight(int from, int to, int n, int a, int b, double *P, int *A)
{
    return iPow(P[(from - 1) * n + (to - 1)], a) * iPow(1.0 / A[(from - 1) * n + (to - 1)], b);
}

int nextNodeNumber(bool *visited, int from, int n, int a, int b, double *P, int *A, Neighbor *NN, int candidateListSize)
{
    /*
     When using Candidate List, there are 4 case.
     case 1: Intersection is empty and pheromone exist => select the unused edge which has the most pheromone weight.
     case 2: Intersection is empty and no pheromone => select node randomly from all unvisited nodes.
     case 3: Intersection is not empty and no pheromone => select node randomly from intersection.
     case 4: Intersection is not empty and pheromone exist => select node with probability from intersection.
     */

    if (candidateListSize > 0) { // Use candidate list.
        // Get candidate list and the number of elements in intersection.
        int candidates[candidateListSize];
        int numberOfElementsInIntersection = 0;
        for (int i = 0; i < candidateListSize; i++) {
            candidates[i] = NN[(from - 1) * n + i].number;
            if (visited[candidates[i] - 1] == false) {
                numberOfElementsInIntersection++;
            }
        }
        
        // Get intersection.
        int intersectionIndex = 0;
        int intersection[numberOfElementsInIntersection];
        for (int i = 0; i < candidateListSize; i++) {
            if (visited[candidates[i] - 1] == false) {
                intersection[intersectionIndex++] = candidates[i];
            }
        }
        
        // Compute sum weight of intersection.
        double sumWeight = 0.0;
        for (int i = 0; i < numberOfElementsInIntersection; i++) {
            sumWeight += pheromoneWeight(from, intersection[i], n, a, b, P, A);
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

    } else { // Don't use candidate list.
        // Compute the sum of pheromone weight (denominator of the probability).
        double sumWeight = 0.0;
        for (int to = 1; to <= n; to++) {
            if (visited[to - 1] == false) {
                sumWeight += pheromoneWeight(from, to, n, a, b, P, A);
            }
        }
        
        if (sumWeight < DBL_MIN) { // No pheromone.
            // Select unvisited node randomly.
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
            
        } else { // Pheromone exist.
            // Select node with probability.
            double targetWeight = sumWeight * (double)rand() / (RAND_MAX + 1.0);
            double weight = 0.0;
            int targetNodeNumber = 1;
            while (weight < targetWeight) {
                if (visited[targetNodeNumber - 1] == false) {
                    weight += pheromoneWeight(from, targetNodeNumber, n, a, b, P, A);
                }
                targetNodeNumber++;
            }
            targetNodeNumber--;
            return targetNodeNumber;
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
    
    // Do transition with probability.
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
    }
}

- (Tour)tourByASWithNumberOfAnt:(int)m
             pheromoneInfluence:(int)a
            transitionInfluence:(int)b
           pheromoneEvaporation:(double)r
                           seed:(unsigned int)seed
                 noImproveLimit:(int)limit
              candidateListSize:(int)c
                        use2opt:(BOOL)use2opt
                   CSVLogString:(NSString *__autoreleasing *)log

{
    srand(seed);
    if (c > n) {
        c = n;
    }
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Initialize pheromone with average tour distance.
    int	totalDistance = 0;
    for (int i = 0; i < n; i++) {
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
    while (noImproveCount < limit) { // improve loop
        loop++;
        
        // Do ant tours.
        dispatch_apply(m, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t k){
            tours[k] = antTour(k, n, A, NN, P, a, b, c);
            if (use2opt) {
                [self improveTourBy2opt:&(tours[k])];
            }
        });
        
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
    free(tours);
    
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
                    candidateListSize:(int)c
                              use2opt:(BOOL)use2opt
                         CSVLogString:(NSString *__autoreleasing *)log
{
    srand(seed);
    if (c > n) {
        c = n;
    }
    
    double *P = calloc(n * n, sizeof(double)); // Pheromone matrix
    
    // Compute initial best tour by NN.
    Tour initialBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
    for (int i = 0; i < n; i++) {
        Tour aTour = [self tourByNNFrom:i + 1 use2opt:use2opt];
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
//    Tour tours[m]; // Cannot refer to declaration with a variably modified type inside block.
    Tour *tours = calloc(m, sizeof(Tour));
    while (noImproveCount < limit) {
        
        // Do ant tours concurrently.
        dispatch_apply(m, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t k){
            tours[k] = antTour(k, n, A, NN, P, a, b, c);
            if (use2opt) {
                [self improveTourBy2opt:&(tours[k])];
            }
        });
        
        // Find iteration best tour.
        Tour iterationBest = {INT32_MAX, calloc(n + 1, sizeof(int))};
        for (int k = 0; k < m; k++) {
            takeBetterTour(tours[k], &iterationBest);
        }
        
        // Update pheromone
        evaporatePheromone(r, n, P);
        depositPheromone(iterationBest, n, P);
        limitPheromoneRange(iterationBest.distance, r, n, pB, P);
        
        // Update global best tour.
        if (takeBetterTour(iterationBest, &globalBest)) {
            noImproveCount = 0;
        } else {
            noImproveCount++;
        }
        [csv appendFormat:@"%d, %d\n", ++loop, globalBest.distance];
    }
    free(tours);
    
    // Export iteration best tour distances in CSV format.
    if (log) {
        *log = csv;
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

    [string appendString:@"\n=============== TSP INFORMATION ================\n"];
    [string appendString:[NSString stringWithFormat:@"%s: %s\n", "NAME", [[self.information objectForKey:@"NAME"] cStringUsingEncoding:NSUTF8StringEncoding]]];
	[self.information enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        if ([key isEqualToString:@"NAME"] == NO) {
            [string appendString:[NSString stringWithFormat:@"%@: %@\n", key, obj]];
        }
	}];

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
}

@end