//
//  USKTrimmer.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/27/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "USKTrimmer.h"

@implementation USKTrimmer

+ (NSString *)trimmedStringWithString:(NSString *)string
{
	return [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
}

+ (NSArray *)trimmedArrayWithArray:(NSArray *)array
{
	NSMutableArray *mutableArray = [NSMutableArray array];
	for (int i = 0; i < array.count; i++) {
		NSString *string = array[i];
		if ([string isEqualToString:@""] == NO) {
			[mutableArray addObject:array[i]];
		}
	}
	return mutableArray;
}

@end
