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
    TSPVisualizationStyleDefault = TSPVisualizationStyleLight
} TSPVisualizationStyle;

@interface TSPVisualizer : NSObject

/**
 *  ImageView on which image is drawn
 */
@property UIImageView *imageView;

- (BOOL)drawPath:(Tour)path ofTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style;
- (BOOL)PNGWithPath:(Tour)path ofTSP:(TSP *)tsp toFileNamed:(NSString *)fileName withStyle:(TSPVisualizationStyle)style;

- (void)drawNodesWithTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style;

@end

/*
 TODO: パスはパス、ノードはノードだけ描画する。背景も別。全部のせもあり。
*/