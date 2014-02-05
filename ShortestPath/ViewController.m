//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "ViewController.h"
#import "TSPExperimentManager.h"
#import "TSPVisualizer.h"
#import "TSPTourQueue.h"

typedef enum _ExpandingPanel {
    ExpandingPanelNone = 0,
    ExpandingPanelProblem = 1,
    ExpandingPanelSolver,
    ExpandingPanelLog,
} ExpandingPanel;

@interface ViewController ()

// For visualizer
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *optimalPathImageView;
@property (weak, nonatomic) IBOutlet UIImageView *globalBestPathImageView;
@property (weak, nonatomic) IBOutlet UIImageView *additionalImageView;
@property (weak, nonatomic) IBOutlet UIImageView *nodeImageView;
@property NSTimer *pathImageUpdateTimer;

@property (weak, nonatomic) IBOutlet UIView *monitorView;

@property (weak, nonatomic) IBOutlet UIView *controlView;

// TableViews
@property (weak, nonatomic) IBOutlet UITableView *problemTableView;
@property (weak, nonatomic) IBOutlet UITableView *solverTableView;
@property (weak, nonatomic) IBOutlet UIButton *problemTableButton;
@property (weak, nonatomic) IBOutlet UIButton *solverTableButton;
@property (weak, nonatomic) IBOutlet UIButton *logTextViewButton;
@property (weak, nonatomic) IBOutlet UIImageView *problemExpandIndicatorImageView;
@property (weak, nonatomic) IBOutlet UIImageView *solverExpandIndicatorImaveView;
@property (weak, nonatomic) IBOutlet UIImageView *logExpandIndicatorImageView;
@property (weak, nonatomic) IBOutlet UIView *problemView;
@property (weak, nonatomic) IBOutlet UIView *solverView;
@property (weak, nonatomic) IBOutlet UIView *logView;
@property ExpandingPanel expandingPanel;

// TSP supporting classes
@property TSPVisualizer        *visualizer;
@property TSPExperimentManager *experimentManager;

// Current TSP information
@property TSP           *currentTSP;
@property (weak, nonatomic) IBOutlet UILabel *currentTSPLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTSPSolverTypeLabel;

// Visualization options
@property TSPVisualizationStyle currentVisualizationStyle;

// Log View
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property NSMutableString *logString;

// Control buttons
@property (weak, nonatomic) IBOutlet UIButton *solveButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *stepButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end

@implementation ViewController

// synthesize to override setter to set TSP's client property.
@synthesize currentTSP = _currentTSP;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
	
    self.visualizer = [[TSPVisualizer alloc] init];
    self.visualizer.backgroundImaveView     = self.backgroundImageView;
    self.visualizer.globalBestPathImageView = self.globalBestPathImageView;
    self.visualizer.optimalPathImageView    = self.optimalPathImageView;
    self.visualizer.additionalImageView     = self.additionalImageView;
    self.visualizer.nodeImageView           = self.nodeImageView;
    
    self.experimentManager = [[TSPExperimentManager alloc] init];
    self.experimentManager.visualizer = self.visualizer;
    
    self.logString = [NSMutableString string];

//    [self.experimentManager doExperiment:USKTSPExperimentMMAS2opt];
    
    // Default Setting
    NSString *defaultSampleName = @"tsp225";
    self.currentSolverType = TSPSolverTypeNN;
    self.currentTSPLabel.text = defaultSampleName;
    self.currentTSPSolverTypeLabel.text = @"Nearest Neighbor";
    
    self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:defaultSampleName ofType:@"tsp"]];
    Tour optimalTour = [TSP optimalSolutionWithName:defaultSampleName];
    self.currentVisualizationStyle = TSPVisualizationStyleOcean;
