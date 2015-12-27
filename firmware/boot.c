#include "vga.h"
#include "disk.h"
#include "diskfs.h"

int try_disk(int id) {
    int firstsect, err;
    /* find boot partition */
    firstsect = find_boot_part(id);
    if (firstsect < 0) {
        return firstsect;
    }
    /* try to load boot loader */
    err = diskfs_loadfile(id, firstsect, "boot/loader.bin", 0x80008000);
    if (err) {
        return err;
    }
    /* jmp to 0x80008000 */
    __asm__("jr %0"::"r"(0x80008000));
}

void boot() {
    while (1) {
        try_disk(0);
        /* print err msg */
        fmt_attr = 0x0C;
        print_fmt("No valid bootable medium found! "
                  "drop to BIOS shell...\n\n");
        fmt_attr = 0x0F;
        /* execute shell */
        shell();
    }
}
