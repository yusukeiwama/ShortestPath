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
static CGFloat dimensionFactor = 1.00075;

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

- (void)prepareForCorrectionWithTSP:(TSP *)tsp margin:(UIEdgeInsets)margin
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
	scale  = CGSizeMake((self.globalBestPathImageView.frame.size.width - margin.left - margin.right) / (right - left),
						(self.globalBestPathImageView.frame.size.height - margin.top - margin.bottom) / (bottom - top));

    // Keep aspect ratio and centering.
    if (scale.width > scale.height) { // Vertically long
        scale.width = scale.height;
        CGFloat displayWidth = (right - left) * scale.width;
        padding.left = padding.right = (self.globalBestPathImageView.frame.size.width - (margin.left + margin.right) - displayWidth) / 2.0;
        padding.top = padding.bottom = 0.0;
    } else { // Horizontally long
        scale.height = scale.width;
        CGFloat displayHeight = (bottom - top) * scale.height;
        padding.top = padding.bottom = (self.globalBestPathImageView.frame.size.height - (margin.top + margin.bottom) - displayHeight) / 2.0;
        padding.left = padding.right = 0.0;
    }

    // Prepare height to use in C function.
    height = self.globalBestPathImageView.frame.size.height;
}

- (void)prepareColorsWithStyle:(TSPVisualizationStyle)style TSP:(TSP *)tsp;
{
    _lineWidthFactor       = 0.010;
    _nodeRadiusFactor      = 0.005;
    _startNodeRadiusFactor = 0.010;
    _pheromoneFactor       = 1.0;
    
    // Set default colors
    _backgroundColor = [[UIColor blackColor] CGColor];
    _nodeColor       = [[UIColor whiteColor] CGColor];
    _startNodeColor  = [[UIColor whiteColor] CGColor];
    _edgeColor       = [[UIColor whiteColor] CGColor];
    _pheromoneColor  = [[UIColor colorWithRed:0.5 green:0.0 blue:1 alpha:1.0] CGColor];

    switch (style) {
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
    
    double scale = pow(dimensionFactor, -tsp.dimension);
    _lineWidthFactor       *= scale;
    _nodeRadiusFactor      *= scale;
    _startNodeRadiusFactor *= scale;
}

- (BOOL)drawPath:(Tour)path ofTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style
{
    if (path.route == NULL || tsp == nil || tsp.nodes == NULL) return NO;

    // Prepare colors and scale.
    [self prepareForCorrectionWithTSP:tsp margin:margin];
    [self prepareColorsWithStyle:style TSP:tsp];
    
    // Start drawing
    UIGraphicsBeginImageContextWithOptions((self.globalBestPathImageView.frame.size), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw path
    Coordinate startPoint = correctedPoint(tsp.nodes[path.route[0] - 1].coord, margin);
    CGContextSetLineWidth(context, self.globalBestPathImageView.frame.size.width * _lineWidthFactor); // 1% of width;
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    for (int i = 1; i <= tsp.dimension; i++) {
        int nodeNumber = path.route[i];
        if (nodeNumber <  1 || nodeNumber > tsp.dimension) { // Tour ends.
            break;
        }
        Coordinate aPoint = correctedPoint(tsp.nodes[nodeNumber - 1].coord, margin);
        CGContextAddLineToPoint(context, aPoint.x, aPoint.y);
        if (style == TSPVisualizationStyleDark
            || style == TSPVisualizationStyleLight) {
            CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:((double)i / tsp.dimension) saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
        } else {
            CGContextSetStrokeColorWithColor(context, _edgeColor);
        }
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, aPoint.x, aPoint.y);
    }
    
    // Update image.
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    self.globalBestPathImageView.image = image;
    UIGraphicsEndImageContext();
	
	return YES;
}

- (BOOL)drawPheromone:(double *)P ofTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style
{
    @autoreleasepool {
        if (P == NULL || tsp == nil || tsp.nodes == NULL) return NO;
        
        [self prepareForCorrectionWithTSP:tsp margin:margin];
        [self prepareColorsWithStyle:style TSP:tsp];
        
        int n = tsp.dimension;
        
        // Find max pheromone
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
        UIGraphicsBeginImageContextWithOptions((self.additionalImageView.frame.size), NO, 0);
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
                CGContextSetLineWidth(context, self.additionalImageView.frame.size.width * (_nodeRadiusFactor * 2) * ((pheromone - min) / range) * _pheromoneFactor);
                CGContextMoveToPoint(context, from.x, from.y);
                CGContextAddLineToPoint(context, to.x, to.y);
                CGContextStrokePath(context);
            }
        }
		
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        self.additionalImageView.image = image;
        UIGraphicsEndImageContext();
    }
    return YES;
}

- (BOOL)PNGWithPath:(Tour)path ofTSP:(TSP *)tsp toFileNamed:(NSString *)fileName withStyle:(TSPVisualizationStyle)style
{
	NSArray	 *filePaths   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [filePaths objectAtIndex:0];
	NSString *outputPath  = [documentDir stringByAppendingPathComponent:fileName];
	NSURL    *outputURL   = [NSURL fileURLWithPath:outputPath];
	// Example Path: /Users/yusukeiwama/Library/Application Support/iPhone Simulator/7.0.3/Applications/85BB258F-2ED0-464C-AD92-1C5D11012E67/Documents
	
	if ([self drawPath:path ofTSP:tsp withStyle:style]) {
		NSData *imageData = UIImagePNGRepresentation(self.globalBestPathImageView.image);
		if ([imageData writeToURL:outputURL atomically:YES]) {
			NSLog(@"%@ is saved", fileName);
			return YES;
		} else {
			NSLog(@"Failed to save %@", fileName);
			return NO;
		}
	}
	
	NSLog(@"Failed to draw %@", fileName);
	return NO;
}

- (void)drawNodesWithTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style
{
    if (tsp == nil) return;
	
	[self prepareForCorrectionWithTSP:tsp margin:margin];
    [self prepareColorsWithStyle:style TSP:tsp];
    
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.nodeImageView.frame.size), NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
		
	// Draw nodes
	CGFloat r = self.nodeImageView.frame.size.width * _nodeRadiusFactor; // 0.5% of width
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
		
	self.nodeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

- (void)drawBackgroundWithStyle:(TSPVisualizationStyle)style
{
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.backgroundImaveView.frame.size), NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw background
    CGContextSetFillColorWithColor(context, _backgroundColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, self.backgroundImaveView.frame.size.width, self.backgroundImaveView.frame.size.height));
    
	self.backgroundImaveView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

- (void)clearTSPVisualization
{
    self.optimalPathImageView.image    = nil;
    self.globalBestPathImageView.image = nil;
    self.additionalImageView.image     = nil;
    self.nodeImageView.image           = nil;
}

- (void)clearTSPTour
{
    self.optimalPathImageView.image    = nil;
    self.globalBestPathImageView.image = nil;
    self.additionalImageView.image     = nil;
}

@end
