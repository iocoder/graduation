/* clock handler */

#include <SDL2/SDL.h>
#include <sys/times.h>
#include <stdio.h>
#include <stdlib.h>

#include "clock.h"
#include "cpu.h"
#include "kbd.h"
#include "vga.h"
#include "ppu.h"
#include "pit.h"

int exit_now = 0;

int watch_events(SDL_Thread *t) {
    /* handle events */
    SDL_Event e;
    while(1) {
        vga_render();
        ppu_render();
        if (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                exit_now = 1;
                SDL_WaitThread(t, NULL);
                return 1;
            } else if (e.type == SDL_KEYDOWN) {
                keydown(e);
            } else if (e.type == SDL_KEYUP) {
                keyup(e);
            }
        }
    }
    return 0;
}

int clock_handler(void *ptr) {
    while(!exit_now) {
        if (cpu_clk()) {
            SDL_Event quit_event;
            quit_event.type=SDL_QUIT;
            SDL_PushEvent(&quit_event);
            break;
        }
        kbd_clk();
        pit_clk();
        pit_clk(); /* doubled because pit_freq = 2 * cpu_freq */
        ppu_clk();
        ppu_clk();
    }
    return 0;
}
