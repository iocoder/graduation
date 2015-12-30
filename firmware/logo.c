#include "vga.h"

extern struct {
    int width;
    int height;
    unsigned short data[0];
} __attribute__((packed)) logo;

void draw_logo() {
    /* divide logo into chars */
    int lines = logo.height/16;
    int chars_per_line = logo.width/9;
    int i, j, k, off = 0, off_sub, ansi=0x80;
    /* print debugging info */
    /*print_fmt("width:  %x\n", logo.width);
    print_fmt("height: %x\n", logo.height);*/
    /* store logo in VGA */
    for (i = 0; i < lines; i++) {
        for (j = 0; j < chars_per_line; j++) {
            /* draw char in VGA font */
            off_sub = off+j;
            for (k = 0; k < 16; k++) {
                write_font(ansi, k, logo.data[off_sub]);
                off_sub += chars_per_line;
            }
            /* show on screen */
            write_char(i+1, (80-chars_per_line-2)+j, ansi++, 0x0E);
        }
        off += chars_per_line*16;
    }
}

__asm__(".section .rodata     ");
__asm__("logo:                ");
__asm__(".incbin \"logo.bin\" ");

