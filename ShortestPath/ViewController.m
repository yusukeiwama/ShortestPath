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
#import "USKTSPCSVParser.h"
#import "TSPView.h"

typedef enum _ExpandingPanel {
    ExpandingPanelNone = 0,
    ExpandingPanelProblem = 1,
    ExpandingPanelSolver,
    ExpandingPanelLog,
} ExpandingPanel;

typedef enum _TSPViewControllerSkin {
    TSPViewControllerSkinOcean       = 0,
    TSPViewControllerSkinStarryNight = 1,
    TSPViewControllerSkinBlack       = 2,
    TSPViewControllerSkinWhite       = 3,
} TSPViewControllerSkin;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

/** Monitor view on the left of the screen. ================================= */
@property (weak, nonatomic) IBOutlet UIView  *monitorView;
@property (weak, nonatomic) IBOutlet UILabel *layerTitleLabel;
@property TSPView *tspView;
@property NSTimer *pathImageUpdateTimer;
/* ========================================================================== */

/** Control views on the right of the screen. ================================ */
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UILabel *currentTSPLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTSPSolverTypeLabel;

// TableViews
@property (weak, nonatomic) IBOutlet UIView      *problemView;
@property (weak, nonatomic) IBOutlet UITableView *problemTableView;
@property (weak, nonatomic) IBOutlet UIView      *problemHeaderView;
@property (weak, nonatomic) IBOutlet UIButton    *problemTableButton;
@property (weak, nonatomic) IBOutlet UIImageView *problemExpandIndicatorImageView;

@property (weak, nonatomic) IBOutlet UIView      *solverView;
@property (weak, nonatomic) IBOutlet UITableView *solverTableView;
@property (weak, nonatomic) IBOutlet UIView      *solverHeaderView;
@property (weak, nonatomic) IBOutlet UIButton    *solverTableButton;
@property (weak, nonatomic) IBOutlet UIImageView *solverExpandIndicatorImaveView;

@property (weak, nonatomic) IBOutlet UIView      *logView;
@property (weak, nonatomic) IBOutlet UIView      *logHeaderView;
@property (weak, nonatomic) IBOutlet UIButton    *logTextViewButton;
@property (weak, nonatomic) IBOutlet UIImageView *logExpandIndicatorImageView;
@property (weak, nonatomic) IBOutlet UITextView  *logTextView;
@property                            UITextView  *fixedLogTextView;

@property ExpandingPanel expandingPanel; // enum: which panel is expanding now
@property UIColor *cellHighlightedColor;
@property UIColor *headerViewColor;

// Control buttons
@property (weak, nonatomic) IBOutlet UIButton *solveButton;
@property (weak, nonatomic) IBOutlet UIButton *stepButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
/* ========================================================================== */

// TSP supporting classes
@property TSPVisualizer        *visualizer;
@property TSPExperimentManager *experimentManager;

// Queue for cancellation.
@property NSOperationQueue *solverExecutionQueue;
@property NSBlockOperation *currentSolverOperation;

// Current TSP information
@property TSP      *currentTSP;
@property NSString *currentTSPName;

// Styles
@property TSPViewControllerSkin skin;
@property TSPVisualizationStyle currentVisualizationStyle;

@end

@implementation ViewController

// synthesize to override setter to set TSP's client property.
@synthesize currentTSP = _currentTSP;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Prevent crash on iOS 6.
    if ([self canPerformAction:@selector(setNeedsStatusBarAppearanceUpdate) withSender:nil]) {
            [self setNeedsStatusBarAppearanceUpdate];
    }
    
    // Load welcome TSP problem from CSV.
