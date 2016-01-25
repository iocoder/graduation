/* the controllers */

#include <SDL2/SDL.h>

unsigned char pad0_butA = 0;
unsigned char pad0_butB = 0;
unsigned char pad0_butSel = 0;
unsigned char pad0_butStart = 0;
unsigned char pad0_butUp = 0;
unsigned char pad0_butDown = 0;
unsigned char pad0_butLeft = 0;
unsigned char pad0_butRight = 0;

unsigned char pad1_butA = 0;
unsigned char pad1_butB = 0;
unsigned char pad1_butSel = 0;
unsigned char pad1_butStart = 0;
unsigned char pad1_butUp = 0;
unsigned char pad1_butDown = 0;
unsigned char pad1_butLeft = 0;
unsigned char pad1_butRight = 0;

unsigned char latched_state0 = 0;
unsigned char latched_state1 = 0;

unsigned char reload_enabled = 0;

unsigned char joypad0_read() {

    unsigned char ret = latched_state0 & 1;

    if (!reload_enabled) {
        latched_state0 = (latched_state0>>1) | 0x80;
    }

    return ret;

}

unsigned char joypad1_read() {

    unsigned char ret = latched_state1 & 1;

    if (!reload_enabled) {
        latched_state1 = (latched_state1>>1) | 0x80;
    }

    return ret;

}

unsigned char joypad_read(int addr) {
    return addr?joypad1_read():joypad0_read();
}

void joypad_write(unsigned char data) {

    if (data & 1) {
        /* reload button states into shift registers */
        latched_state0 = (pad0_butA    <<0) |
                         (pad0_butB    <<1) |
                         (pad0_butSel  <<2) |
                         (pad0_butStart<<3) |
                         (pad0_butUp   <<4) |
                         (pad0_butDown <<5) |
                         (pad0_butLeft <<6) |
                         (pad0_butRight<<7);

        latched_state1 = (pad1_butA    <<0) |
                         (pad1_butB    <<1) |
                         (pad1_butSel  <<2) |
                         (pad1_butStart<<3) |
                         (pad1_butUp   <<4) |
                         (pad1_butDown <<5) |
                         (pad1_butLeft <<6) |
                         (pad1_butRight<<7);

        reload_enabled = 1;
    } else {
        reload_enabled = 0; /* reloading done */
    }

}

void joypad_keydown(SDL_Event e) {

    switch (e.key.keysym.sym) {
        case SDLK_UP:
            pad0_butUp = 1;
            break;

        case SDLK_DOWN:
            pad0_butDown = 1;
            break;

        case SDLK_LEFT:
            pad0_butLeft = 1;
            break;

        case SDLK_RIGHT:
            pad0_butRight = 1;
            break;

        case SDLK_RSHIFT:
            pad0_butSel = 1;
            break;

        case SDLK_RETURN:
            pad0_butStart = 1;
            break;

        case SDLK_a:
            pad0_butA = 1;
            break;

        case SDLK_z:
            pad0_butB = 1;
            break;

        default:
            break;
    }

}

void joypad_keyup(SDL_Event e) {

    switch (e.key.keysym.sym) {
        case SDLK_UP:
            pad0_butUp = 0;
            break;

        case SDLK_DOWN:
            pad0_butDown = 0;
            break;

        case SDLK_LEFT:
            pad0_butLeft = 0;
            break;

        case SDLK_RIGHT:
            pad0_butRight = 0;
            break;

        case SDLK_RSHIFT:
            pad0_butSel = 0;
            break;

        case SDLK_RETURN:
            pad0_butStart = 0;
            break;

        case SDLK_a:
            pad0_butA = 0;
            break;

        case SDLK_z:
            pad0_butB = 0;
            break;

        default:
            break;
    }

}
