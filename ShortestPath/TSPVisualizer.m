//
//  USKTSPVisualizer.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPVisualizer.h"

static const UIEdgeInsets margin = {40.0, 40.0, 40.0, 40.0};
static UIEdgeInsets padding = {20.0, 20.0, 20.0, 20.0};
static CGPoint offset = {0.0, 0.0};
static CGSize  scale  = {1.0, 1.0};
static CGFloat height;
static const CGFloat dimensionFactor = 0.99925; // the base of scale factors.

Coordinate correctedPoint(Coordinate point, UIEdgeInsets margin)
{
    Coordinate newPoint = {(point.x - offset.x) * scale.width  + margin.left + padding.left,
        ((point.y - offset.y) * scale.height + margin.top + padding.top) * (-1) + height}; // Flip verically

	return newPoint;
}

@implementation TSPVisualizer {
    CGColorRef _backgroundColor;
    CGColorRef _nodeColor;
    CGColorRef _startNodeColor;
    CGColorRef _edgeColor;
    CGColorRef _pheromoneColor;
    CGFloat    _lineWidthFactor;
    CGFloat    _nodeRadiusFactor;
    CGFloat    _startNodeRadiusFactor;
    CGFloat    _pheromoneFactor;
    
    int *previousRoute;
}

- (void)prepareColorsAndScaleFactorsWithTSP:(TSP *)tsp
{
    // Set default scale factors
    _lineWidthFactor       = 0.010; // the ratio of tour line width to the view's side length.
    _nodeRadiusFactor      = 0.005; // the ratio of node radius to the view's side length.
    _startNodeRadiusFactor = 0.010; // the ratio of start node radius to the view's side length.
    _pheromoneFactor       = 1.0;   // the ratio of pheromone line width to the node's diameter.
    
    // Set default colors
    _backgroundColor = [[UIColor blackColor] CGColor];
    _nodeColor       = [[UIColor whiteColor] CGColor];
    _startNodeColor  = [[UIColor whiteColor] CGColor];
    _edgeColor       = [[UIColor whiteColor] CGColor];
    _pheromoneColor  = [[UIColor colorWithRed:0.4 green:0.0 blue:1 alpha:1.0] CGColor];
    //    _pheromoneColor  = [[UIColor colorWithRed:1.0 green:1.0 blue:0 alpha:0.8] CGColor];
    
    switch (self.style) {
        case TSPVisualizationStyleDark:
            _backgroundColor = [[UIColor blackColor] CGColor];
            _nodeColor       = [[UIColor whiteColor] CGColor];
            _startNodeColor  = [[UIColor whiteColor] CGColor];
            _edgeColor       = [[UIColor whiteColor] CGColor];
            _lineWidthFactor = 0.005;
            break;
        case TSPVisualizationStyleLight:
            _backgroundColor = [[UIColor colorWithWhite:0.98 alpha:1.0] CGColor];
            _nodeColor       = [[UIColor blackColor]  CGColor];
            _edgeColor       = [[UIColor blueColor] CGColor];
            _pheromoneColor  = [[UIColor colorWithWhite:1.0 alpha:0.3] CGColor];
            break;
        case TSPVisualizationStyleOcean:
            _backgroundColor = [[UIColor colorWithRed:0.0 green:0.3 blue:0.5 alpha:1.0] CGColor];
            _nodeColor       = [[UIColor whiteColor] CGColor];
            _edgeColor       = [[UIColor whiteColor] CGColor];
            _startNodeColor  = [[UIColor whiteColor] CGColor];
            _lineWidthFactor = 0.003;
            break;
        case TSPVisualizationStyleGrayScale:
        default:
            _backgroundColor = [[UIColor whiteColor] CGColor];
            _nodeColor       = [[UIColor lightGrayColor]  CGColor];
            _edgeColor       = [[UIColor blackColor] CGColor];
            break;
    }
    
    // Scale factors.
    double scale = pow(dimensionFactor, tsp.dimension);
    _lineWidthFactor       *= scale;
    _nodeRadiusFactor      *= scale;
    _startNodeRadiusFactor *= scale;
}

- (void)prepareCorrectionValueWithTSP:(TSP *)tsp
{
	// Find top, left, right, bottom nodes.
	double top = MAXFLOAT, left = MAXFLOAT, bottom = 0, right = 0;
	for (int i = 0; i < tsp.dimension; i++) {
		if (tsp.nodes[i].coord.x < left)   left   = tsp.nodes[i].coord.x;
		if (tsp.nodes[i].coord.x > right)  right  = tsp.nodes[i].coord.x;
		if (tsp.nodes[i].coord.y < top)    top    = tsp.nodes[i].coord.y;
		if (tsp.nodes[i].coord.y > bottom) bottom = tsp.nodes[i].coord.y;
	}
	
	// Compute constants for size correction
	offset = CGPointMake(left, top);
	scale  = CGSizeMake((self.view.frame.size.width - margin.left - margin.right) / (right - left),
						(self.view.frame.size.height - margin.top - margin.bottom) / (bottom - top));

    // Keep aspect ratio and centering.
    if (scale.width > scale.height) { // Vertically long
        scale.width = scale.height;
        CGFloat displayWidth = (right - left) * scale.width;
        padding.left = padding.right = (self.view.frame.size.width - (margin.left + margin.right) - displayWidth) / 2.0;
        padding.top = padding.bottom = 0.0;
    } else { // Horizontally long
        scale.height = scale.width;
        CGFloat displayHeight = (bottom - top) * scale.height;
        padding.top = padding.bottom = (self.view.frame.size.height - (margin.top + margin.bottom) - displayHeight) / 2.0;
        padding.left = padding.right = 0.0;
    }

    // Prepare height to use in C function.
    height = self.view.frame.size.height;
    
}