//    USKTSPCSVParser *parser = [USKTSPCSVParser new];
//    [parser TSPWithCSV:[[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"csv"]];
    
    self.solverExecutionQueue   = [NSOperationQueue new];
    self.solverExecutionQueue.maxConcurrentOperationCount = 1;
    self.currentSolverOperation = [NSBlockOperation new];
	
    self.tspView = [[TSPView alloc] initWithFrame:CGRectMake(0, 0, self.monitorView.frame.size.width, self.monitorView.frame.size.height)];
    [self.monitorView addSubview:self.tspView];
    
    self.visualizer = [[TSPVisualizer alloc] init];
    self.visualizer.view = self.tspView;
    
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
        self.fixedLogTextView.selectable = NO;
        self.fixedLogTextView.backgroundColor = [UIColor clearColor];
        self.fixedLogTextView.textColor = [UIColor whiteColor];
        [self.logView addSubview:self.fixedLogTextView];
        [self.logTextView removeFromSuperview];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.fixedLogTextView.frame = CGRectMake(self.monitorView.frame.origin.x + 12.0,
                                                     self.monitorView.frame.origin.y,
                                                     self.monitorView.frame.size.width - 24.0,
                                                     self.monitorView.frame.size.height - 24.0);
            [self.view addSubview:self.fixedLogTextView];
            self.fixedLogTextView.hidden = YES;
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchLayer:)];
            [self.fixedLogTextView addGestureRecognizer:tapRecognizer];
        }
        
    } else {
        self.fixedLogTextView = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.logTextView.frame = CGRectMake(self.monitorView.frame.origin.x + 12.0,
                                                     self.monitorView.frame.origin.y,
                                                     self.monitorView.frame.size.width - 24.0,
                                                     self.monitorView.frame.size.height - 24.0);
            [self.view addSubview:self.logTextView];
            self.logTextView.hidden = YES;
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchLayer:)];
            [self.logTextView addGestureRecognizer:tapRecognizer];
        }

    }
    
