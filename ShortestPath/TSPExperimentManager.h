//
//  USKTSPExperimentManager.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 1/26/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TSPVisualizer;

typedef enum USKTSPExperiment {
	USKTSPExperimentNN,
	USKTSPExperimentNN2opt,
    USKTSPExperimentASTuning,
    USKTSPExperimentAS,
	USKTSPExperimentOptimal
} USKTSPExperiment;

@interface TSPExperimentManager : NSObject

@property TSPVisualizer *visualizer;

- (void)doExperiment:(USKTSPExperiment)experiment;

@end
