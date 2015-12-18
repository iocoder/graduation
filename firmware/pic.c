#include "pic.h"

int *pic_reg = (int *) PIC_BASE;

int pic_read() {

    return *pic_reg;

}

void pic_enable() {

    *pic_reg = 1;

}

void pic_disable() {

    *pic_reg = 0;

}

void pic_init() {

    pic_enable();

}
