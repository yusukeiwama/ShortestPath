//
//  USKTSPCSVParser.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 2/7/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "USKTSPCSVParser.h"

#import "USKTrimmer.h"

// Prevent round error.
#define SCALE_FACTOR 100

@implementation USKTSPCSVParser


- (TSP *)TSPWithCSV:(NSString *)path
{
    // Get lines from file.
    NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
	NSArray *lines = [rawString componentsSeparatedByString:@"\n"];
	lines = [USKTrimmer trimmedArrayWithArray:lines];
    
    int n = 0;
    for (int i = 1; i < [lines count]; i++) {
        NSArray *cells = [lines[i] componentsSeparatedByString:@","];
        for (int j = 1; j < [cells count]; j++) {
            NSString *str = cells[j];
            if ([str isEqualToString:@""] == NO) { // Found node
                n++;
                printf("%d %d %d\n", n, j * SCALE_FACTOR, -i * SCALE_FACTOR); // scale to prevent round error.
            }
        }
    }

    return nil;
}

@end
