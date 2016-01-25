#ifndef VM_VGA_H
#define VM_VGA_H

void vga_write(unsigned short addr, unsigned int data);
void vga_render();
void vga_stop();
void vga_init();

#endif