//    [self.experimentManager doExperiment:USKTSPExperimentMMAS2opt];
    
    // Load default problem
    self.currentTSPName = @"welcome91";
    self.currentTSPLabel.text = self.currentTSPName;

    self.currentSolverType = TSPSolverTypeNN;
    self.currentTSPSolverTypeLabel.text = @"Nearest Neighbor";
    
    self.currentVisualizationStyle = TSPVisualizationStyleDark;
    self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
    [self.logString appendString:[self.currentTSP informationString]];
    if (osVersionSupported) {
    self.fixedLogTextView.text = self.logString;
    } else {
        self.logTextView.text = self.logString;
    }
    [self.visualizer drawNodesWithTSP:self.currentTSP];
    
    // Draw optimal tour if available
    if (self.currentTSP.optimalTour.route != NULL) {
        [self.visualizer drawOptimalTour:[TSP optimalSolutionWithName:self.currentTSPName] withTSP:self.currentTSP];
    }

    // Round button layer.
    self.saveButton.layer.cornerRadius  =
    self.stepButton.layer.cornerRadius  = self.stepButton.frame.size.width / 2.0;
    self.solveButton.layer.cornerRadius = self.solveButton.frame.size.width / 2.0;
    self.saveButton.layer.borderWidth   =
    self.stepButton.layer.borderWidth   =
    self.solveButton.layer.borderWidth  = 1.0;
    self.saveButton.layer.borderColor   =
    self.stepButton.layer.borderColor   =
    self.solveButton.layer.borderColor  = [[UIColor colorWithWhite:1.0 alpha:0.5] CGColor];
    
    self.pathImageUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(visualizeLog) userInfo:nil repeats:YES];
    
    self.skin = TSPViewControllerSkinStarryNight;
    [self prepareSkin];
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
    if (n <= 0) {
        return;
    }
    int capacity = 200000000 / (n * n * sizeof(double));
    if ([self.currentTSP.logQueue count] > capacity) {
        [self.currentTSP.operationQueue setSuspended:YES];
    } else if ([self.currentTSP.operationQueue isSuspended] == YES && [self.currentTSP.logQueue count] < 3) {
        [self.currentTSP.operationQueue setSuspended:NO];
    }
    
    NSDictionary *logDictionary = [self.currentTSP.logQueue dequeue];
    static int countToChangeTitle = 0;
    if (logDictionary == nil) {
        // Prevent fluctuating solve button title when start solving and no log in queue.
        if (countToChangeTitle < 100) {
            countToChangeTitle++;
        }
        if ([self.solveButton.titleLabel.text isEqualToString:@"Solve"] == NO
            && [self.currentTSP.logQueue count] == 0
            && countToChangeTitle > 30) { // Did finish solving.
            [self.solveButton setTitle:@"Solve" forState:UIControlStateNormal];
        }
        return;
    } else {
        countToChangeTitle = 0;
    }
    
    if ([self.solveButton.titleLabel.text isEqualToString:@"Solving"] == NO) {
        [self.solveButton setTitle:@"Solving" forState:UIControlStateNormal];
    }


    Tour *tour_p = [((NSValue *)logDictionary[@"Tour"]) pointerValue];
    if (tour_p != NULL) {
        if (self.currentSolverType == TSPSolverTypeNN) {
            [self.visualizer drawDirectionalTour:*tour_p withTSP:self.currentTSP];
        } else {
            [self.visualizer drawTour:*tour_p withTSP:self.currentTSP];
        }
        free(tour_p->route);
        free(tour_p);
    }

    double *P   = [((NSValue *)logDictionary[@"Pheromone"]) pointerValue];
    if (P != NULL) {
        [self.visualizer drawPheromone:P withTSP:self.currentTSP];
        free(P);
    }
    
    NSString *aLog = logDictionary[@"Log"];
    if (aLog) {
        [self.logString appendString:aLog];
    }
    if (self.fixedLogTextView) {
        self.fixedLogTextView.text = self.logString;
        if (self.fixedLogTextView.text.length > 0) {
            NSRange bottomRange = NSMakeRange(self.fixedLogTextView.text.length - 1, 1);
            [self.fixedLogTextView scrollRangeToVisible:bottomRange];
        }
    } else {
        self.logTextView.text = self.logString;
        if (self.logTextView.text.length > 0) {
            NSRange bottomRange = NSMakeRange(self.logTextView.text.length - 1, 1);
            [self.logTextView scrollRangeToVisible:bottomRange];
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.problemTableView]) {
        switch (section) {
            case 0: return self.experimentManager.sampleNames.count;
            case 1: return 1;
        }

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
        // Set Highlight color
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = self.cellHighlightedColor;
        bgColorView.layer.masksToBounds = YES;

        switch (indexPath.section) {
            case 0:
                cell = [tableView dequeueReusableCellWithIdentifier:sampleNameCell];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sampleNameCell];
                }
                cell.selectedBackgroundView = bgColorView;
                cell.textLabel.text  = self.experimentManager.sampleNames[indexPath.row];
                cell.backgroundColor = [UIColor clearColor];
                break;
            case 1:
                cell = [tableView dequeueReusableCellWithIdentifier:sampleNameCell];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sampleNameCell];
                }
                cell.selectedBackgroundView = bgColorView;
                cell.textLabel.text  = @"welcome91";
                cell.backgroundColor = [UIColor clearColor];
                break;
            default:
                break;
        }
    } else if ([tableView isEqual:self.solverTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:solverNameCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:solverNameCellIdentifier];
        }
        // Set Highlight color
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = self.cellHighlightedColor;
        bgColorView.layer.masksToBounds = YES;
        cell.selectedBackgroundView = bgColorView;
        
        cell.textLabel.text  = self.experimentManager.solverNames[indexPath.row];
        cell.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([tableView isEqual:self.problemTableView]) {
        return 2;
    }
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.problemTableView]) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 24)];
        headerView.backgroundColor = self.headerViewColor;
        headerView.alpha           = 0.9;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, tableView.bounds.size.width - 10, 18)];
        label.text      = [self tableView:tableView titleForHeaderInSection:section];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        label.font      = [UIFont fontWithName:@"Helvetica Bold" size:14.0];
        label.backgroundColor = [UIColor clearColor];
        [headerView addSubview:label];
        
        return headerView;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.problemTableView]) {
        switch (section) {
            case 0:  return @"TSPLIB";
            case 1:  return @"Original";
            default: return nil;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.problemTableView]) {
        return 22.0;
    } else {
        return 0.0;
    }
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self clearCurrentSolvingContext];
    
    if ([tableView isEqual:self.problemTableView]) { // Change current problem.
        self.currentTSP.aborted = YES;
        self.currentTSPName = [self.problemTableView cellForRowAtIndexPath:indexPath].textLabel.text;
        self.currentTSPLabel.text = self.currentTSPName;
        self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
        [self.logString setString:@""];
        
        // Draw new nodes
        [self.visualizer clearTSPImages];
        [self.visualizer drawNodesWithTSP:self.currentTSP];
        
        // Draw optimal path.
        [self.visualizer drawOptimalTour:[TSP optimalSolutionWithName:self.currentTSPName] withTSP:self.currentTSP];
        
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
                self.visualizer.view.pheromoneImageView.image = nil;
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

/**
 solve: atcually may not execute the solver in some situations. In proper situation, executeSolver is called.
 */
- (IBAction)solveButtonAction:(id)sender
{
    if ([self.pathImageUpdateTimer isValid]) { // Visualizing
        
        if ([self.currentTSP.logQueue count] == 0) { // not solving
            
            // start solving
            [self.solveButton setTitle:@"Solving" forState:UIControlStateNormal];
            [self clearCurrentSolvingContext];
            
            self.currentTSP.aborted = YES;
            self.currentTSP = [TSP TSPWithFile:[[NSBundle mainBundle] pathForResource:self.currentTSPName ofType:@"tsp"]];
            
            [self.visualizer clearTourImages];
            
            [self executeSolver];
            
        } else { // now solving

            // Pause
            [self.currentTSP.operationQueue setSuspended:YES];
            [self.solveButton setTitle:@"Pausing" forState:UIControlStateNormal];
            [self.pathImageUpdateTimer invalidate];

        }

    } else { // not Visualizing
        
        [self.solveButton setTitle:@"Solving" forState:UIControlStateNormal];
        self.pathImageUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(visualizeLog) userInfo:nil repeats:YES];

    }
}

