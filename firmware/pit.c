#include "vga.h"
#include "pit.h"

int *counter_reg = (int *) PIT_BASE;
int ticks;
char chr;

int pit_read() {

    return *counter_reg;

}

void pit_write(int count) {

    *counter_reg = count;

}

void pit_irq() {

    /*write_to_vga(0, chr++);*/
    /*print_fmt("0x%x seconds passed.\n", ++ticks);*/

}

void pit_init() {

    /* interrupt every 10ms */
    pit_write(500000);

    /* initialize tick counter */
    ticks = 0;

}
