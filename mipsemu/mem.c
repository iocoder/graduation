#include <stdio.h>
#include <stdlib.h>

#include "mem.h"
#include "kbd.h"
#include "vga.h"
#include "pit.h"
#include "pic.h"
#include "ppu.h"
#include "joy.h"

unsigned char ram[0x1000000];
unsigned char rom[0x1000000];

unsigned int read_byte(unsigned char *mem) {
    return *((unsigned char *) mem);
}

unsigned int write_byte(unsigned char *mem, unsigned int word) {
    return *((unsigned char *) mem) = word;
}

unsigned int read_half(unsigned char *mem) {
    return *((unsigned short *) mem);
}

unsigned int write_half(unsigned char *mem, unsigned int word) {
    return *((unsigned short *) mem) = word;
}

unsigned int read_word(unsigned char *mem) {
    return *((unsigned int *) mem);
}

unsigned int write_word(unsigned char *mem, unsigned int word) {
    return *((unsigned int *) mem) = word;
}

unsigned int (*read_fun[])(unsigned char *mem) =
    {read_byte, read_half, read_word};

unsigned int (*write_fun[])(unsigned char *mem, unsigned int word) =
    {write_byte, write_half, write_word};

void dump_mem() {
    FILE *f = fopen("mem.img", "w");
    fwrite(ram, sizeof(ram), 1, f);
    fwrite(rom, sizeof(rom), 1, f);
    fclose(f);
    system("konsole -e hexedit mem.img");
}

unsigned int mem_read(unsigned int addr, int size) {
    /* ------------- memory map -------------
     * -- 0x00000000 - 0x00FFFFFF : RAM
     * -- 0x1E000000 - 0x1E003FFF : VGA
     * -- 0x1E800000 - 0x1E800FFF : KBD
     * -- 0x1E801000 - 0x1E801FFF : PIT
     * -- 0x1E802000 - 0x1E802FFF : PIC
     * -- 0x1EC02000 - 0x1EC02007 : PPU
     * -- 0x1EC04016 - 0x1EC04017 : JOY
     * -- 0x1F000000 - 0x1FFFFFFF : ROM
     */
    if (addr >= 0x00000000 && addr <= 0x00FFFFFF) {
        /* RAM Memory */
        return read_fun[size](&ram[addr & (sizeof(rom)-1)]);
    } else if (addr >= 0x1E000000 && addr <= 0x1E003FFF) {
        /* VGA Memory */
    } else if (addr >= 0x1E800000 && addr <= 0x1E800FFF) {
        /* Keyboard Memory */
        return kbd_read();
    } else if (addr >= 0x1E801000 && addr <= 0x1E801FFF) {
        /* PIT Memory */
        return pit_read();
    } else if (addr >= 0x1E802000 && addr <= 0x1E802FFF) {
        /* PIC Memory */
        return pic_read();
    } else if (addr >= 0x1EC02000 && addr <= 0x1EC02007) {
        /* PPU Memory */
        return ppu_reg_read(addr&7);
    } else if (addr >= 0x1EC04016 && addr <= 0x1EC04017) {
        /* Controller */
        return joypad_read(addr&1);
    } else if (addr >= 0x1F000000 && addr <= 0x1FFFFFFF) {
        /* ROM Memory */
        return read_fun[size](&rom[addr & (sizeof(rom)-1)]);
    }
}

void mem_write(unsigned int addr, unsigned int data, int size) {
    /* ------------- memory map -------------
     * -- 0x00000000 - 0x00FFFFFF : RAM
     * -- 0x1E000000 - 0x1E003FFF : VGA
     * -- 0x1E800000 - 0x1E800FFF : KBD
     * -- 0x1E801000 - 0x1E801FFF : PIT
     * -- 0x1E802000 - 0x1E802FFF : PIC
     * -- 0x1EC02000 - 0x1EC02FFF : PPU
     * -- 0x1EC04016 - 0x1EC04017 : JOY
     * -- 0x1F000000 - 0x1FFFFFFF : ROM
     */
    if (addr >= 0x00000000 && addr <= 0x00FFFFFF) {
        /* RAM Memory */
        write_fun[size](&ram[addr & (sizeof(ram)-1)], data);
    } else if (addr >= 0x1E000000 && addr <= 0x1E003FFF) {
        /* VGA Memory */
        vga_write(addr>>1, data);
    } else if (addr >= 0x1E800000 && addr <= 0x1E800FFF) {
        /* Keyboard memory */
        kbd_write(data);
    } else if (addr >= 0x1E801000 && addr <= 0x1E801FFF) {
        /* PIT Memory */
        pit_write(data);
    } else if (addr >= 0x1E802000 && addr <= 0x1E802FFF) {
        /* PIC Memory */
        pic_write(data);
    } else if (addr >= 0x1EC02000 && addr <= 0x1EC02007) {
        /* PPU Memory */
        ppu_reg_write(addr&7, data);
    } else if (addr >= 0x1EC04016 && addr <= 0x1EC04017) {
        /* Controller */
        joypad_write(data);
    } else if (addr >= 0x1F000000 && addr <= 0x1FFFFFFF) {
        /* ROM Memory */
    }
}

void mem_init(char *firmware_name, char *diskimg_name) {

    FILE *f;
    int i;

    /* load the operating system */
    if (!(f = fopen(diskimg_name, "r"))) {
        fprintf(stderr, "Error: cannot open %s.\n", diskimg_name);
        exit(-2);
    }
    fread(&rom[0x000000], 0xC00000, 1, f);
    fclose(f);

    /* load firmware image */
    if (!(f = fopen(firmware_name, "r"))) {
        fprintf(stderr, "Error: cannot open %s.\n", firmware_name);
        exit(-2);
    }
    fread(&rom[0xC00000], 0x400000, 1, f);
    fclose(f);

    /* fill RAM with garbage */
    /*for (i = 0; i < sizeof(ram); i++)
        ram[i] = i;*/

}
