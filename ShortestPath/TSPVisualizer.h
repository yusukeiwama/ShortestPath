//
//  USKTSPVisualizer.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSP.h"
#import "TSPView.h"

typedef enum TSPVisualizationStyle {
    TSPVisualizationStyleDark,
    TSPVisualizationStyleLight,
    TSPVisualizationStyleGrayScale,
    TSPVisualizationStyleOcean,
    TSPVisualizationStyleDefault = TSPVisualizationStyleLight
} TSPVisualizationStyle;

@interface TSPVisualizer : NSObject

@property TSPVisualizationStyle style;
@property TSPView               *view;

@property NSOperationQueue      *operationQueue;

#pragma mark - Visualizations

- (BOOL)drawBackground;
- (BOOL)drawPheromone:(double *)P withTSP:(TSP *)tsp;
- (BOOL)drawOptimalTour:(Tour)tour withTSP:(TSP *)tsp;
- (BOOL)drawDirectionalTour:(Tour)tour withTSP:(TSP *)tsp;
- (BOOL)drawTour:(Tour)tour withTSP:(TSP *)tsp;
- (BOOL)drawNodesWithTSP:(TSP *)tsp;

- (BOOL)clearTourImages; // Clear optimal tour, directional tour, tour, pheromone.
- (BOOL)clearTSPImages;  // Clear all except for background.
- (BOOL)clearAll;

#pragma mark - Export

- (BOOL)PNGWithImageOnImageView:(UIImageView *)image fileName:(NSString *)fileName;

@end