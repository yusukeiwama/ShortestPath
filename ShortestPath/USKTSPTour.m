//
//  USKTSPTour.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/27/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "USKTSPTour.h"

@implementation USKTSPTour

+ (id)tourWithLength:(int)length route:(NSArray *)route
{
	return [[USKTSPTour alloc] initWithLength:length route:route];
}

- (id)initWithLength:(int)length route:(NSArray *)route
{
	self = [super init];
	if (self) {
		_length = length;
		_route  = route;
	}
	return self;
}

@end
