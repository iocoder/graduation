#ifndef VM_VGA_H
#define VM_VGA_H

void vga_write(unsigned short addr, unsigned char data);
int vga_update();
void vga_stop();
void vga_init();

#endif