//    [self.visualizer drawBackgroundWithStyle:self.currentVisualizationStyle];
    [self.visualizer drawPath:optimalTour ofTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
    [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:self.currentVisualizationStyle];

    self.saveButton.layer.cornerRadius  =
    self.stepButton.layer.cornerRadius  =
    self.stopButton.layer.cornerRadius  = 30.0;
    self.solveButton.layer.cornerRadius = 50.0;
    self.saveButton.layer.borderWidth   =
    self.stepButton.layer.borderWidth   =
    self.stopButton.layer.borderWidth   = 1.0;
    self.solveButton.layer.borderWidth  = 1.5;
    self.saveButton.layer.borderColor   =
    self.stepButton.layer.borderColor   =
    self.stopButton.layer.borderColor   =
    self.solveButton.layer.borderColor  = [[UIColor colorWithWhite:1.0 alpha:0.5] CGColor];
    
    self.pathImageUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(dequeuePathToDrawPathImage) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (TSP *)currentTSP
{
    return _currentTSP;
}

- (void)setCurrentTSP:(TSP *)currentTSP
{
    _currentTSP = currentTSP;
    _currentTSP.client = self;
}


- (void)dequeuePathToDrawPathImage
{
    // Choose which dequeue to enqueue according to current solver type.
    Tour *tour_p = NULL;
    switch (self.currentSolverType) {
        case TSPSolverTypeNN:
            tour_p = [self.currentTSP dequeueTourFromQueueType:TSPTourQueueTypeNN];
            if (tour_p == NULL) {
                tour_p = [self.currentTSP dequeueTourFromQueueType:TSPTourQueueType2opt];
            }
            break;
        case TSPSolverTypeAS:
            tour_p = [self.currentTSP dequeueTourFromQueueType:TSPTourQueueTypeAS];
            break;
        case TSPSolverTypeMMAS:
            tour_p = [self.currentTSP dequeueTourFromQueueType:TSPTourQueueTypeAS];
            break;
        default:
            break;
    }
    
    if (tour_p == NULL) {
        return;
    }
    
    [self.visualizer drawPath:*tour_p ofTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
    free(tour_p->route);
}

#pragma mark - TableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.problemTableView]) {
        return self.experimentManager.sampleNames.count;
    } else if ([tableView isEqual:self.solverTableView]) {
        return self.experimentManager.solverNames.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *sampleNameCell           = @"sampleNameCell";
    static NSString *solverNameCellIdentifier = @"solverNameCell";
    
    UITableViewCell *cell;
    if ([tableView isEqual:self.problemTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:sampleNameCell];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sampleNameCell];
        }
        // Set Highlight color
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor colorWithRed:(76.0/255.0) green:(161.0/255.0) blue:(255.0/255.0) alpha:1.0]; // perfect color suggested by @mohamadHafez
        bgColorView.layer.masksToBounds = YES;
        cell.selectedBackgroundView = bgColorView;

        cell.textLabel.text  = self.experimentManager.sampleNames[indexPath.row];
        cell.backgroundColor = [UIColor clearColor];
    } else if ([tableView isEqual:self.solverTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:solverNameCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:solverNameCellIdentifier];
        }
        // Set Highlight color
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor colorWithRed:(76.0/255.0) green:(161.0/255.0) blue:(255.0/255.0) alpha:1.0]; // perfect color suggested by @mohamadHafez
        bgColorView.layer.masksToBounds = YES;
        cell.selectedBackgroundView = bgColorView;

        cell.textLabel.text  = self.experimentManager.solverNames[indexPath.row];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    return cell;
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.problemTableView]) {
        [self.currentTSP flushTours];
        NSString *sampleName = self.experimentManager.sampleNames[indexPath.row];
        self.currentTSPLabel.text = sampleName;
        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:sampleName ofType:@"tsp"]];
        // Draw nodes
        [self.visualizer clearTSPVisualization];
        [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
        
        // Display TSP information
        [self.logString appendString:[self.currentTSP informationString]];
        self.logTextView.text = self.logString;
        if (self.logTextView.text.length > 0) {
            NSRange bottomRange = NSMakeRange(self.logTextView.text.length - 1, 1);
            [self.logTextView scrollRangeToVisible:bottomRange];
        }
        
    } else if ([tableView isEqual:self.solverTableView]) {
        [self.currentTSP flushTours];
        NSString *solverName = self.experimentManager.solverNames[indexPath.row];
        self.currentTSPSolverTypeLabel.text = solverName;
        
        switch (indexPath.row) {
            case 0:
                self.currentSolverType = TSPSolverTypeNN;
                break;
            case 1:
                self.currentSolverType = TSPSolverTypeAS;
                break;
            case 2:
                self.currentSolverType = TSPSolverTypeMMAS;
                break;
            default:
                break;
        }
    }
}

