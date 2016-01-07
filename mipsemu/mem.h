#ifndef VM_MEM_H
#define VM_MEM_H

void dump_mem();
unsigned int mem_read(unsigned int addr, int size);
void mem_write(unsigned int addr, unsigned int data, int size);
void mem_init(char *firmware_name, char *diskimg_name);

#endif
