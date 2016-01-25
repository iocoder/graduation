#include "vga.h"
#include "kbd.h"
#include "disk.h"
#include "diskfs.h"
#include "bios.h"
#include "isr.h"

bios_t bios;

void bios_init() {
    /* VGA routines */
    bios.vga.write_to_vga = write_to_vga;
    bios.vga.write_char   = write_char;
    bios.vga.write_font   = write_font;
    bios.vga.clear_screen = clear_screen;
    bios.vga.move_cursor  = move_cursor;
    bios.vga.hide_cursor  = hide_cursor;
    bios.vga.show_cursor  = show_cursor;
    bios.vga.print_char   = print_char;
    bios.vga.print_int    = print_int;
    bios.vga.print_hex    = print_hex;
    bios.vga.print_str    = print_str;
    bios.vga.print_hf     = print_hf;
    bios.vga.print_fmt    = print_fmt;

    /* KBD routines */
    bios.kbd.getc         = getc;
    bios.kbd.scan_char    = scan_char;
    bios.kbd.scan_str     = scan_str;
    bios.kbd.scan_int     = scan_int;

    /* disk routines */
    bios.disk.readsect    = disk_readsect;
    bios.disk.readsects   = disk_readsects;

    /* diskfs routines */
    bios.diskfs.loadfile  = diskfs_loadfile;

    /* isr routines */
    bios.isr.ptrs         = isr;

    /* load gp register with ptr to bios structure */
    __asm__("or $gp, $0, %0"::"r"(&bios));
}
