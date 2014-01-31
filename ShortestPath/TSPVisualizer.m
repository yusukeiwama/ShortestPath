//
//  USKTSPVisualizer.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPVisualizer.h"

static UIEdgeInsets padding = {20.0, 20.0, 20.0, 20.0};
static CGPoint offset = {0.0, 0.0};
static CGSize  scale  = {1.0, 1.0};
static CGFloat height;

Coordinate correctedPoint(Coordinate point, UIEdgeInsets margin)
{
    Coordinate newPoint = {(point.x - offset.x) * scale.width  + margin.left + padding.left,
        ((point.y - offset.y) * scale.height + margin.top + padding.top) * (-1) + height}; // Flip verically

	return newPoint;
}

@implementation TSPVisualizer {
    CGColorRef _backgroundColor;
    CGColorRef _nodeColor;
    CGColorRef _edgeColor;
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
	scale  = CGSizeMake((self.imageView.frame.size.width - margin.left - margin.right) / (right - left),
						(self.imageView.frame.size.height - margin.top - margin.bottom) / (bottom - top));

    // Keep aspect ratio and centering.
    if (scale.width > scale.height) { // Vertically long
        scale.width = scale.height;
        CGFloat displayWidth = (right - left) * scale.width;
        padding.left = padding.right = (self.imageView.frame.size.width - (margin.left + margin.right) - displayWidth) / 2.0;
        padding.top = padding.bottom = 0.0;
    } else { // Horizontally long
        scale.height = scale.width;
        CGFloat displayHeight = (bottom - top) * scale.height;
        padding.top = padding.bottom = (self.imageView.frame.size.height - (margin.top + margin.bottom) - displayHeight) / 2.0;
        padding.left = padding.right = 0.0;
    }

    // Prepare height to use in C function.
    height = self.imageView.frame.size.height;
}

- (void)prepareColorsWithStyle:(TSPVisualizationStyle)style
{
    switch (style) {
        case TSPVisualizationStyleDark:
            _backgroundColor = [[UIColor blackColor] CGColor];
            _nodeColor       = [[UIColor whiteColor] CGColor];
            _edgeColor       = [[UIColor yellowColor] CGColor];
            break;
        case TSPVisualizationStyleLight:
            _backgroundColor = [[UIColor colorWithWhite:0.98 alpha:1.0] CGColor];
            _nodeColor       = [[UIColor blackColor]  CGColor];
            _edgeColor       = [[UIColor blueColor] CGColor];
            break;
        case TSPVisualizationStyleGrayScale:
        default:
            _backgroundColor = [[UIColor whiteColor] CGColor];
            _nodeColor       = [[UIColor lightGrayColor]  CGColor];
            _edgeColor       = [[UIColor blackColor] CGColor];
            break;
    }
}

- (BOOL)drawPath:(Tour)path ofTSP:(TSP *)tsp withStyle:(TSPVisualizationStyle)style
{
	if (path.route == NULL || tsp == nil || tsp.nodes == NULL) return NO;
	
    UIEdgeInsets margin  = {40.0, 40.0, 40.0, 40.0};
	[self prepareForCorrectionWithTSP:tsp margin:margin];
    [self prepareColorsWithStyle:style];
    
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.imageView.frame.size), YES, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw background
    CGContextSetFillColorWithColor(context, _backgroundColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, self.imageView.frame.size.width, self.imageView.frame.size.height));
	
	// Draw path
	Coordinate startPoint = correctedPoint(tsp.nodes[path.route[0] - 1].coord, margin);
	CGContextSetLineWidth(context, 10.0);
	CGContextMoveToPoint(context, startPoint.x, startPoint.y);
	for (int i = 1; i < tsp.dimension; i++) {
		Coordinate aPoint = correctedPoint(tsp.nodes[path.route[i] - 1].coord, margin);
		CGContextAddLineToPoint(context, aPoint.x, aPoint.y);
        if (style == TSPVisualizationStyleDark || style == TSPVisualizationStyleLight) {
            CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:((double)i / tsp.dimension) saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
        } else {
            CGContextSetStrokeColorWithColor(context, _edgeColor);
        }
		CGContextStrokePath(context);
		CGContextMoveToPoint(context, aPoint.x, aPoint.y);
	}
	CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
	CGContextStrokePath(context);
	
	// Draw nodes
	CGFloat r = 5.0;
	CGContextSetFillColorWithColor(context, _nodeColor);
	for (int i = 0; i < tsp.dimension; i++) {
		Coordinate aPoint = correctedPoint(tsp.nodes[i].coord, margin);
		CGContextFillEllipseInRect(context, CGRectMake(aPoint.x - r, aPoint.y - r, 2 * r, 2 * r));
	}
	
	// Draw start node
    r = 10.0;
	CGContextSetFillColorWithColor(context, [[UIColor yellowColor] CGColor]);
	CGContextFillEllipseInRect(context, CGRectMake(startPoint.x - r, startPoint.y - r, 2 * r, 2 * r));
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeEllipseInRect(context, CGRectMake(startPoint.x - r, startPoint.y - r, 2 * r, 2 * r));
	
	self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
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
		NSData *imageData = UIImagePNGRepresentation(self.imageView.image);
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
	
    UIEdgeInsets margin = {40.0, 40.0, 40.0, 40.0};
	[self prepareForCorrectionWithTSP:tsp margin:margin];
    [self prepareColorsWithStyle:style];
    
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.imageView.frame.size), YES, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw background
    CGContextSetFillColorWithColor(context, _backgroundColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, self.imageView.frame.size.width, self.imageView.frame.size.height));
		
	// Draw nodes
	CGFloat r = 22.0;
	CGContextSetFillColorWithColor(context, _nodeColor);
	for (int i = 0; i < tsp.dimension; i++) {
		Coordinate aPoint = correctedPoint(tsp.nodes[i].coord, margin);
		CGContextFillEllipseInRect(context, CGRectMake(aPoint.x - r, aPoint.y - r, 2 * r, 2 * r));
	}
		
	self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

@end
