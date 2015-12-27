#include "vga.h"
#include "kbd.h"
#include "pit.h"
#include "pic.h"
#include "isr.h"

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
    //print_epc();
    //print_cause();
    //print_fmt("int source: %x\n", pic_read());
    pic_enable();
}

void isr_init() {
    /* initialize status register */
    __asm__("mtc0 %0, $12"::"r"(0xABCDDCBF));
}
