#ifndef VM_KBD_H
#define VM_KBD_H

#include <SDL/SDL.h>

#define KBD_BUF_SIZE    16

unsigned int kbd_read();
void kbd_write(unsigned int data);
void keydown(SDL_Event e);
void keyup(SDL_Event e);
void kbd_init();
void kbd_clk();

#endif
