#include "vga.h"

void post() {
    int old_col, size = 0x18000;
    fmt_attr = 0x0F;
    print_fmt("MIPS-I 32-Bit CPU at 50MHz\n");
    print_fmt("Memory Test: ");
    hide_cursor();
    while (1) {
        old_col = col;
        ((char *) size)[0] = 0xAA;
        ((char *) size)[1] = 0x55;
        ((char *) size)[2] = 0xAA;
        ((char *) size)[3] = 0x55;
        if (*((int *)size) == 0x55AA55AA) {
            print_fmt("%dKB", size/1024);
        } else {
            /* no more ram */
            break;
        }
        col = old_col;
        size+=1024*2;
    }
    show_cursor();
    print_fmt("%dKB OK", size/1024);
    print_fmt("\n");
    print_fmt("\n");
}