- (IBAction)step:(id)sender
{
    // If not solving, start solving and try to step again.
    if ([self.currentTSP.logQueue count] == 0) {
        [self.pathImageUpdateTimer invalidate];
        [self executeSolver];
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self step:sender];
        });
        return;
    }
    
    // Pause
    if ([self.pathImageUpdateTimer isValid]) {
        [self.pathImageUpdateTimer invalidate];
        [self.currentTSP.operationQueue setSuspended:YES];
    }
    
    // Confirm that there is a data to visualize. if not or only few left, resume solving to get more log.
    if ([self.currentTSP.logQueue count] < 3) {
        self.pathImageUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(visualizeLog) userInfo:nil repeats:YES];
        [self.currentTSP.operationQueue setSuspended:NO];
    }
    
    [self visualizeLog];
}

- (void)executeSolver
{
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
                                           probabilityBest:0.05
                                            takeGlogalBest:NO
                                                      seed:rand()
                                            noImproveLimit:200
                                         candidateListSize:20
                                                   use2opt:YES
                                                 smoothing:0.5
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
}


- (IBAction)hideControls:(id)sender {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.controlView.frame = CGRectMake(1024, 32, 330, 708);
                         self.monitorView.frame = CGRectMake( 192, 32, 640, 640);
                         self.layerTitleLabel.frame = CGRectMake(192, 660, 640, 30);
                         self.layerTitleLabel.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                     }];
}

