#ifndef _MIPSCOMP_PIC_H
#define _MIPSCOMP_PIC_H

#define PIC_BASE        0xBE802000

int pic_read();
void pic_enable();
void pic_disable();
void pic_init();

#endif
