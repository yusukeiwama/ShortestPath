//
//  TSPTourQueue.m
//  ShortestPath
//
//  Created by Yusuke Iwama on 2/5/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPTourQueue.h"

typedef struct _LinkedTour {
    Tour               tour;
    int                routeSize;
    struct _LinkedTour *next;
} LinkedTour;

@implementation TSPTourQueue {
    LinkedTour *_head;
    LinkedTour *_tail;
}
    
- (void)enqueueTour:(Tour *)tour routeSize:(int)size
{
    // Create new MidTour.
    LinkedTour *newTour = calloc(1, sizeof(LinkedTour));
    newTour->routeSize  = size;
    newTour->tour.route = calloc(size + 1, sizeof(int)); // +1 ... exceeded element work as a sentinel.
    memcpy(newTour->tour.route, tour->route, size * sizeof(int));
    newTour->next  = NULL;
    
    // Add new MidTour to the MidTour list.
    if (_head == NULL) {
        _head = newTour;
        _tail = _head;
    } else {
        _tail->next = newTour;
        _tail       = newTour;
    }
}

- (Tour *)dequeueTour
{
    if (_head == NULL) {
        return NULL;
    }
    LinkedTour *dequeuedTour = _head;
    _head = _head->next;
    
    return &(dequeuedTour->tour);
}


- (void)flush
{
    while (_head != NULL) {
        LinkedTour *target = _head;
        _head = _head->next;
        free(target->tour.route);
        free(target);
    }
}

@end
