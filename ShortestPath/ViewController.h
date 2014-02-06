//
//  USKViewController.h
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TSP.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property TSPSolverType currentSolverType;

@end

/**
 TODO: add log
 TODO: Human mode
*/