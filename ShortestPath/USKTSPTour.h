//
//  USKTSPTour.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/27/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface USKTSPTour : NSObject

/**
 *  Total length.
 */
@property int length;

/**
 *  Array of node number.
 */
@property NSArray *route;

+ (id)tourWithLength:(int)length route:(NSArray *)route;
- (id)initWithLength:(int)length route:(NSArray *)route;

@end
