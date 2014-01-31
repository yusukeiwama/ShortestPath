//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "ViewController.h"
#import "TSP.h"
#import "TSPExperimentManager.h"
#import "TSPVisualizer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pathImageView;
@property (weak, nonatomic) IBOutlet UITableView *sampleNameTable;
@property (weak, nonatomic) IBOutlet UITableView *solverNameTable;

@property TSPVisualizer *visualizer;
@property TSPExperimentManager *experimentManager;
@property TSP *currentTSP;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.visualizer = [[TSPVisualizer alloc] init];
    self.visualizer.imageView = self.pathImageView;
    
    self.experimentManager = [[TSPExperimentManager alloc] init];
    self.experimentManager.visualizer = self.visualizer;
    
//    [self.experimentManager doExperiment:USKTSPExperimentMMAS2opt];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.sampleNameTable]) {
        return self.experimentManager.SampleNames.count;
    } else if ([tableView isEqual:self.solverNameTable]) {
        return self.experimentManager.solverNames.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *sampleNameCellIdentifier = @"sampleNameCell";
    static NSString *solverNameCellIdentifier = @"solverNameCell";
    
    UITableViewCell *cell;
    
    if ([tableView isEqual:self.sampleNameTable]) {
        cell = [tableView dequeueReusableCellWithIdentifier:sampleNameCellIdentifier];
        if (cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sampleNameCellIdentifier];
        }
        cell.textLabel.text = self.experimentManager.SampleNames[indexPath.row];
    } else if ([tableView isEqual:self.solverNameTable]) {
        cell = [tableView dequeueReusableCellWithIdentifier:solverNameCellIdentifier];
        if (cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:solverNameCellIdentifier];
        }
        cell.textLabel.text = self.experimentManager.solverNames[indexPath.row];
    }
    
    return cell;
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.sampleNameTable]) {
        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.experimentManager.SampleNames[indexPath.row] ofType:@"tsp"]];
        [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
    } else if ([tableView isEqual:self.solverNameTable]) {
        switch (indexPath.row) {
            case 0: {
                Tour tour = [self.currentTSP tourByNNFrom:1];
                [self.visualizer drawPath:tour ofTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
                break;
            }
            case 1: {
                Tour tour = [self.currentTSP tourByASWithNumberOfAnt:self.currentTSP.dimension
                                             pheromoneInfluence:1
                                            transitionInfluence:2
                                           pheromoneEvaporation:0.5
                                                           seed:rand()
                                                 noImproveLimit:200
                                              candidateListSize:20
                                                   CSVLogString:NULL];
                [self.visualizer drawPath:tour ofTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
                break;
            }
            case 2: {
               Tour tour = [self.currentTSP tourByMMAS2optWithNumberOfAnt:25
                                                   pheromoneInfluence:1
                                                  transitionInfluence:4
                                                 pheromoneEvaporation:0.1
                                                      probabilityBest:0.1
                                                                 seed:rand()
                                                       noImproveLimit:200
                                                    candidateListSize:20
                                                         CSVLogString:NULL];
                [self.visualizer drawPath:tour ofTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
                break;
            }
            case 3:
                break;
            default:
                break;
        }

    }
}

@end
