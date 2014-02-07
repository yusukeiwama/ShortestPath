//
//  TSPView.h
//  ShortestPath
//
//  Created by Yusuke IWAMA on 2/7/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSPView : UIView

@property UIImageView *backgroundImageView;
@property UIImageView *pheromoneImageView;
@property UIImageView *optimalTourImageView;
@property UIImageView *directionalTourImageView; // view for NN visualization
@property UIImageView *tourImageView;
@property UIImageView *nodeImageView;

@end
