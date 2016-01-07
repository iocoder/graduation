#include <SDL/SDL.h>

#include "kbd.h"
#include "mem.h"
#include "pic.h"

static unsigned char buf[KBD_BUF_SIZE];
static int buf_write = 0;
static int buf_read = 0;
static unsigned char last_read = 0;

int next_read() {
    return (buf_read+1)%sizeof(KBD_BUF_SIZE);
}

int next_write() {
    return (buf_write+1)%sizeof(KBD_BUF_SIZE);
}

unsigned char get_from_buf() {
    unsigned char ret;
    if (buf_write == buf_read) {
        ret = last_read;
    } else {
        ret = last_read = buf[buf_read];
        buf_read = next_read();
    }
    return ret;
}

void add_to_buf(unsigned char c) {
    if (next_write() == buf_read) {
        /* buffer is full, ignore this */
        return;
    }
    buf[buf_write] = c;
    buf_write = next_write();
    pic_irq(1);
}

unsigned int get_scancode(SDL_Event e) {
    switch(e.key.keysym.sym) {
        case SDLK_ESCAPE:
            return 0x67;
        case SDLK_F1:
            return 0x05;
        case SDLK_F2:
            return 0x06;
        case SDLK_F3:
            return 0x04;
        case SDLK_F4:
            return 0x0C;
        case SDLK_F5:
            return 0x03;
        case SDLK_F6:
            return 0x0B;
        case SDLK_F7:
            return 0x83;
        case SDLK_F8:
            return 0x0A;
        case SDLK_F9:
            return 0x01;
        case SDLK_F10:
            return 0x09;
        case SDLK_F11:
            return 0x78;
        case SDLK_F12:
            return 0x07;
        /* ------------------------------------------------------------ */
        case SDLK_BACKQUOTE:
            return 0x0E;
        case SDLK_EXCLAIM:
        case SDLK_1:
            return 0x16;
        case SDLK_AT:
        case SDLK_2:
            return 0x1E;
        case SDLK_HASH:
        case SDLK_3:
            return 0x26;
        case SDLK_DOLLAR:
        case SDLK_4:
            return 0x25;
        case SDLK_5:
            return 0x2E;
        case SDLK_CARET:
        case SDLK_6:
            return 0x36;
        case SDLK_AMPERSAND:
        case SDLK_7:
            return 0x3D;
        case SDLK_ASTERISK:
        case SDLK_8:
            return 0x3E;
        case SDLK_LEFTPAREN:
        case SDLK_9:
            return 0x46;
        case SDLK_RIGHTPAREN:
        case SDLK_0:
            return 0x45;
        case SDLK_UNDERSCORE:
        case SDLK_MINUS:
            return 0x4E;
        case SDLK_KP_PLUS:
        case SDLK_EQUALS:
            return 0x55;
        case SDLK_BACKSPACE:
            return 0x66;
        /* ------------------------------------------------------------ */
        case SDLK_TAB:
            return 0x0D;
        case SDLK_q:
            return 0x15;
        case SDLK_w:
            return 0x1D;
        case SDLK_e:
            return 0x24;
        case SDLK_r:
            return 0x2D;
        case SDLK_t:
            return 0x2C;
        case SDLK_y:
            return 0x35;
        case SDLK_u:
            return 0x3C;
        case SDLK_i:
            return 0x43;
        case SDLK_o:
            return 0x44;
        case SDLK_p:
            return 0x4D;
        case SDLK_LEFTBRACKET:
            return 0x54;
        case SDLK_RIGHTBRACKET:
            return 0x5B;
        case SDLK_BACKSLASH:
            return 0x5D;
        /* ------------------------------------------------------------ */
        case SDLK_CAPSLOCK:
            return 0x58;
        case SDLK_a:
            return 0x1C;
        case SDLK_s:
            return 0x1B;
        case SDLK_d:
            return 0x23;
        case SDLK_f:
            return 0x2B;
        case SDLK_g:
            return 0x34;
        case SDLK_h:
            return 0x33;
        case SDLK_j:
            return 0x3B;
        case SDLK_k:
            return 0x42;
        case SDLK_l:
            return 0x4B;
        case SDLK_COLON:
        case SDLK_SEMICOLON:
            return 0x4C;
        case SDLK_QUOTEDBL:
        case SDLK_QUOTE:
            return 0x52;
        case SDLK_RETURN:
            return 0x5A;
        /* ------------------------------------------------------------- */
        case SDLK_LSHIFT:
            return 0x12;
        case SDLK_z:
            return 0x1A;
        case SDLK_x:
            return 0x22;
        case SDLK_c:
            return 0x21;
        case SDLK_v:
            return 0x2A;
        case SDLK_b:
            return 0x32;
        case SDLK_n:
            return 0x31;
        case SDLK_m:
            return 0x3A;
        case SDLK_LESS:
        case SDLK_COMMA:
            return 0x41;
        case SDLK_GREATER:
        case SDLK_PERIOD:
            return 0x49;
        case SDLK_QUESTION:
        case SDLK_SLASH:
            return 0x4A;
        case SDLK_RSHIFT:
            return 0x59;
        /* ------------------------------------------------------------- */
        case SDLK_LCTRL:
            return 0x14;
        case SDLK_LALT:
            return 0x11;
        case SDLK_SPACE:
            return 0x29;
        case SDLK_RALT:
            return 0xE011;
        case SDLK_RCTRL:
            return 0xE014;
        case SDLK_UP:
            return 0xE075;
        case SDLK_RIGHT:
            return 0xE074;
        case SDLK_LEFT:
            return 0xE06B;
        case SDLK_DOWN:
            return 0xE072;
        default:
            return 0;
    }
}

unsigned int kbd_read() {
    if (buf_read != buf_write) {
        return get_from_buf();
    } else {
        return 0;
    }
}

void kbd_write(unsigned int data) {

}

void scproc(SDL_Event e, int release) {
    /*if (e.key.keysym.sym == SDLK_UP) {
        if (!release)
            dump_mem();
    } else {*/
        unsigned int scancode = get_scancode(e);
        unsigned char esc = (scancode>>8)&0xFF;
        unsigned char pkt = (scancode>>0)&0xFF;
        if (release)
            add_to_buf(0xF0);
        if (esc)
            add_to_buf(esc);
        if (pkt)
            add_to_buf(pkt);
    /*}*/
}

void keydown(SDL_Event e) {
    scproc(e, 0);
}

void keyup(SDL_Event e) {
    scproc(e, 1);
}

void kbd_clk() {

}

void kbd_init() {
    /* what am I supposed to do here? */
}
