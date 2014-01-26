//
//  USKTSPVisualizer.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "USKTSP.h"

@interface USKTSPVisualizer : NSObject

/**
 *  ImageView on which image is drawn
 */
@property UIImageView *imageView;

- (void)drawPath:(PathInfo)path ofTSP:(USKTSP *)tsp;

@end
