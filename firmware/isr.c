#include "vga.h"
#include "kbd.h"
#include "pit.h"
#include "pic.h"
#include "isr.h"

void (*isr[8])(int *regs);

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

void handle_interrupt(int *regs) {
    switch (pic_read()) {
        case 0:
            pit_irq();
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
    if (isr[pic_read()&7])
        isr[pic_read()&7](regs);
    //print_epc();
    //print_cause();
    //print_fmt("int source: %x\n", pic_read());
    pic_enable();
}

void isr_init() {
    int i;
    /* initialize ISRs with NULL */
    for (i = 0; i < 8; i++)
        isr[i] = 0;
    /* initialize status register */
    __asm__("mtc0 %0, $12"::"r"(0xABCDDCBF));

}
