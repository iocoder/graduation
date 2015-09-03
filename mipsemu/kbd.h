#ifndef VM_KBD_H
#define VM_KBD_H

#include <SDL/SDL.h>

#define KBD_BUF_SIZE    16

unsigned char kbd_read(unsigned int addr);
void kbd_write(unsigned int addr, unsigned char data);
void keydown(SDL_Event e);
void keyup(SDL_Event e);
void kbd_init();
void kbd_clk();

#endif
