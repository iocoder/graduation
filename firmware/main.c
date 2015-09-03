#include "vga.h"

int main() {

    /* initialize VGA... */
    clear_screen(0x4F, 0x4F, 0x4E);

    /* initialize keyboard */
    kbd_init();

    /* print header */
    print_fmt("****************************");
    fmt_attr = 0x4E;
    print_fmt(" MIPS COMPUTER FOR CSED ");
    fmt_attr = 0x4F;
    print_fmt("****************************");
    print_fmt("-> ROM: 64KB\n");
    print_fmt("-> RAM: 32KB\n");
    print_fmt("-> VGA RAM: 8+32KB\n");
    print_fmt("****************************");
    print_fmt("****************************");
    print_fmt("************************");

    /* start shell */
    shell();

    /* return 0 */
    return 0;

}
