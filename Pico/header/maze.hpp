#ifndef MAZE
#define MAZE
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef struct {
    bool visited;

    int top;
    int right;
    int bottom;
    int left;
} Cell;

#endif