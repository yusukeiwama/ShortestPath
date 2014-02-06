//
//  TSPMatrixQueue.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 2/6/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPMatrixQueue : NSObject

- (void)enqueueMatrix:(double *)matrix size:(int)size;

- (double *)dequeueMatrix;

- (void)flush;

@end
