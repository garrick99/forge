/*
 * Forge Verified Snake — playable terminal game
 *
 * All game logic proven memory-safe. 52 Z3 proofs.
 * Arrow keys to move. Eat food (*) to grow. Don't hit yourself.
 *
 * Works on Windows (conio) and Linux (termios).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <time.h>

#ifdef _WIN32
#include <conio.h>
#include <windows.h>
#define SLEEP_MS(ms) Sleep(ms)
#define CLEAR() system("cls")
static int get_key(void) {
    if (!_kbhit()) return -1;
    int ch = _getch();
    if (ch == 224 || ch == 0) {
        ch = _getch();
        switch (ch) {
            case 72: return 3; /* up */
            case 80: return 1; /* down */
            case 75: return 2; /* left */
            case 77: return 0; /* right */
        }
    }
    if (ch == 'w' || ch == 'W') return 3;
    if (ch == 's' || ch == 'S') return 1;
    if (ch == 'a' || ch == 'A') return 2;
    if (ch == 'd' || ch == 'D') return 0;
    if (ch == 'q' || ch == 'Q' || ch == 27) return 99;
    return -1;
}
#else
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#define SLEEP_MS(ms) usleep((ms)*1000)
#define CLEAR() printf("\033[2J\033[H")
static struct termios orig_term;
static void restore_term(void) { tcsetattr(0, TCSANOW, &orig_term); }
static void raw_mode(void) {
    tcgetattr(0, &orig_term);
    atexit(restore_term);
    struct termios t = orig_term;
    t.c_lflag &= ~(ICANON | ECHO);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 0;
    tcsetattr(0, TCSANOW, &t);
}
static int get_key(void) {
    char buf[3];
    int n = read(0, buf, 3);
    if (n <= 0) return -1;
    if (n == 1) {
        if (buf[0] == 'w') return 3;
        if (buf[0] == 's') return 1;
        if (buf[0] == 'a') return 2;
        if (buf[0] == 'd') return 0;
        if (buf[0] == 'q' || buf[0] == 27) return 99;
    }
    if (n == 3 && buf[0] == 27 && buf[1] == '[') {
        if (buf[2] == 'A') return 3;
        if (buf[2] == 'B') return 1;
        if (buf[2] == 'D') return 2;
        if (buf[2] == 'C') return 0;
    }
    return -1;
}
#endif

#define main forge_main_unused
#include "game.c"
#undef main

#define W 20
#define MAX_SNAKE 400

static void draw(uint64_t *board, int w, uint64_t score, uint64_t length) {
    CLEAR();
    printf("  +");
    for (int i = 0; i < w; i++) printf("--");
    printf("+\n");

    for (int y = 0; y < w; y++) {
        printf("  |");
        for (int x = 0; x < w; x++) {
            uint64_t cell = board[y * w + x];
            if (cell == 1)      printf("\033[32m@@\033[0m");    /* snake = green */
            else if (cell == 2) printf("\033[31m**\033[0m");    /* food = red */
            else if (cell == 3) printf("##");                    /* wall */
            else                printf("  ");                    /* empty */
        }
        printf("|\n");
    }

    printf("  +");
    for (int i = 0; i < w; i++) printf("--");
    printf("+\n");
    printf("  Score: %lu   Length: %lu   [WASD/Arrows] Move  [Q] Quit\n",
           (unsigned long)score, (unsigned long)length);
    printf("  Forge Verified Snake — 52 proof obligations, 0 buffer overflows\n");
}

int main(void) {
    uint64_t board[W * W];
    uint64_t snake_x[MAX_SNAKE], snake_y[MAX_SNAKE];

    forge_span_u64_t b = { board, W * W };
    forge_span_u64_t sx = { snake_x, MAX_SNAKE };
    forge_span_u64_t sy = { snake_y, MAX_SNAKE };

#ifndef _WIN32
    raw_mode();
#endif

    __forge_tuple_u64_u64_u64_t init = init_game(b, W, sx, sy, MAX_SNAKE);
    uint64_t head = init._0, tail = init._1, length = init._2;
    uint64_t dir = 0; /* start moving right */
    uint64_t seed = (uint64_t)time(NULL);
    int alive = 1;

    while (alive) {
        draw(board, W, get_score(length), length);

        SLEEP_MS(120);

        int key = get_key();
        if (key == 99) break;
        if (key >= 0 && key <= 3) {
            /* Prevent 180-degree turns */
            if (!((key == 0 && dir == 2) || (key == 2 && dir == 0) ||
                  (key == 1 && dir == 3) || (key == 3 && dir == 1)))
                dir = key;
        }

        __forge_tuple_u64_u64_u64_u64_t step =
            snake_step(b, W, sx, sy, MAX_SNAKE, head, tail, length, dir);

        uint64_t status = step._0;
        head = step._1;
        tail = step._2;
        length = step._3;

        if (status == 1) {
            alive = 0;
        } else if (status == 2) {
            seed = seed * 6364136223846793005ULL + 1442695040888963407ULL;
            place_food(b, W * W, seed);
        }
    }

    draw(board, W, get_score(length), length);
    printf("\n  GAME OVER! Final score: %lu\n\n", (unsigned long)get_score(length));

    return 0;
}
