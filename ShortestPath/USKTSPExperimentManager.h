//
//  USKTSPExperimentManager.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

@class USKTSPVisualizer;

typedef enum USKTSPExperiment {
	USKTSPExperimentNN,
	USKTSPExperimentNN2opt,
} USKTSPExperiment;

@interface USKTSPExperimentManager : NSObject

@property USKTSPVisualizer *visualizer;

- (void)doExperiment:(USKTSPExperiment)experiment;

@end
