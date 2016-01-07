#ifndef VM_VGA_H
#define VM_VGA_H

void vga_write(unsigned short addr, unsigned int data);
int vga_update();
void vga_stop();
void vga_init();

#endif
