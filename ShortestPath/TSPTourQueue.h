//
//  TSPTourQueue.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 2/5/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSP.h"

@interface TSPTourQueue : NSObject

- (void)enqueueTour:(Tour)tour toIndex:(int)index;

// Caller must free MidTour->tour.route
- (MidTour *)dequeueTour;

- (void)flush;

@end