- (IBAction)showControls:(id)sender {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.controlView.frame = CGRectMake(674, 32, 330, 708);
                         self.monitorView.frame = CGRectMake( 20, 32, 640, 640);
                         self.layerTitleLabel.frame = CGRectMake(20, 660, 640, 30);
                         self.layerTitleLabel.alpha = 1.0;
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

- (void)hideLogIfPhone
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (self.fixedLogTextView) {
            self.fixedLogTextView.hidden = YES;
        } else {
            self.logTextView.hidden = YES;
        }
    }
}

- (IBAction)switchLayer:(id)sender {
    static long long tapCount = 0;
    tapCount++;
    
    switch (tapCount % 6) {
        case 1: // show tour
            [self hideLogIfPhone];
            self.layerTitleLabel.text = @"Global Best Tour";
            self.tspView.backgroundImageView.hidden      = NO;
            self.tspView.pheromoneImageView.hidden       = YES;
            self.tspView.optimalTourImageView.hidden     = YES;
            self.tspView.directionalTourImageView.hidden = NO;
            self.tspView.tourImageView.hidden            = NO;
            self.tspView.nodeImageView.hidden            = NO;
            break;
        case 2: // show pheromone
            if (!(self.currentSolverType == TSPSolverTypeAS
                || self.currentSolverType == TSPSolverTypeMMAS)) {
                [self switchLayer:nil];
                return;
            }
            [self hideLogIfPhone];
            self.layerTitleLabel.text = @"Pheromone";
            self.tspView.backgroundImageView.hidden      = NO;
            self.tspView.pheromoneImageView.hidden       = NO;
            self.tspView.optimalTourImageView.hidden     = YES;
            self.tspView.directionalTourImageView.hidden = YES;
            self.tspView.tourImageView.hidden            = YES;
            self.tspView.nodeImageView.hidden            = NO;
            break;
        case 3: // show nodes
            [self hideLogIfPhone];
            self.layerTitleLabel.text = @"Nodes";
            self.tspView.backgroundImageView.hidden      = NO;
            self.tspView.pheromoneImageView.hidden       = YES;
            self.tspView.optimalTourImageView.hidden     = YES;
            self.tspView.directionalTourImageView.hidden = YES;
            self.tspView.tourImageView.hidden            = YES;
            self.tspView.nodeImageView.hidden            = NO;
            break;
        case 4: // show optimal tour
            if (self.currentTSP.optimalTour.route == NULL) {
                [self switchLayer:nil];
                return;
            }
            [self hideLogIfPhone];
            self.layerTitleLabel.text = @"Optimal Tour";
            self.tspView.backgroundImageView.hidden      = NO;
            self.tspView.pheromoneImageView.hidden       = YES;
            self.tspView.optimalTourImageView.hidden     = NO;
            self.tspView.directionalTourImageView.hidden = YES;
            self.tspView.tourImageView.hidden            = YES;
            self.tspView.nodeImageView.hidden            = NO;
            break;
        case 5:
            if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
                [self switchLayer:nil];
                return;
            }
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                if (self.fixedLogTextView) {
                    self.fixedLogTextView.hidden = NO;
                } else {
                    self.logTextView.hidden = NO;
                }
            }
            self.layerTitleLabel.text = @"Log";
            self.tspView.backgroundImageView.hidden      = NO;
            self.tspView.pheromoneImageView.hidden       = YES;
            self.tspView.optimalTourImageView.hidden     = YES;
            self.tspView.directionalTourImageView.hidden = YES;
            self.tspView.tourImageView.hidden            = YES;
            self.tspView.nodeImageView.hidden            = YES;
            break;
        default:
            [self hideLogIfPhone];
            self.layerTitleLabel.text = @"Default";
            self.tspView.backgroundImageView.hidden      = NO;
            self.tspView.pheromoneImageView.hidden       = NO;
            self.tspView.optimalTourImageView.hidden     = YES;
            self.tspView.directionalTourImageView.hidden = NO;
            self.tspView.tourImageView.hidden            = NO;
            self.tspView.nodeImageView.hidden            = NO;
            break;
    }
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        self.skin = (self.skin + 1) % 3;
        [self prepareSkin];
    } 
}

