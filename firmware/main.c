#include "vga.h"
#include "kbd.h"
#include "pit.h"
#include "pic.h"

int ticks;
char chr;

void newsec() {
    print_fmt("0x%x seconds passed.\n", ++ticks);
    //__asm__("nop; nop; nop;");
}

void print_status() {
    int reg;
    __asm__("mfc0 %0, $12":"=r"(reg):"r"(0xFFFFFFFF));
    print_fmt("reg: %x\n", reg);
}

void print_cause() {
    int reg;
    __asm__("mfc0 %0, $13":"=r"(reg):"r"(0xFFFFFFFF));
    print_fmt("CAUSE: %x\n", reg);
}

void print_epc() {
    int reg;
    __asm__("mfc0 %0, $14;":"=r"(reg):"r"(0xFFFFFFFF));
    print_fmt("EPC: %x\n", reg);
}

void handle_interrupt() {
    switch (pic_read()) {
        case 0:
            write_to_vga(0, chr++);
            break;
        case 1:
            kbd_irq();
            break;
        case 2:
            break;
        case 3:
            break;
        case 4:
            break;
        case 5:
            break;
        case 6:
            break;
        case 7:
            break;
        default:
            break;
    }
    //print_epc();
    //print_cause();
    //print_fmt("int source: %x\n", pic_read());
    pic_enable();
}

void do_rfe() {
    __asm__("rfe");
}

int main() {

    int reg;

    /* initialize VGA... */
    clear_screen(0x0E, 0x0E, 0x0E);

    /* initialize PIC */
    pic_init();

    /* interrupt test */
    __asm__("mfc0 %0, $12":"=r"(reg));
    print_fmt("reg: %x\n", reg);
    __asm__("mtc0 %0, $12"::"r"(0xABCDDCBF));
    __asm__("mfc0 %0, $12":"=r"(reg):"r"(0xFFFFFFFF));
    print_fmt("reg: %x\n", reg);
    chr = 0;

    ticks = 0;
    pit_write(500000);

    /* initialize keyboard */
    kbd_init();

    /* print header */
    print_fmt("****************************");
    fmt_attr = 0x0F;
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
