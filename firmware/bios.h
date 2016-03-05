#ifndef _MIPSCOMP_BIOS_H
#define _MIPSCOMP_BIOS_H

typedef struct {
    /*00*/ void (*write_to_vga)(int index, char data);
    /*01*/ void (*write_char)(int row, int col, char chr, char attr);
    /*02*/ void (*write_font)(int ascii, int row_indx, short data);
    /*03*/ void (*clear_screen)();
    /*04*/ void (*move_cursor)(int new_col, int new_row);
    /*05*/ void (*hide_cursor)();
    /*06*/ void (*show_cursor)();
    /*07*/ void (*print_char)(char c, char attr);
    /*08*/ void (*print_int)(unsigned int num, char attr);
    /*09*/ void (*print_hex)(unsigned int num, char attr);
    /*0A*/ void (*print_str)(char *str, char attr);
    /*0B*/ void (*print_hf)(int line, char *str, char attr);
    /*0C*/ void (*print_fmt)(char *fmt, ...);
} bios_vga_t;

typedef struct {
    /*0D*/ char (*getc)();
    /*0E*/ void (*scan_char)(char *c);
    /*0F*/ void (*scan_str)(char *str);
    /*10*/ int  (*scan_int)(int *num);
} bios_kbd_t;

typedef struct {
    /*11*/ int (*readsect)(int id, int lba, void *buf);
    /*12*/ int (*readsects)(int id, int lba, int count, void *buf);
} bios_disk_t;

typedef struct {
    /*13*/ int (*loadfile)(int id,int firstsect,char *path,unsigned int base);
} bios_diskfs_t;

typedef struct {
    /*14*/ void (**ptrs)(int *regs);
    /*15*/ void (*set_isr_loc)(void *loc);
} bios_isr_t;

typedef struct {
    bios_vga_t    vga;
    bios_kbd_t    kbd;
    bios_disk_t   disk;
    bios_diskfs_t diskfs;
    bios_isr_t    isr;
} bios_t;

extern bios_t bios;

void bios_init();

#endif
