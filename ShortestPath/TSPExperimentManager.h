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
    USKTSPExperimentMMASTuning,
    USKTSPExperimentMMAS,
    USKTSPExperimentMMAS2optTuning,
    USKTSPExperimentMMAS2opt,
    USKTSPExperimentTSPTrial,
	USKTSPExperimentOptimal
} USKTSPExperiment;

@interface TSPExperimentManager : NSObject

@property TSPVisualizer *visualizer;
@property NSArray       *sampleNames;
@property NSArray       *solverNames;

- (void)doExperiment:(USKTSPExperiment)experiment;

@end


/**
 異なるアルゴリズムを比較するときは解の作成回数を同じにして考える。
 2-optの１回を１回とする
 同じOのものを同じコストとかんがえる。
*/

/*
 All files
 @[@"a280", @"ali535", @"att48", @"att532", @"bayg29", @"bays29", @"berlin52", @"bier127", @"brazil58", @"brd14051",	@"brg180", @"burma14", @"ch130", @"ch150", @"d198", @"d493", @"d657", @"d1291", @"d1655", @"d2103", @"d15112", @"d18512", @"dantzig42", @"dsj1000", @"eil51", @"eil76", @"eil101", @"fl417", @"fl1400", @"fl1577", @"fl3795", @"fnl4461", @"fri26", @"gil262", @"gr17", @"gr21", @"gr24", @"gr48", @"gr96", @"gr120", @"gr137", @"gr202", @"gr229", @"gr431", @"gr666", @"hk48", @"kroA100", @"kroB100", @"kroC100", @"kroD100", @"kroE100", @"kroA150", @"kroB150", @"kroA200", @"kroB200", @"lin105", @"lin318", @"linhp318", @"nrw1379", @"p654", @"pa561", @"pcb442", @"pcb1173", @"pcb3038", @"pla7397", @"pla33810", @"pla85900", @"pr76", @"pr107", @"pr124", @"pr136", @"pr144", @"pr152", @"pr226", @"pr264", @"pr299", @"pr439", @"pr1002", @"pr2392", @"rat99", @"rat195", @"rat575", @"rat783", @"rd100", @"rd400", @"rl1304", @"rl1323", @"rl1889", @"rl5915", @"rl5934", @"rl11849", @"si175", @"si535", @"si1032", @"st70", @"swiss42", @"ts225", @"tsp225", @"u159", @"u574", @"u724", @"u1060", @"u1432", @"u1817", @"u2152", @"u2319", @"ulysses16", @"ulysses22", @"usa13509", @"vm1084", @"vm1748"]
*/