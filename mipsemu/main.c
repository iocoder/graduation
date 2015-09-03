#include <stdio.h>
#include <SDL/SDL.h>

#include "clock.h"
#include "vga.h"
#include "cpu.h"
#include "kbd.h"
#include "mem.h"

SDL_Surface* screen = NULL;

int main(int argc, char *argv[]) {

    SDL_Thread *t;

    /* check the arguments */
    if (argc != 2) {
        fprintf(stderr, "Invalid arguments. Usage: ");
        fprintf(stderr, "%s <firmware>\n", argv[0]);
        return -1;
    }

    /* print splash */
    printf("*********************************\n");
    printf("*  MIPS FPGA COMPUTER EMULATOR  *\n");
    printf("*********************************\n");
    printf("\n");

    /* loading... */
    printf("The emulator is loading...\n");

    /* initialize SDL */
    SDL_Init(SDL_INIT_EVERYTHING);

    /* Set up screen */
    screen = SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE);

    /* Set title */
    SDL_WM_SetCaption("MIPS FPGA Computer Emulator", NULL);

    /* initialize memory */
    mem_init(argv[1]);
    
    /* initialize CPU */
    cpu_init();

    /* initialize VGA */
    vga_init();

    /* initialize keyboard */
    kbd_init();

    /* create execution thread */
    t = SDL_CreateThread(clock_handler, (void *)NULL);

    /* run event watcher */
    watch_events(t);

    /* quit SDL */
    SDL_Quit();

    /* done */
    return 0;

}
