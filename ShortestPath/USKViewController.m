//
//  USKViewController.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 12/13/13.
//  Copyright (c) 2013 Yusuke Iwama. All rights reserved.
//

#import "USKViewController.h"
#import "USKTSP.h"

@interface USKViewController ()

@end

@implementation USKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	USKTSP *tsp = [[USKTSP alloc] initWithFilePath:[[NSBundle mainBundle] pathForResource:@"TSPData/eil51" ofType:@"tsp"]];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
