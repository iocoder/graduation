#ifndef _6502COMP_VGA_H
#define _6502COMP_VGA_H

#define HEADER_ATTR     0x0E
#define FOOTER_ATTR     0x0F

#define VGA_BASE        0xE0000000

extern char attr;
extern char fmt_attr;
extern char scan_attr;

void clear_screen(char _attr, char _fmt_attr, char _scan_attr);
void print_char(char c, char attr);
void print_int(unsigned int num, char attr);
void print_hex(unsigned int num, char attr);
void print_str(char *str, char attr);
void print_hf(int line, char *str, char attr);
void print_fmt(char *fmt, ...);

#endif