- (void)prepareForVisualizationOfTSP:(TSP *)tsp
{
    [self prepareColorsAndScaleFactorsWithTSP:tsp];
    [self prepareCorrectionValueWithTSP:tsp];
}

- (BOOL)drawBackground
{
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.view.frame.size), NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw background
    CGContextSetFillColorWithColor(context, _backgroundColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height));
    
	self.view.backgroundImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    return YES;
}

-(BOOL)drawPheromone:(double *)P withTSP:(TSP *)tsp
{
    if (P == NULL || tsp == nil || tsp.nodes == NULL) return NO;
    
    [self prepareForVisualizationOfTSP:tsp];
    
    int n = tsp.dimension;
    
    // Find max, min pheromone and get the range.
    double max = DBL_MIN;
    double min = DBL_MAX;
    int k = 0;
    for (int i = 0; i < n * (n - 1) / 2; i++) {
        if (P[k] > max) {
            max = P[k];
        }
        if (P[k] < min) {
            min = P[k];
        }
        k++;
    }
    double range = max - min;
    
    // Start drawing
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw matrix
    if (_pheromoneFactor > 1.0) {
        CGContextSetLineCap(context, kCGLineCapRound);
    }
    CGContextSetStrokeColorWithColor(context, _pheromoneColor);
    //        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:0.5 green:0.0 blue:0.8 alpha:0.5] CGColor]);
    k = 0;
    for (int i = 0; i < n; i++) {
        Coordinate from = correctedPoint(tsp.nodes[i].coord, margin);
        for (int j = i + 1; j < n; j++) {
            Coordinate to = correctedPoint(tsp.nodes[j].coord, margin);
            double pheromone = P[k++];
            /*
             For performance reason, not use (pheromone / max) but use ((pheromone - min) / range).
             Probability is related (pheromone / max), not ((pheromone - min) / range).
             However ...
             1. It's too heavy to draw first few step in MMAS with draw-type A.
             2. min pheromone in MMAS is hardly visible with both draw-type A and B.
             3. Because min pheromone goes to zero in AS, there is no difference between draw-type A and B.
             So, draw-type B is used.
             */
//            double lineWidth = self.view.frame.size.width * (_nodeRadiusFactor * 2) * (pheromone / max) * _pheromoneFactor; // ... A
            double lineWidth = self.view.frame.size.width * (_nodeRadiusFactor * 2) * _pheromoneFactor * ((pheromone - min) / range); // ... B
            
//            if (lineWidth < 0.001) { // Stop drawing too shallow line for performance.
//                lineWidth = 0.0;
//            }
            
            CGContextSetLineWidth(context, lineWidth);
            CGContextMoveToPoint(context, from.x, from.y);
            CGContextAddLineToPoint(context, to.x, to.y);
            CGContextStrokePath(context);
        }
    }
    
    self.view.pheromoneImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return YES;
}

- (BOOL)drawOptimalTour:(Tour)tour withTSP:(TSP *)tsp
{
    if (tour.route == NULL || tsp == nil || tsp.nodes == NULL) return NO;
    
    [self prepareForVisualizationOfTSP:tsp];
    
    // Start drawing
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw path
    Coordinate startPoint = correctedPoint(tsp.nodes[tour.route[0] - 1].coord, margin);
    CGContextSetLineWidth(context, self.view.frame.size.width * _nodeRadiusFactor * 2.0);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    for (int i = 1; i <= tsp.dimension; i++) {
        int nodeNumber = tour.route[i];
        if (nodeNumber <  1 || nodeNumber > tsp.dimension) { // Tour ends.
            break;
        }
        Coordinate aPoint = correctedPoint(tsp.nodes[nodeNumber - 1].coord, margin);
        CGContextAddLineToPoint(context, aPoint.x, aPoint.y);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:((double)i / tsp.dimension) saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, aPoint.x, aPoint.y);
    }
    
    self.view.optimalTourImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return YES;
}

