//
//  USKViewController.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TSP.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property TSPSolverType   currentSolverType;
@property NSMutableString *logString;

@end

/**
 TODO: fix bug that changing algorithm while solving big problem result in disabling solving functionality.
 TODO: fix bug that the problem is read from file no less than three time before solving!
 TODO: fix bug and refactor solve button action and title changing.
 
 TODO: Enable to edit parameters.
 TODO: Human mode
*/