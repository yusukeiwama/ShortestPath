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

// Queue for cancellation.
@property NSOperationQueue *solverExecutionQueue;
@property NSBlockOperation *currentSolverOperation;


// Current TSP information
@property TSP           *currentTSP;
@property NSString      *currentTSPName;
@property (weak, nonatomic) IBOutlet UILabel *currentTSPLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTSPSolverTypeLabel;

// Visualization options
@property TSPVisualizationStyle currentVisualizationStyle;

// Log View
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property UITextView *fixedLogTextView;

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
    
    self.solverExecutionQueue   = [NSOperationQueue new];
    self.solverExecutionQueue.maxConcurrentOperationCount = 1;
    self.currentSolverOperation = [NSBlockOperation new];
	
    self.visualizer = [[TSPVisualizer alloc] init];
    self.visualizer.backgroundImaveView     = self.backgroundImageView;
    self.visualizer.globalBestPathImageView = self.globalBestPathImageView;
    self.visualizer.optimalPathImageView    = self.optimalPathImageView;
    self.visualizer.additionalImageView     = self.additionalImageView;
    self.visualizer.nodeImageView           = self.nodeImageView;
    
    self.experimentManager = [[TSPExperimentManager alloc] init];
    self.experimentManager.visualizer = self.visualizer;
    
    self.logString = [NSMutableString string];
    
    // Workaround until Apple fixes the choppy UITextView bug.
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer  options:NSNumericSearch] != NSOrderedAscending);
    
    if (osVersionSupported) {
        NSTextStorage* textStorage = [[NSTextStorage alloc] init];
        NSLayoutManager* layoutManager = [NSLayoutManager new];
        [textStorage addLayoutManager:layoutManager];
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.view.bounds.size];
        [layoutManager addTextContainer:textContainer];
        self.fixedLogTextView = [[UITextView alloc] initWithFrame:self.logTextView.frame
                                                    textContainer:textContainer];
        self.fixedLogTextView.font = [UIFont fontWithName:@"menlo" size:11.0];
        self.fixedLogTextView.editable = NO;
        self.fixedLogTextView.backgroundColor = [UIColor clearColor];
        self.fixedLogTextView.textColor = [UIColor whiteColor];
        [self.logView addSubview:self.fixedLogTextView];
        [self.logTextView removeFromSuperview];
    }

//    [self.experimentManager doExperiment:USKTSPExperimentMMAS2opt];
    
    // Default Setting
    self.currentTSPName = @"st70";
    self.currentTSPLabel.text = self.currentTSPName;
    
    self.currentSolverType = TSPSolverTypeNN;
    self.currentTSPSolverTypeLabel.text = @"Nearest Neighbor";
    
    self.currentVisualizationStyle = TSPVisualizationStyleDark;
    self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
    [self.logString appendString:[self.currentTSP informationString]];
    self.fixedLogTextView.text = self.logString;
    [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:self.currentVisualizationStyle];

    self.saveButton.layer.cornerRadius  =
    self.stepButton.layer.cornerRadius  =
    self.stopButton.layer.cornerRadius  = self.stopButton.frame.size.width / 2.0;
    self.solveButton.layer.cornerRadius = self.solveButton.frame.size.width / 2.0;
    self.saveButton.layer.borderWidth   =
    self.stepButton.layer.borderWidth   =
    self.stopButton.layer.borderWidth   =
    self.solveButton.layer.borderWidth  = 1.0;
    self.saveButton.layer.borderColor   =
    self.stepButton.layer.borderColor   =
    self.stopButton.layer.borderColor   =
    self.solveButton.layer.borderColor  = [[UIColor colorWithWhite:1.0 alpha:0.5] CGColor];
    
    self.pathImageUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(visualizeLog) userInfo:nil repeats:YES];
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


