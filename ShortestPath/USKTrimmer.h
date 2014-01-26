//
//  USKTrimmer.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/27/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface USKTrimmer : NSObject

/// Trim whitespace. (i.e. @" ch130" => @"ch130")
+ (NSString *)trimmedStringWithString:(NSString *)string;

/// Trim empty string element. (i.e. @[@"hello", @"", @"5.3"] => @[@"hello", @"5.3"]
+ (NSArray *)trimmedArrayWithArray:(NSArray *)array;

@end
