//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKViewController.h"
#import "USKTSP.h"

@interface USKViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *nodeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *pathImageView;

@end

@implementation USKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	USKTSP *tsp = [USKTSP TSPWithFile:[[NSBundle mainBundle] pathForResource:@"TSPData/ch130" ofType:@"tsp"]];
	
	double sum = 0;
	PathInfo shortestPath = {MAXFLOAT, NULL};
	for (int i = 0; i < tsp.dimension; i++) {
		PathInfo shortPath = [tsp shortestPathByNNFrom:i + 1];
		[tsp improvePathBy2opt:&shortPath];
		if (shortPath.length < shortestPath.length) {
			[tsp freePath:shortestPath];
			shortestPath = shortPath;
		} else {
			[tsp freePath:shortPath];
		}
		sum += shortPath.length;
		printf("%.3f, ", shortPath.length);
	}
	printf("\nAverage = %.3f\nShortest = %.3f\n", sum / tsp.dimension, shortestPath.length);
		
	[self drawPath:shortestPath ofTSP:tsp];
}

- (void)drawPath:(PathInfo)path ofTSP:(USKTSP *)tsp
{
	double top = MAXFLOAT, left = MAXFLOAT, bottom = 0, right = 0;
	for (int i = 0; i < tsp.dimension; i++) {
		if (tsp.nodes[i].coordination.x < left)	  left   = tsp.nodes[i].coordination.x;
		if (tsp.nodes[i].coordination.x > right)  right  = tsp.nodes[i].coordination.x;
		if (tsp.nodes[i].coordination.y < top)    top    = tsp.nodes[i].coordination.y;
		if (tsp.nodes[i].coordination.y > bottom) bottom = tsp.nodes[i].coordination.y;
	}
	UIEdgeInsets insets = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
	CGPoint offset = {left, top};
	CGSize  scale  = {(self.nodeImageView.frame.size.width - insets.left - insets.right) / (right - left), (self.nodeImageView.frame.size.height - insets.top - insets.bottom) / (bottom - top)};
	
	UIGraphicsBeginImageContextWithOptions((self.nodeImageView.frame.size), NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw nodes
	CGFloat r = 5.0;
	CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
	for (int i = 0; i < tsp.dimension; i++) {
		CGContextFillEllipseInRect(context, CGRectMake((tsp.nodes[i].coordination.x - offset.x) * scale.width - r + insets.left,
													   (tsp.nodes[i].coordination.y - offset.y) * scale.height - r + insets.top,
													   2 * r, 2 * r));
	}
	
	// Draw start node
	CGPoint startPoint = tsp.nodes[path.path[0] - 1].coordination;
	CGContextSetFillColorWithColor(context, [[UIColor yellowColor] CGColor]);
	CGContextFillEllipseInRect(context, CGRectMake((startPoint.x - offset.x) * scale.width - r + insets.left,
												   (startPoint.y - offset.y) * scale.height - r + insets.top,
												   2 * r, 2 * r));
	
	self.nodeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	
	// Draw path
	CGContextMoveToPoint(context, (startPoint.x - offset.x) * scale.width + insets.left, (startPoint.y - offset.y) * scale.height + insets.top);
	for (int i = 1; i < tsp.dimension; i++) {
		CGPoint nextPoint = tsp.nodes[path.path[i] - 1].coordination;
		CGContextAddLineToPoint(context, (nextPoint.x - offset.x) * scale.width + insets.left , (nextPoint.y - offset.y) * scale.height + insets.top);
		CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:((double)i / tsp.dimension) saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
		CGContextStrokePath(context);
		CGContextMoveToPoint(context, (nextPoint.x - offset.x) * scale.width + insets.left, (nextPoint.y - offset.y) * scale.height + insets.top);
	}
	CGContextAddLineToPoint(context, (startPoint.x - offset.x) * scale.width + insets.left, (startPoint.y - offset.y) * scale.height + insets.top);
	CGContextStrokePath(context);

	
	self.pathImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
