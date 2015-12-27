#ifndef _MIPSCOMP_DISK_H
#define _MIPSCOMP_DISK_H

int disk_readsect(int id, int lba, void *buf);
int disk_readsects(int id, int lba, int count, void *buf);

#endif
