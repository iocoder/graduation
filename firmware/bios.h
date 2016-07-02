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
    /*0D*/ int  (*get_cursor)(char *x, char *y);
    /*0E*/ int  (*set_attr_at_off)(char x, char y, char attr);
    /*0F*/ int  (*set_char_at_off)(char x, char y, char c);
    /*10*/ int  (*set_cursor)(char x, char y);
} bios_vga_t;

typedef struct {
    /*11*/ char (*getc)();
    /*12*/ void (*scan_char)(char *c);
    /*13*/ void (*scan_str)(char *str);
    /*14*/ int  (*scan_int)(int *num);
} bios_kbd_t;

typedef struct {
    /*15*/ int (*readsect)(int id, int lba, void *buf);
    /*16*/ int (*readsects)(int id, int lba, int count, void *buf);
} bios_disk_t;

typedef struct {
    /*17*/ int (*loadfile)(int id,int firstsect,char *path,unsigned int base);
    /*18*/ void (*getuuid)(char *uuid);
} bios_diskfs_t;

typedef struct {
    /*19*/ void (**ptrs)(int *regs);
    /*1A*/ void (*set_isr_loc)(void *loc);
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
