#include <stdio.h>
#include <stdlib.h>
#include <SDL/SDL.h>

#include "vga.h"

extern SDL_Surface* screen;
unsigned char chr[80*30];
unsigned char att[80*30];
unsigned short font[256][16];
int close_thread = 0;
int thread_closed = 0;
Uint32 palette[] = {
     0x000000,
     0x0000AA,
     0x00AA00,
     0x00AAAA,
     0xAA0000,
     0xAA00AA,
     0xAA5500,
     0xAAAAAA,
     0x555555,
     0x5555FF,
     0x55FF55,
     0x55FFFF,
     0xFF5555,
     0xFF55FF,
     0xFFFF55,
     0xFFFFFF
};

void set_fpx(int x, int y, Uint32 color) {
    Uint32 *pixels = (Uint32 *) screen->pixels;
    pixels[(y*screen->w)+x] = color;
}

void update_char(int loc, unsigned char ascii, unsigned char attrib) {

    int row = loc/80;
    int col = loc%80;
    Uint32 fg = palette[(attrib>>0)&0xF];
    Uint32 bg = palette[(attrib>>4)&0xF];
    int j, k;

    /* update buffers */
    chr[loc] = ascii;
    att[loc] = attrib;

    /* update screen */
    for (j = 0; j < 9; j++)
        for (k = 0; k < 16; k++) {
            if (font[ascii][k]&(1<<(8-j))) {
                set_fpx(col*9+j, row*16+k, fg);
            } else {
                set_fpx(col*9+j, row*16+k, bg);
            }
        }

}

void vga_write(unsigned short addr, unsigned int data) {

    int loc;
    if (addr & 0x1000) {
        /* font */
        font[(addr & 0x0FF0)>>4][addr&0x0F] = data;
    } else if (addr < 4000) {
        /* data */
        loc = (addr & 0x0FFF)>>1;
        if (addr & 1) {
            update_char(loc, chr[loc], data);
        } else {
            update_char(loc, data, att[loc]);
        }
    } else {
        /* special registers */

    }

}

int vga_update() {
    while(!close_thread)
        SDL_Flip(screen);
    thread_closed = 1;
    return 1;
}

void vga_stop() {
    close_thread = 1;
    while (!thread_closed);
}

void vga_init() {

    FILE *f;
    int i;

    /* initialize screen */
    for (i = 0; i < 80*25; i++)
        update_char(i, 0, 0x11);

    /* instantiate a thread for updating the screen */
    SDL_CreateThread(&vga_update, NULL);

}
