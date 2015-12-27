#include "rom.h"

int rom_readsect(int lba, char *buf) {
    int i;
    for (i = 0; i < 512; i++)
        buf[i] = ((char *) ROM_BASE)[lba*512+i];
    return 0;
}

void rom_init() {
    /* do nothing */
}
