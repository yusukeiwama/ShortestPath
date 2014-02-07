//
//  TSPView.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 2/7/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPView.h"

@implementation TSPView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _backgroundImageView      = [[UIImageView alloc] initWithFrame:frame];
        _pheromoneImageView       = [[UIImageView alloc] initWithFrame:frame];
        _optimalTourImageView     = [[UIImageView alloc] initWithFrame:frame];
        _directionalTourImageView = [[UIImageView alloc] initWithFrame:frame];
        _tourImageView            = [[UIImageView alloc] initWithFrame:frame];
        _nodeImageView            = [[UIImageView alloc] initWithFrame:frame];
        [self addSubview:_backgroundImageView];
        [self addSubview:_pheromoneImageView];
        [self addSubview:_optimalTourImageView];
        [self addSubview:_tourImageView];
        [self addSubview:_nodeImageView];
        self.optimalTourImageView.hidden = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
