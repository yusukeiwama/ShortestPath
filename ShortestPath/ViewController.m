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

@property (weak, nonatomic) IBOutlet UIPickerView *samplePickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *solverPickerView;

@property (weak, nonatomic) IBOutlet UIView *solverTuningView;


@property TSPVisualizer *visualizer;
@property TSPExperimentManager *experimentManager;
@property TSP *currentTSP;
@property UIView *currentTuningView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.visualizer = [[TSPVisualizer alloc] init];
    self.visualizer.imageView = self.pathImageView;
    
    self.experimentManager = [[TSPExperimentManager alloc] init];
    self.experimentManager.visualizer = self.visualizer;
    
//    self.sampleNameTable.transform = CGAffineTransformRotate(self.sampleNameTable.transform, -M_PI / 6.0);
    
//    [self.experimentManager doExperiment:USKTSPExperimentMMAS2opt];
    


    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark - TableViewDataSource
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    if ([tableView isEqual:self.sampleNameTable]) {
//        return self.experimentManager.sampleNames.count;
//    } else if ([tableView isEqual:self.solverNameTable]) {
//        return self.experimentManager.solverNames.count;
//    } else {
//        return 0;
//    }
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *sampleNameCellIdentifier = @"sampleNameCell";
//    static NSString *solverNameCellIdentifier = @"solverNameCell";
//    
//    UITableViewCell *cell;
//    
//    if ([tableView isEqual:self.sampleNameTable]) {
//        cell = [tableView dequeueReusableCellWithIdentifier:sampleNameCellIdentifier];
//        if (cell) {
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sampleNameCellIdentifier];
//        }
//        cell.textLabel.text = self.experimentManager.sampleNames[indexPath.row];
//    } else if ([tableView isEqual:self.solverNameTable]) {
//        cell = [tableView dequeueReusableCellWithIdentifier:solverNameCellIdentifier];
//        if (cell) {
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:solverNameCellIdentifier];
//        }
//        cell.textLabel.text = self.experimentManager.solverNames[indexPath.row];
//    }
//    
//    return cell;
//}
//
//#pragma mark - TableViewDelegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([tableView isEqual:self.sampleNameTable]) {
//        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.experimentManager.sampleNames[indexPath.row] ofType:@"tsp"]];
//        [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
//    } else if ([tableView isEqual:self.solverNameTable]) {
//        //TODO: cancell previous procedure!
////        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//            switch (indexPath.row) {
//                case 0: {
//                    Tour tour = [self.currentTSP tourByNNFrom:1];
//                    [self.visualizer drawPath:tour ofTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
//                    break;
//                }
//                case 1: {
//                    Tour tour = [self.currentTSP tourByASWithNumberOfAnt:self.currentTSP.dimension
//                                                      pheromoneInfluence:1
//                                                     transitionInfluence:2
//                                                    pheromoneEvaporation:0.5
//                                                                    seed:rand()
//                                                          noImproveLimit:200
//                                                       candidateListSize:20
//                                                            CSVLogString:NULL];
//                    [self.visualizer drawPath:tour ofTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
//                    break;
//                }
//                case 2: {
//                    Tour tour = [self.currentTSP tourByMMAS2optWithNumberOfAnt:25
//                                                            pheromoneInfluence:1
//                                                           transitionInfluence:4
//                                                          pheromoneEvaporation:0.1
//                                                               probabilityBest:0.1
//                                                                          seed:rand()
//                                                                noImproveLimit:200
//                                                             candidateListSize:20
//                                                                  CSVLogString:NULL];
//                    [self.visualizer drawPath:tour ofTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
//                    break;
//                }
//                case 3:
//                    break;
//                default:
//                    break;
//            }
//       
////        });
// 
//    }
//}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([pickerView isEqual:self.samplePickerView]) {
        return self.experimentManager.sampleNames.count;
    } else if ([pickerView isEqual:self.solverPickerView]) {
        return self.experimentManager.solverNames.count;
    } else {
        return 0;
    }
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([pickerView isEqual:self.samplePickerView]) {
        return self.experimentManager.sampleNames[row];
    } else if ([pickerView isEqual:self.solverPickerView]) {
        return self.experimentManager.solverNames[row];
    } else {
        return nil;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    static NSString *ASTuningViewNibName = @"ASTuningView";
    static NSString *HumanTuningViewNibName = @"HumanTuningView";
    
    if ([pickerView isEqual:self.samplePickerView]) {
        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.experimentManager.sampleNames[row] ofType:@"tsp"]];
        [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:TSPVisualizationStyleLight];
    } else if ([pickerView isEqual:self.solverPickerView]) {
        switch (row) {
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

                NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:ASTuningViewNibName owner:self options:nil];
                UIView *myView = nibViews[0];
                [self.solverTuningView addSubview:myView];
                
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
                
                NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:ASTuningViewNibName owner:self options:nil];
                UIView *myView = nibViews[0];
                [self.solverTuningView addSubview:myView];
                
                break;
            }
            case 3: {
                
                NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:HumanTuningViewNibName owner:self options:nil];
                UIView *myView = nibViews[0];
                [self.solverTuningView addSubview:myView];
                
                break;
            }
            default:
                break;
        }
    } else {
        return;
    }

}


@end
