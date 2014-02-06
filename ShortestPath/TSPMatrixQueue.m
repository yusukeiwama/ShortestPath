//
//  TSPMatrixQueue.m
//  ShortestPath
//
//  Created by Yusuke IWAMA on 2/6/14.
//  Copyright (c) 2014 Yusuke Iwama. All rights reserved.
//

#import "TSPMatrixQueue.h"

typedef struct _LinkedMatrix {
    double *matrix;
    struct _LinkedMatrix *next;
} LinkedMatrix;

@implementation TSPMatrixQueue {
    LinkedMatrix *_head;
    LinkedMatrix *_tail;
}

- (void)enqueueMatrix:(double *)matrix size:(int)n
{
    // Create new upper triangle matrix in linear array.
    LinkedMatrix *newMatrix = calloc(1, sizeof(LinkedMatrix));
    newMatrix->matrix = calloc(n * (n - 1) / 2, sizeof(double)); // upper matrix in linear array.
    int k = 0;
    for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
            newMatrix->matrix[k++] = matrix[i * n + j];
        }
    }
    newMatrix->next  = NULL;
    
    // Add new matrix into the list.
    if (_head == NULL) {
        _head = newMatrix;
        _tail = _head;
    } else {
        _tail->next = newMatrix;
        _tail       = newMatrix;
    }
}

- (double *)dequeueMatrix
{
    if (_head == NULL) {
        return NULL;
    }
    LinkedMatrix *target = _head;
    _head = _head->next;
    
    return target->matrix;
}


- (void)flush
{
    while (_head != NULL) {
        LinkedMatrix *target = _head;
        _head = _head->next;
        free(target->matrix);
        free(target);
    }
}

- (void)dealloc
{
    [self flush];
}

@end
