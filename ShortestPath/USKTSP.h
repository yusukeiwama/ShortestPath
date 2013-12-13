//
//  USKTSP.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct TSPNode{
	NSInteger nodeID;
	CGPoint coordination;
} TSPNode;

@interface USKTSP : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *comment;
@property (readonly) NSString *type;
@property (readonly) NSUInteger dimension;
@property (readonly) NSString *edgeWeightType;
@property (readonly) TSPNode *nodes;

/// lengths of arcs (size of array is (numberOfNodes * numberOfNodes))
@property (readonly) double *adjacencyMatrix;

/**
 initialize with specified TSP data file.
 @param path input file path
 */
- initWithFilePath:(NSString *)path;

@end
