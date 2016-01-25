#ifndef VM_JOYPAD_H
#define VM_JOYPAD_H

#include <SDL2/SDL.h>

unsigned char joypad_read();
void joypad_write(unsigned char data);
void joypad_keydown(SDL_Event e);
void joypad_keyup(SDL_Event e);

#endif

