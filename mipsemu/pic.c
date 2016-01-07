#include <stdio.h>

#include "cpu.h"
#include "pic.h"

int int_device;
int pic_enable;
int pic_int[8] = {0};
int pic_has_int;

void pic_write(unsigned int data) {
    if (data&1) {
        pic_enable = 1;
        if (pic_has_int) {
            cpu_irq();
        }
    } else {
        pic_enable = 0;
    }
}

unsigned int pic_read() {
    return int_device;
}

void pic_irq(int irqno) {
    if (!pic_int[irqno]) {
        pic_int[irqno] = 1;
        pic_has_int++;
        if (pic_enable) {
            cpu_irq();
        }
    }
}

void pic_iak() {
    int i;
    for (i = 0; i < 8 && !pic_int[i]; i++);
    if (i == 8) {
        /* ? */
    } else {
        pic_int[i] = 0; /* interrupt served */
        int_device = i;
        pic_has_int--;
        pic_enable = 0;
    }
}

void pic_init() {
    int_device = 0;
    pic_enable = 0;
    pic_has_int = 0;
}
