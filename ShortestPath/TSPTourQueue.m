//
//  TSPTourQueue.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 2/5/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPTourQueue.h"


@implementation TSPTourQueue {
    MidTour *_headTour;
    MidTour *_tailTour;
}
    
- (void)enqueueTour:(Tour)tour toIndex:(int)index
{
    // Create new MidTour.
    MidTour *newTour = calloc(1, sizeof(MidTour));
    newTour->index = index;
    int routeSize = index + 1;
    newTour->tour.route = calloc(routeSize, sizeof(int));
    memcpy(newTour->tour.route, tour.route, routeSize * sizeof(int));
    newTour->next  = NULL;
    
    // Add new MidTour to the MidTour list.
    if (_headTour == NULL) {
        _headTour = newTour;
        _tailTour = _headTour;
    } else {
        _tailTour->next = newTour;
        _tailTour = newTour;
    }
}

- (MidTour *)dequeueTour
{
    if (_headTour == NULL) {
        return NULL;
    }
    MidTour *dequeuedTour = _headTour;
    _headTour = _headTour->next;
    
    return dequeuedTour;
}


- (void)flush
{
    while (_headTour != NULL) {
        free(_headTour->tour.route);
        MidTour *freeTarget = _headTour;
        _headTour = _headTour->next;
        free(freeTarget);
    }
}

@end
