#ifndef _6502COMP_KBD_H
#define _6502COMP_KBD_H

#define KBD_BUF_SIZE    16
#define KBD_BASE        0xFFF00000
#define KBD_DATA        0
#define KBD_STATUS      1

void scan_char(char *c);
void scan_str(char *str);
int scan_int(int *num);
void kbd_init();

#endif

