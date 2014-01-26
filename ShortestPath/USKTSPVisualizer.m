//
//  USKTSPVisualizer.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "USKTSPVisualizer.h"

static const UIEdgeInsets margin = {20.0, 20.0, 20.0, 20.0};
static CGPoint offset = {0.0, 0.0};
static CGSize  scale  = {1.0, 1.0};

CGPoint correctedPoint(CGPoint point)
{
	return CGPointMake((point.x - offset.x) * scale.width  + margin.left,
					   (point.y - offset.y) * scale.height + margin.top);
}

@implementation USKTSPVisualizer

- (void)drawPath:(PathInfo)path ofTSP:(USKTSP *)tsp
{
	// Find top, left, right, bottom nodes.
	double top = MAXFLOAT, left = MAXFLOAT, bottom = 0, right = 0;
	for (int i = 0; i < tsp.dimension; i++) {
		if (tsp.nodes[i].coordination.x < left)	  left   = tsp.nodes[i].coordination.x;
		if (tsp.nodes[i].coordination.x > right)  right  = tsp.nodes[i].coordination.x;
		if (tsp.nodes[i].coordination.y < top)    top    = tsp.nodes[i].coordination.y;
		if (tsp.nodes[i].coordination.y > bottom) bottom = tsp.nodes[i].coordination.y;
	}
	
	// Compute constants for size correction
	offset = CGPointMake(left, top);
	scale  = CGSizeMake((self.imageView.frame.size.width - margin.left - margin.right) / (right - left),
						(self.imageView.frame.size.height - margin.top - margin.bottom) / (bottom - top));
	
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.imageView.frame.size), YES, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw path
	CGPoint startPoint = correctedPoint(tsp.nodes[path.path[0] - 1].coordination);
	CGContextSetLineWidth(context, 10.0);
	CGContextMoveToPoint(context, startPoint.x, startPoint.y);
	for (int i = 1; i < tsp.dimension; i++) {
		CGPoint aPoint = correctedPoint(tsp.nodes[path.path[i] - 1].coordination);
		CGContextAddLineToPoint(context, aPoint.x, aPoint.y);
		CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:((double)i / tsp.dimension) saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
		CGContextStrokePath(context);
		CGContextMoveToPoint(context, aPoint.x, aPoint.y);
	}
	CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
	CGContextStrokePath(context);
	
	// Draw nodes
	CGFloat r = 5.0;
	CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
	for (int i = 0; i < tsp.dimension; i++) {
		CGPoint aPoint = correctedPoint(tsp.nodes[i].coordination);
		CGContextFillEllipseInRect(context, CGRectMake(aPoint.x - r, aPoint.y - r, 2 * r, 2 * r));
	}

	// Draw start node
	CGContextSetFillColorWithColor(context, [[UIColor yellowColor] CGColor]);
	CGContextFillEllipseInRect(context, CGRectMake(startPoint.x - r, startPoint.y - r, 2 * r, 2 * r));
	
	self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

@end
