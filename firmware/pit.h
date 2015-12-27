#ifndef _MIPSCOMP_PIT_H
#define _MIPSCOMP_PIT_H

#define PIT_BASE        0xBE801000

int pit_read();
void pit_write(int count);
void pit_irq();
void pit_init();

#endif
