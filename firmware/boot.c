#include "vga.h"

void boot() {
    while (1) {
        /* print err msg */
        fmt_attr = 0x0C;
        print_fmt("No valid bootable medium found! "
                  "drop to BIOS shell...\n\n");
        fmt_attr = 0x0F;
        /* execute shell */
        shell();
    }
}