- (void)visualizeLog
{
    // Suspend solving operation when log queue have enough data to visualize. (prevent memory pressure.)
    // Limit memory allocation for pheromone matrix in 200MB.
    int n = self.currentTSP.dimension;
    int capacity = 200000000 / (n * n * sizeof(double));
    if ([self.currentTSP.logQueue count] > capacity) {
        [self.currentTSP.operationQueue setSuspended:YES];
    } else if ([self.currentTSP.operationQueue isSuspended] == YES && [self.currentTSP.logQueue count] < 10) {
        [self.currentTSP.operationQueue setSuspended:NO];
    }
    
    NSDictionary *logDictionary = [self.currentTSP.logQueue dequeue];
    if (logDictionary == nil) {
        return;
    }

    Tour *tour_p = [((NSValue *)logDictionary[@"Tour"]) pointerValue];
    if (tour_p != NULL) {
        [self.visualizer drawPath:*tour_p ofTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
        free(tour_p->route);
        free(tour_p);
    }

    double *P      = [((NSValue *)logDictionary[@"Pheromone"]) pointerValue];
    if (P != NULL) {
        [self.visualizer drawPheromone:P ofTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
        free(P);
    }
    
    NSString *aLog = logDictionary[@"Log"];
    if (aLog) {
        [self.logString appendString:aLog];
    }
    self.fixedLogTextView.text = self.logString;
    if (self.fixedLogTextView.text.length > 0) {
        NSRange bottomRange = NSMakeRange(self.fixedLogTextView.text.length - 1, 1);
        [self.fixedLogTextView scrollRangeToVisible:bottomRange];
    }
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
    [self clearCurrentSolvingContext];
    
    if ([tableView isEqual:self.problemTableView]) { // Change current problem.
        self.currentTSP.aborted = YES;
        self.currentTSPName = self.experimentManager.sampleNames[indexPath.row];
        self.currentTSPLabel.text = self.currentTSPName;
        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
        [self.logString setString:@""];
        
        // Draw nodes
        [self.visualizer clearTSPVisualization];
        [self.visualizer drawNodesWithTSP:self.currentTSP withStyle:self.currentVisualizationStyle];
        
        // Display TSP information
        [self.logString appendString:[self.currentTSP informationString]];
        self.fixedLogTextView.text = self.logString;
        // Scroll to bottom.
        if (self.fixedLogTextView.text.length > 0) {
            NSRange bottomRange = NSMakeRange(self.fixedLogTextView.text.length - 1, 1);
            [self.fixedLogTextView scrollRangeToVisible:bottomRange];
        }
        
    } else if ([tableView isEqual:self.solverTableView]) { // Change current solver.
        NSString *solverName = self.experimentManager.solverNames[indexPath.row];
        self.currentTSPSolverTypeLabel.text = solverName;
        
        self.currentTSP.aborted = YES;
        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
        switch (indexPath.row) {
            case 0:
                self.currentSolverType = TSPSolverTypeNN;
                self.currentVisualizationStyle = TSPVisualizationStyleDark;
                break;
            case 1:
                self.currentSolverType = TSPSolverTypeAS;
                self.currentVisualizationStyle = TSPVisualizationStyleOcean;
                break;
            case 2:
                self.currentSolverType = TSPSolverTypeMMAS;
                self.currentVisualizationStyle = TSPVisualizationStyleOcean;
                break;
            default:
                break;
        }
    }
}

#pragma mark - Button Actions
- (IBAction)solve:(id)sender
{
    [self clearCurrentSolvingContext];

    self.currentTSP.aborted = YES;
    self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
   
    switch (self.currentSolverType) {
        case TSPSolverTypeNN: {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                [self.currentTSP tourByNNFrom:rand() % self.currentTSP.dimension + 1
                                      use2opt:YES];
            }];
            [self.solverExecutionQueue addOperation:operation];
            break;
        }
        case TSPSolverTypeAS: {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self.currentTSP tourByASWithNumberOfAnt:self.currentTSP.dimension
                                         pheromoneInfluence:1
                                        transitionInfluence:2
                                       pheromoneEvaporation:0.5
                                                       seed:rand()
                                             noImproveLimit:200
                                          candidateListSize:20
                                                    use2opt:YES
                                               CSVLogString:nil];
            }];
            [self.solverExecutionQueue addOperation:operation];
            break;
        }
        case TSPSolverTypeMMAS: {
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self.currentTSP tourByMMASWithNumberOfAnt:25
                                           pheromoneInfluence:1
                                          transitionInfluence:4
                                         pheromoneEvaporation:0.2
                                              probabilityBest:0.01
                                                         seed:rand()
                                               noImproveLimit:200
                                            candidateListSize:20
                                                      use2opt:YES
                                                 CSVLogString:nil];
            }];
            [self.solverExecutionQueue addOperation:operation];
            break;
        }
        default:
            break;
    }
}

- (void)clearCurrentSolvingContext
{
    [self.solverExecutionQueue cancelAllOperations];

    // maybe not necessary (TSP is responsible for flush queue when dealloc.)
//    [self.currentTSP flushTours];
//    [self.currentTSP flushMatrices];
    
    [self.visualizer clearTSPTour];
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
    if (self.expandingPanel) { // expanding.
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
                             self.fixedLogTextView.frame = CGRectMake(0, 46, 330, 156);
                             // Scroll to bottom.
                             if (self.fixedLogTextView.text.length > 0) {
                                 NSRange bottomRange = NSMakeRange(self.fixedLogTextView.text.length - 1, 1);
                                 [self.fixedLogTextView scrollRangeToVisible:bottomRange];
                             }

                         }];
        self.expandingPanel = ExpandingPanelNone;
    } else { // not expanding.
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
                                 self.fixedLogTextView.frame = CGRectMake(0, 46, 330, 486);
                                 // Scroll to bottom.
                                 if (self.fixedLogTextView.text.length > 0) {
                                     NSRange bottomRange = NSMakeRange(self.fixedLogTextView.text.length - 1, 1);
                                     [self.fixedLogTextView scrollRangeToVisible:bottomRange];
                                 }

                             }];
            self.expandingPanel = ExpandingPanelLog;
        }
    }
}

@end
