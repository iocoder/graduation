#ifndef _MIPSCOMP_VGA_H
#define _MIPSCOMP_VGA_H

#define HEADER_ATTR     0x0E
#define FOOTER_ATTR     0x0F

#define VGA_BASE        0xBE000000

extern int col;
extern char attr;
extern char fmt_attr;
extern char scan_attr;

void write_to_vga(int index, char data);
void write_char(int row, int col, char chr, char attr);
void write_font(int ascii, int row_indx, short data);
void clear_screen();
void move_cursor(int new_col, int new_row);
void hide_cursor();
void show_cursor();
void vga_init();
void print_char(char c, char attr);
void print_int(unsigned int num, char attr);
void print_hex(unsigned int num, char attr);
void print_str(char *str, char attr);
void print_hf(int line, char *str, char attr);
void print_fmt(char *fmt, ...);

#endif
