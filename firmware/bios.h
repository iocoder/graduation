#ifndef _MIPSCOMP_BIOS_H
#define _MIPSCOMP_BIOS_H

typedef struct {
    void (*write_to_vga)(int index, char data);
    void (*write_char)(int row, int col, char chr, char attr);
    void (*write_font)(int ascii, int row_indx, short data);
    void (*clear_screen)();
    void (*move_cursor)(int new_col, int new_row);
    void (*hide_cursor)();
    void (*show_cursor)();
    void (*print_char)(char c, char attr);
    void (*print_int)(unsigned int num, char attr);
    void (*print_hex)(unsigned int num, char attr);
    void (*print_str)(char *str, char attr);
    void (*print_hf)(int line, char *str, char attr);
    void (*print_fmt)(char *fmt, ...);
} bios_vga_t;

typedef struct {
    char (*getc)();
    void (*scan_char)(char *c);
    void (*scan_str)(char *str);
    int  (*scan_int)(int *num);
} bios_kbd_t;

typedef struct {
    int (*readsect)(int id, int lba, void *buf);
    int (*readsects)(int id, int lba, int count, void *buf);
} bios_disk_t;

typedef struct {
    int (*loadfile)(int id, int firstsect, char *path, unsigned int base);
} bios_diskfs_t;

typedef struct {
    bios_vga_t    vga;
    bios_kbd_t    kbd;
    bios_disk_t   disk;
    bios_diskfs_t diskfs;
} bios_t;

extern bios_t bios;

void bios_init();

#endif
