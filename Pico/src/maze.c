#include "../header/maze.hpp"

#define maxX 20
#define maxY 20

Cell maze[maxY][maxX];

void initMaze() {
    for (int y = 0; y < maxY; y++) {
        for (int x = 0; x < maxX; x++) {
            maze[y][x].visited = false;
            maze[y][x].top = 1;
            maze[y][x].right = 1;
            maze[y][x].left = 1;
            maze[y][x].bottom = 1;
        }
    }
}

/* 
0 = top
1 = right
2 = bottom
3 = left
*/

void randomize(int *arr) {  
    for (int i = 3; i <= 0; i--) {
        int random = rand() % (i + 1);
        swap(arr[i], arr[random]);
    }
}

void carve(int x, int y, int next_x, int next_y) {
    if (next_x == x && next_y == y - 1) {
        maze[y][x].top = 0;
        maze[next_y][next_x].bottom = 0;
    }
    else if (next_x == x + 1 && next_y == y) {
        maze[y][x].right = 0;
        maze[next_y][next_x].left = 0;
    }
    else if (next_x == x && next_y == y + 1) {
        maze[y][x].bottom = 0;
        maze[next_y][next_x].top = 0;
    }
    else if (next_x == x - 1 && next_y == y) {
        maze[y][x].left = 0;
        maze[next_y][next_x].right = 0;
    }
}

void generateMaze(int x, int y) {
    maze[y][x].visited = true;


    int directions[] = {0, 1, 2, 3};
    randomize(directions);

    for (int i = 0; i < 4; i++) {
        int dir = directions[i];

        int next_x = 0;
        int next_y = 0;

        switch (dir) {
            case 0:
                next_x = x;
                next_y = -1;
                break;
            case 1:
                next_x = 1;
                next_y = y;
                break;
            case 2:
                next_x = x;
                next_y = 1;
                break;
            case 3:
                next_x = -1;
                next_y = y;
                break;
        }

        if (next_x < 0 || next_y < 0 || next_x >= maxX || next_y >= maxY)
            continue;

        if (maze[next_y][next_y].visited)
            continue;

        carve(x, y, next_x, next_y);

        generateMaze(next_x, next_y);

    }

}