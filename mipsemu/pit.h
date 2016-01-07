#ifndef VM_PIT_H
#define VM_PIT_H

void pit_write(unsigned int data);
unsigned int pit_read();
void pit_clk();
void pit_init();

#endif
