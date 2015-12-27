#include "rom.h"
#include "sdcard.h"
#include "disk.h"

int disk_readsect(int id, int lba, void *buf) {
    if (id == 0) {
        return rom_readsect(lba, buf);
    } else if (id == 0x80) {
        return sdcard_readsect(lba, buf);
    } else {
        return -1;
    }
}

int disk_readsects(int id, int lba, int count, void *buf) {
    int i, err;
    for (i = 0; i < count; i++) {
        if (err = disk_readsect(id, lba+i, &((char *) buf)[i*512]))
            return err;
    }
    return 0;
}
