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
    USKTSPExperimentASTuningBeta,
    USKTSPExperimentAS,
    USKTSPExperimentMMASTuningBeta,
    USKTSPExperimentMMAS,
	USKTSPExperimentOptimal
} USKTSPExperiment;

@interface TSPExperimentManager : NSObject

@property TSPVisualizer *visualizer;

- (void)doExperiment:(USKTSPExperiment)experiment;

@end


/**
 異なるアルゴリズムを比較するときは解の作成回数を同じにして考える。
 2-optの１回を１回とする
 同じOのものを同じコストとかんがえる。
*/