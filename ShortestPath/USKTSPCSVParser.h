//
//  USKTSPCSVParser.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 2/7/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSP.h"

@interface USKTSPCSVParser : NSObject

- (TSP *)TSPWithCSV:(NSString *)path;

@end
