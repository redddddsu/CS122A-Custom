#ifndef MAZE
#define MAZE
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include "hardware/spi.h"
#include "pico/stdlib.h"
#include <time.h>



typedef struct {
    bool visited;

    int top;
    int right;
    int bottom;
    int left;

    bool begin;
    bool end;

    bool current_position;

} Cell;

void initMaze();
void randomize(int *arr);
void carve(int x, int y, int next_x, int next_y);
void generateMaze(int x, int y);
void create_border();
void transmit_maze(int bt);
void gameLogic(int16_t acceleration[]);

#endif