//
//  USKTSP.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKTSP.h"

@implementation USKTSP

@synthesize name;
@synthesize comment;
@synthesize type;
@synthesize dimension;
@synthesize edgeWeightType;
@synthesize nodes;
@synthesize adjacencyMatrix;

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
			for (NSUInteger i = 0; i < information.count - 8; i++) {
				NSArray *nodeInfo = [information[i + 6] componentsSeparatedByString:@" "]; // 6 is offset in TSPData file
				nodes[i].nodeID = [nodeInfo[0] integerValue];
				nodes[i].coordination.x = [nodeInfo[1] doubleValue];
				nodes[i].coordination.y = [nodeInfo[2] doubleValue];
//				printf("%d %f %f\n", nodes[i].nodeID, nodes[i].coordination.x, nodes[i].coordination.y);
			}
			[self prepareAdjacencyMatrix];
		}
		
		
	}
	
	return self;
}

- (void)prepareAdjacencyMatrix {
	adjacencyMatrix = calloc(dimension * dimension, sizeof(double));
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

- (void)dealloc
{
	free(nodes);
	free(adjacencyMatrix);
}

@end