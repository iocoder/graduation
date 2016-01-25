#ifndef VM_PPU_H
#define VM_PPU_H

unsigned char ppu_reg_read(int reg);
void ppu_reg_write(unsigned short reg, unsigned char data);
void ppu_render();
void ppu_clk();
void ppu_init();

#endif
