#include <stdio.h>
#include <stdlib.h>

#include "mem.h"
#include "kbd.h"
#include "vga.h"

unsigned char ram[0x10000];
unsigned char rom[0x10000];

unsigned int read_word(unsigned char *mem) {
    return *((unsigned int *) mem);
}

unsigned int write_word(unsigned char *mem, unsigned int word) {
    return *((unsigned int *) mem) = word;
}

void dump_mem() {
    FILE *f = fopen("mem.img", "w");
    fwrite(ram, sizeof(ram), 1, f);
    fwrite(rom, sizeof(rom), 1, f);
    fclose(f);
    system("konsole -e hexedit mem.img");
}

unsigned int mem_read(unsigned int addr) {

    /* memory address is always a multiple of 4 */
    addr = addr & 0xFFFFFFFC;

    /* memory map:
     * ------------
     * 0x00000000 - 0x0000FFFF : FIRMWARE ROM : 64K
     * 0x00010000 - 0x00017FFF : STATIC   RAM : 32K
     * 0x00018FFF - 0x0001FFFF : VGA      RAM : 32K (actual = 8KB)
     * 0xFFF00000 - 0xFFFFFFFF : KEYBOARD I/O
     */
    if (addr >= 0x00000000 && addr <= 0x0000FFFF) {
        /* ROM Memory */
        return read_word(&rom[addr & (sizeof(rom)-1)]);
    } else if (addr >= 0x00010000 && addr <= 0x0001FFFF) {
        /* RAM Memory */
        return read_word(&ram[addr & (sizeof(ram)-1)]);
    } else if (addr >= 0xFFF00000 && addr <= 0xFFFFFFFF) {
        /* Keyboard memory */
        return kbd_read((addr>>2) & 1);
    }

}

void mem_write(unsigned int addr, unsigned int data) {

    /* memory address is always a multiple of 4 */
    addr = addr & 0xFFFFFFFC;

    /* memory map:
     * ------------
     * 0x00000000 - 0x0000FFFF : FIRMWARE ROM : 64K
     * 0x00010000 - 0x00017FFF : STATIC   RAM : 32K
     * 0x00018FFF - 0x0001FFFF : VGA      RAM : 32K (actual = 8KB)
     * 0xFFF00000 - 0xFFFFFFFF : KEYBOARD I/O
     */
    if (addr >= 0x00000000 && addr <= 0x0000FFFF) {
        /* ROM Memory */
    } else if (addr >= 0x00010000 && addr <= 0x00017FFF) {
        /* RAM Memory */
        write_word(&ram[addr & (sizeof(ram)-1)], data);
    } else if (addr >= 0x00018000 && addr <= 0x0001FFFF) {
        /* VGA Memory */
        vga_write(addr>>2,write_word(&ram[addr&(sizeof(ram)-1)],data)&0xFF);
    } else if (addr >= 0xFFF00000 && addr <= 0xFFFFFFFF) {
        /* Keyboard memory */
        kbd_write((addr>>2) & 1, data & 0xFF);
    }

}

void mem_init(char *firmware_name) {

    FILE *f;
    int i;

    /* load the operating system */
    if (!(f = fopen(firmware_name, "r"))) {
        fprintf(stderr, "Error: cannot open %s.\n", firmware_name);
        exit(-2);
    }
    fread(rom, sizeof(rom), 1, f);
    fclose(f);

    /* fill the RAM with garbage */
    for (i = 0; i < sizeof(ram); i++)
        ram[i] = i;

}