#pragma mark - Button Actions
- (IBAction)solve:(id)sender
{
    Tour tour;
    
    switch (self.currentSolverType) {
        case TSPSolverTypeNN: {
            tour = [self.currentTSP tourByNNFrom:rand() % self.currentTSP.dimension + 1
                                         use2opt:YES];
            [self.currentTSP improveTourBy2opt:&tour];
            break;
        }
        case TSPSolverTypeAS: {
            tour = [self.currentTSP tourByASWithNumberOfAnt:self.currentTSP.dimension
                                         pheromoneInfluence:1
                                        transitionInfluence:2
                                       pheromoneEvaporation:0.5
                                                       seed:rand()
                                             noImproveLimit:1000
                                          candidateListSize:20
                                                    use2opt:YES
                                               CSVLogString:nil];
            break;
        }
        case TSPSolverTypeMMAS: {
            tour = [self.currentTSP tourByMMASWithNumberOfAnt:25
                                           pheromoneInfluence:1
                                          transitionInfluence:4
                                         pheromoneEvaporation:0.2
                                              probabilityBest:0.01
                                                         seed:rand()
                                               noImproveLimit:200
                                            candidateListSize:20
                                                      use2opt:YES
                                                 CSVLogString:nil];
            break;
        }
        default:
            break;
    }
    
//    [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
//    [self.visualizer drawPath:tour toIndex:self.currentTSP.dimension - 1 ofTSP:self.currentTSP withStyle:self.currentVisualizationStyle];

}



- (IBAction)hideControls:(id)sender {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.controlView.frame = CGRectMake(1024, 32, 330, 708);
                         self.monitorView.frame = CGRectMake( 192, 64, 640, 640);
                     }
                     completion:^(BOOL finished){
                     }];
}

- (IBAction)showControls:(id)sender {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.controlView.frame = CGRectMake(674, 32, 330, 708);
                         self.monitorView.frame = CGRectMake( 20, 32, 640, 640);
                     }
                     completion:^(BOOL finished){
                     }];
}

