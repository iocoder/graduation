#include <stdio.h>

#include "pic.h"
#include "pit.h"

unsigned int max_counter;
unsigned int counter;
unsigned int total_cycles;

void pit_write(unsigned int data) {
    max_counter = data;
    counter = 0;
}

unsigned int pit_read() {
    return counter;
}

void pit_clk() {
    total_cycles++;
    if (max_counter) {
        counter++;
        if (counter == max_counter) {
            counter = 0;
            pic_irq(0);
        }
    }
}

void pit_init() {
    max_counter = 0;
    counter = 0;
    total_cycles = 0;
}
