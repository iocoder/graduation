#ifndef _MIPSCOMP_SDCARD_H
#define _MIPSCOMP_SDCARD_H

int sdcard_readsect(int lba, char *buf);
void sdcard_init();

#endif
