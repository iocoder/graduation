#ifndef VM_MEM_H
#define VM_MEM_H

void dump_mem();
unsigned int mem_read(unsigned int addr);
void mem_write(unsigned int addr, unsigned int data);
void mem_init(char *firmware_name);

#endif
