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
static CGFloat height;

CGPoint correctedPoint(CGPoint point)
{
	return CGPointMake((point.x - offset.x) * scale.width  + margin.left,
					   ((point.y - offset.y) * scale.height + margin.top) * (-1) + height);
}

@implementation USKTSPVisualizer

- (void)prepareForCorrectionWithTSP:(USKTSP *)tsp
{
	// Find top, left, right, bottom nodes.
	double top = MAXFLOAT, left = MAXFLOAT, bottom = 0, right = 0;
	for (int i = 0; i < tsp.dimension; i++) {
		CGPoint p = [tsp.nodes[i] CGPointValue];
		if (p.x < left)   left   = p.x;
		if (p.x > right)  right  = p.x;
		if (p.y < top)    top    = p.y;
		if (p.y > bottom) bottom = p.y;
	}
	
	// Compute constants for size correction
	offset = CGPointMake(left, top);
	scale  = CGSizeMake((self.imageView.frame.size.width - margin.left - margin.right) / (right - left),
						(self.imageView.frame.size.height - margin.top - margin.bottom) / (bottom - top));
	height = self.imageView.frame.size.height;
}

- (BOOL)drawPath:(USKTSPTour *)path ofTSP:(USKTSP *)tsp
{
	if (path.route == nil || tsp == nil || tsp.nodes == NULL) return NO;
	
	[self prepareForCorrectionWithTSP:tsp];
	
	// Start drawing
	UIGraphicsBeginImageContextWithOptions((self.imageView.frame.size), YES, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw path
	CGPoint startPoint = correctedPoint([tsp.nodes[[path.route[0] integerValue] - 1] CGPointValue]);
	CGContextSetLineWidth(context, 10.0);
	CGContextMoveToPoint(context, startPoint.x, startPoint.y);
	for (int i = 1; i < tsp.dimension; i++) {
		CGPoint aPoint = correctedPoint([tsp.nodes[[path.route[i] integerValue] - 1] CGPointValue]);
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
		CGPoint aPoint = correctedPoint([tsp.nodes[i] CGPointValue]);
		CGContextFillEllipseInRect(context, CGRectMake(aPoint.x - r, aPoint.y - r, 2 * r, 2 * r));
	}
	
	// Draw start node
	CGContextSetFillColorWithColor(context, [[UIColor yellowColor] CGColor]);
	CGContextFillEllipseInRect(context, CGRectMake(startPoint.x - r, startPoint.y - r, 2 * r, 2 * r));
	
	self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return YES;
}

- (BOOL)PNGWithPath:(USKTSPTour *)path ofTSP:(USKTSP *)tsp toFileNamed:(NSString *)fileName
{
	NSArray	 *filePaths   = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [filePaths objectAtIndex:0];
	NSString *outputPath  = [documentDir stringByAppendingPathComponent:fileName];
	NSURL    *outputURL   = [NSURL fileURLWithPath:outputPath];
	// Example Path: /Users/yusukeiwama/Library/Application Support/iPhone Simulator/7.0.3/Applications/85BB258F-2ED0-464C-AD92-1C5D11012E67/Documents
	
	
	if ([self drawPath:path ofTSP:tsp]) {
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

@end
