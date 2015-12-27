#ifndef _MIPSCOMP_ROM_H
#define _MIPSCOMP_ROM_H

#define ROM_BASE        0xBF000000

int rom_readsect(int lba, char *buf);
void rom_init();

#endif
