//
//  USKTSPVisualizer.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSP.h"

typedef enum TSPVisualizationStyle {
    TSPVisualizationStyleDark,
    TSPVisualizationStyleLight,
    TSPVisualizationStyleGrayScale,
    TSPVisualizationStyleOcean,
    TSPVisualizationStyleDefault = TSPVisualizationStyleLight
} TSPVisualizationStyle;

@interface TSPVisualizer : NSObject

@property UIImageView *backgroundImaveView;
@property UIImageView *optimalPathImageView;
@property UIImageView *globalBestPathImageView;
@property UIImageView *additionalImageView;
@property UIImageView *nodeImageView;


- (BOOL)drawPath:(Tour)path ofTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style onImageView:(UIImageView *)imageView;

- (void)drawNodesWithTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style;

- (void)drawBackgroundWithStyle:(TSPVisualizationStyle)style;

- (BOOL)drawPheromone:(double *)P ofTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style;

/// Clear all layer but background.
- (void)clearTSPVisualization;

/// Clear path and pheromone.
- (void)clearTSPTour;

#pragma mark - Export
- (BOOL)PNGWithPath:(Tour)path ofTSP:(TSP *)tsp toFileNamed:(NSString *)fileName withStyle:(TSPVisualizationStyle)style;

@end