- (BOOL)drawDirectionalTour:(Tour)tour withTSP:(TSP *)tsp
{
    if (tour.route == NULL || tsp == nil || tsp.nodes == NULL) return NO;
    
    [self prepareForVisualizationOfTSP:tsp];
    
    // Start drawing
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw path
    Coordinate startPoint = correctedPoint(tsp.nodes[tour.route[0] - 1].coord, margin);
    CGContextSetLineWidth(context, self.view.frame.size.width * _lineWidthFactor * 0.8);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    for (int i = 1; i <= tsp.dimension; i++) {
        int nodeNumber = tour.route[i];
        if (nodeNumber <  1 || nodeNumber > tsp.dimension) { // Tour ends.
            break;
        }
        Coordinate aPoint = correctedPoint(tsp.nodes[nodeNumber - 1].coord, margin);
        CGContextAddLineToPoint(context, aPoint.x, aPoint.y);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:((double)i / tsp.dimension) saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, aPoint.x, aPoint.y);
    }
    
    self.view.tourImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return YES;
}

- (BOOL)drawTour:(Tour)tour withTSP:(TSP *)tsp
{
    if (tour.route == NULL || tsp == nil || tsp.nodes == NULL) return NO;

    [self prepareForVisualizationOfTSP:tsp];
    
    // Start drawing
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw path
    Coordinate startPoint = correctedPoint(tsp.nodes[tour.route[0] - 1].coord, margin);
    CGContextSetLineWidth(context, self.view.frame.size.width * _lineWidthFactor);
    CGContextSetStrokeColorWithColor(context, _edgeColor);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    for (int i = 1; i <= tsp.dimension; i++) {
        int nodeNumber = tour.route[i];
        if (nodeNumber <  1 || nodeNumber > tsp.dimension) { // Tour ends.
            break;
        }
        Coordinate aPoint = correctedPoint(tsp.nodes[nodeNumber - 1].coord, margin);
        CGContextAddLineToPoint(context, aPoint.x, aPoint.y);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, aPoint.x, aPoint.y);
    }
    
    self.view.tourImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	return YES;
}


- (BOOL)PNGWithImageOnImageView:(UIImageView *)imageView fileName:(NSString *)fileName
{
	NSArray	 *filePaths   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [filePaths objectAtIndex:0];
	NSString *outputPath  = [documentDir stringByAppendingPathComponent:fileName];
	NSURL    *outputURL   = [NSURL fileURLWithPath:outputPath];
	// Example Path: /Users/yusukeiwama/Library/Application Support/iPhone Simulator/7.0.3/Applications/85BB258F-2ED0-464C-AD92-1C5D11012E67/Documents
    
    NSData *imageData = UIImagePNGRepresentation(imageView.image);
    if ([imageData writeToURL:outputURL atomically:YES]) {
        NSLog(@"%@ is saved", fileName);
        return YES;
    } else {
        NSLog(@"Failed to save %@", fileName);
        return NO;
    }
	
	NSLog(@"Failed to draw %@", fileName);
	return NO;
}

- (BOOL)drawNodesWithTSP:(TSP *)tsp
{
    if (tsp == nil) return NO;

	[self prepareForVisualizationOfTSP:tsp];
    
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.view.frame.size), NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
		
	// Draw nodes
	CGFloat r = self.view.frame.size.width * _nodeRadiusFactor; // 0.5% of width
	CGContextSetFillColorWithColor(context, _nodeColor);
	for (int i = 0; i < tsp.dimension; i++) {
		Coordinate aPoint = correctedPoint(tsp.nodes[i].coord, margin);
		CGContextFillEllipseInRect(context, CGRectMake(aPoint.x - r, aPoint.y - r, 2 * r, 2 * r));
	}
    
    // Draw start node
//    r = self.globalBestPathImageView.frame.size.width * _startNodeRadiusFactor; // 1% of width
//	CGContextSetFillColorWithColor(context, _startNodeColor);
//    Coordinate startPoint = correctedPoint(tsp.nodes[0].coord, margin);
//	CGContextFillEllipseInRect(context, CGRectMake(startPoint.x - r, startPoint.y - r, 2 * r, 2 * r));

    // Draw start node's border.
//    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
//    CGContextSetLineWidth(context, 1.0);
//    CGContextStrokeEllipseInRect(context, CGRectMake(startPoint.x - r, startPoint.y - r, 2 * r, 2 * r));
		
	self.view.nodeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    return YES;
}

- (BOOL)clearTourImages
{
    self.view.pheromoneImageView.image       = nil;
    self.view.directionalTourImageView.image = nil;
    self.view.tourImageView.image            = nil;
    
    return YES;
}

- (BOOL)clearTSPImages
{
    self.view.pheromoneImageView.image       = nil;
    self.view.optimalTourImageView.image     = nil;
    self.view.directionalTourImageView.image = nil;
    self.view.tourImageView.image            = nil;
    self.view.nodeImageView.image            = nil;
    
    return YES;
}

- (BOOL)clearAll
{
    self.view.backgroundImageView.image      = nil;
    self.view.pheromoneImageView.image       = nil;
    self.view.optimalTourImageView.image     = nil;
    self.view.directionalTourImageView.image = nil;
    self.view.tourImageView.image            = nil;
    self.view.nodeImageView.image            = nil;
    
    return YES;
}

@end