- (void)prepareSkin
{
    switch (self.skin) {
        case TSPViewControllerSkinOcean:
//            self.currentVisualizationStyle = TSPVisualizationStyleOcean;
            self.backgroundImageView.image = [UIImage imageNamed:@"deepBlueOcean.jpg"];
            self.headerViewColor = [UIColor colorWithRed:33/255.0 green:70/255.0 blue:138/255.0 alpha:1.0];
            self.problemHeaderView.backgroundColor =
            self.solverHeaderView.backgroundColor  =
            self.logHeaderView.backgroundColor     = self.headerViewColor;
            self.saveButton.backgroundColor  =
            self.stepButton.backgroundColor  =
            self.solveButton.backgroundColor = [UIColor colorWithRed:33/255.0 green:70/255.0 blue:138/255.0 alpha:0.5];
            self.cellHighlightedColor = [UIColor colorWithRed:(76.0/255.0) green:(161.0/255.0) blue:(255.0/255.0) alpha:1.0];
            break;
        case TSPViewControllerSkinStarryNight:
//            self.currentVisualizationStyle = TSPVisualizationStyleOcean;
            self.backgroundImageView.image = [UIImage imageNamed:@"starryNight_Nicolas_Goulet.jpg"];
            self.view.backgroundColor = [UIColor blackColor];
            self.headerViewColor = [UIColor colorWithRed:123/255.0 green:144/255.0 blue:133/255.0 alpha:1.0];
            self.problemHeaderView.backgroundColor =
            self.solverHeaderView.backgroundColor  =
            self.logHeaderView.backgroundColor     = self.headerViewColor;
            self.saveButton.backgroundColor  =
            self.stepButton.backgroundColor  =
            self.solveButton.backgroundColor = [UIColor colorWithRed:123/255.0 green:144/255.0 blue:133/255.0 alpha:0.5];
            self.cellHighlightedColor = [UIColor colorWithRed:(183.0/255.0) green:(171.0/255.0) blue:(141.0/255.0) alpha:1.0];
            break;
        case TSPViewControllerSkinBlack:
//            self.currentVisualizationStyle = TSPVisualizationStyleOcean;
            self.backgroundImageView.image = nil;
            self.view.backgroundColor = [UIColor blackColor];
            self.headerViewColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:179/255.0 alpha:1.0];
            self.problemHeaderView.backgroundColor =
            self.solverHeaderView.backgroundColor  =
            self.logHeaderView.backgroundColor     = self.headerViewColor;
            self.saveButton.backgroundColor  =
            self.stepButton.backgroundColor  =
            self.solveButton.backgroundColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:179/255.0 alpha:0.5];
            self.cellHighlightedColor = [UIColor colorWithRed:(128/255.0) green:(128/255.0) blue:(128.0/255.0) alpha:1.0];
            break;
        case TSPViewControllerSkinWhite:
            self.currentVisualizationStyle = TSPVisualizationStyleGrayScale;
            self.backgroundImageView.image = nil;
            self.view.backgroundColor = [UIColor whiteColor];
            self.headerViewColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:179/255.0 alpha:1.0];
            self.problemHeaderView.backgroundColor =
            self.solverHeaderView.backgroundColor  =
            self.logHeaderView.backgroundColor     = self.headerViewColor;
            self.saveButton.backgroundColor  =
            self.stepButton.backgroundColor  =
            self.solveButton.backgroundColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:179/255.0 alpha:0.5];
            self.cellHighlightedColor = [UIColor colorWithRed:(128/255.0) green:(128/255.0) blue:(128.0/255.0) alpha:1.0];
        default:
            break;
    }
    [self.problemTableView reloadData];
    [self.solverTableView reloadData];
}


@end