- (IBAction)expandPanel:(id)sender
{
    if (self.expandingPanel) {
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.problemView.frame = CGRectMake(0, 0, 330, 211);
                             self.problemTableView.frame = CGRectMake(0, 46, 330, 165);
                             self.solverView.frame = CGRectMake(0, 219, 330, 211);
                             self.logView.frame = CGRectMake(0, 438, 330, 202);
                             switch (self.expandingPanel) {
                                 case ExpandingPanelProblem:
                                     self.problemExpandIndicatorImageView.transform = CGAffineTransformRotate(self.problemExpandIndicatorImageView.transform, -M_PI_2);
                                     self.solverExpandIndicatorImaveView.transform = CGAffineTransformRotate(self.solverExpandIndicatorImaveView.transform, +M_PI_2);
                                     self.logExpandIndicatorImageView.transform = CGAffineTransformRotate(self.logExpandIndicatorImageView.transform, +M_PI_2);
                                     break;
                                 case ExpandingPanelSolver:
                                     self.problemExpandIndicatorImageView.transform = CGAffineTransformRotate(self.problemExpandIndicatorImageView.transform, +M_PI_2);
                                     self.solverExpandIndicatorImaveView.transform = CGAffineTransformRotate(self.solverExpandIndicatorImaveView.transform, -M_PI_2);
                                     self.logExpandIndicatorImageView.transform = CGAffineTransformRotate(self.logExpandIndicatorImageView.transform, +M_PI_2);
                                     break;
                                 case ExpandingPanelLog:
                                     self.problemExpandIndicatorImageView.transform = CGAffineTransformRotate(self.problemExpandIndicatorImageView.transform, +M_PI_2);
                                     self.solverExpandIndicatorImaveView.transform = CGAffineTransformRotate(self.solverExpandIndicatorImaveView.transform, +M_PI_2);
                                     self.logExpandIndicatorImageView.transform = CGAffineTransformRotate(self.logExpandIndicatorImageView.transform, -M_PI_2);
                                     break;
                                 default:
                                     break;
                             }
                         }
                         completion:^(BOOL finished){
                         }];
        self.expandingPanel = ExpandingPanelNone;
    } else {
        if ([sender isEqual:self.problemTableButton]) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.problemView.frame = CGRectMake(0, 0, 330, 532);
                                 self.solverView.frame = CGRectMake(0, 540, 330, 46);
                                 self.logView.frame = CGRectMake(0, 594, 330, 46);
                                 self.problemExpandIndicatorImageView.transform = CGAffineTransformRotate(self.problemExpandIndicatorImageView.transform, +M_PI_2);
                                 self.solverExpandIndicatorImaveView.transform = CGAffineTransformRotate(self.solverExpandIndicatorImaveView.transform, -M_PI_2);
                                 self.logExpandIndicatorImageView.transform = CGAffineTransformRotate(self.logExpandIndicatorImageView.transform, -M_PI_2);
                             }
                             completion:^(BOOL finished){
                                 self.problemTableView.frame = CGRectMake(0, 46, 330, 486);
                             }];
            self.expandingPanel = ExpandingPanelProblem;
        } else if ([sender isEqual:self.solverTableButton]) {
            self.expandingPanel = ExpandingPanelSolver;
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.problemView.frame = CGRectMake(0, 0, 330, 46);
                                 self.solverView.frame = CGRectMake(0, 54, 330, 532);
                                 self.logView.frame = CGRectMake(0, 594, 330, 46);
                                 self.problemExpandIndicatorImageView.transform = CGAffineTransformRotate(self.problemExpandIndicatorImageView.transform, -M_PI_2);
                                 self.solverExpandIndicatorImaveView.transform = CGAffineTransformRotate(self.solverExpandIndicatorImaveView.transform, +M_PI_2);
                                 self.logExpandIndicatorImageView.transform = CGAffineTransformRotate(self.logExpandIndicatorImageView.transform, -M_PI_2);
                             }
                             completion:^(BOOL finished){
                                 self.solverTableView.frame = CGRectMake(0, 46, 330, 486);
                             }];
            self.expandingPanel = ExpandingPanelSolver;
        } else if ([sender isEqual:self.logTextViewButton]) {
            self.expandingPanel = ExpandingPanelLog;
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.problemView.frame = CGRectMake(0, 0, 330, 46);
                                 self.solverView.frame = CGRectMake(0, 54, 330, 46);
                                 self.logView.frame = CGRectMake(0, 108, 330, 532);
                                 self.problemExpandIndicatorImageView.transform = CGAffineTransformRotate(self.problemExpandIndicatorImageView.transform, -M_PI_2);
                                 self.solverExpandIndicatorImaveView.transform = CGAffineTransformRotate(self.solverExpandIndicatorImaveView.transform, -M_PI_2);
                                 self.logExpandIndicatorImageView.transform = CGAffineTransformRotate(self.logExpandIndicatorImageView.transform, +M_PI_2);
                             }
                             completion:^(BOOL finished){
                                 self.logTextView.frame = CGRectMake(0, 46, 330, 486);
                             }];
            self.expandingPanel = ExpandingPanelLog;
        }
    }
}

@end
