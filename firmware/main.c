#include "vga.h"

int main() {

    int reg;

    /* initialize VGA... */
    clear_screen(0x0E, 0x0E, 0x0E);

    /* test */
    __asm__("mfc0 %0, $12":"=r"(reg));
    print_fmt("reg: %x\n", reg);
    __asm__("mtc0 %0, $12"::"r"(0xABCDDCBA));
    __asm__("mfc0 %0, $12":"=r"(reg));
    print_fmt("reg: %x\n", reg);

    /* initialize keyboard */
    kbd_init();

    /* print header */
    print_fmt("****************************");
    fmt_attr = 0x0E;
    print_fmt(" MIPS COMPUTER FOR CSED ");
    fmt_attr = 0x0E;
    print_fmt("****************************");
    print_fmt("-> ROM: 64KB\n");
    print_fmt("-> RAM: 32KB\n");
    print_fmt("-> VGA RAM: 8+32KB\n");
    print_fmt("****************************");
    print_fmt("****************************");
    print_fmt("************************");

    /* test cache stupidity */
    /*int *stupid = (int *) 0xF0000000;
    *stupid = 0x12345678;
    print_hex(*stupid, 0x0E);
    print_char('\n', 0x0E);
    int j;
    for (j = 0; j < 512; j++)
        stupid[j+1] = stupid[j];
    print_hex(*stupid, 0x0E);
    while(1);*/

    /*int i;
    for (i = 6; i < 25; i++) {
        print_hex(i, 0x0E);
        print_char('\n', 0x0E);
    }
    print_hex(i, 0x0E);
    while(1);*/

    /* start shell */
    shell();

    /* return 0 */
    return 0;

}
