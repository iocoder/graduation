#include "vga.h"
#include "string.h"

char *vga       = (char *) VGA_BASE;
char attr;
char fmt_attr;
char scan_attr;
int  row;
int  col;
int  row_base;
int  cursor_shown;
extern unsigned char font[256*16];

void write_to_vga(int index, char data) {
    if (index >= 0xFFD) {
        /* special registers */
        vga[index] = data;
    } else {
        if (index + row_base*160 < 25*160) {
            vga[index + row_base*160] = data;
        } else {
            vga[index + row_base*160 - 25*160] = data;
        }
    }
}

void write_char(int row, int col, char chr, char attr) {
    write_to_vga(row*160+col*2+0, chr);
    write_to_vga(row*160+col*2+1, attr);
}

void write_font(int ascii, int row_indx, char data) {
    vga[0x1000+ascii*16+row_indx] = data;
}

void clear_screen() {
    int i = row = col = row_base = 0;
    write_to_vga(0xFFD, row_base);
    if (cursor_shown) {
        write_to_vga(0xFFE, row);
        write_to_vga(0xFFF, col);
    }
    while (i < 160*25) {
        write_to_vga(i++, 0);
        write_to_vga(i++, attr);
    }
    /* load font */
    for (i = 0; i < 0x1000; i++)
      vga[0x1000+i] = font[i];
}

void move_cursor(int new_col, int new_row) {
    col = new_col;
    row = new_row;
    if (cursor_shown) {
        write_to_vga(0xFFE, row);
        write_to_vga(0xFFF, col);
    }
}

void hide_cursor() {
    cursor_shown = 0;
    write_to_vga(0xFFE, 0xFF);
    write_to_vga(0xFFF, 0xFF);
}

void show_cursor() {
    cursor_shown = 1;
    write_to_vga(0xFFE, row);
    write_to_vga(0xFFF, col);
}

void vga_init() {
    int i;
    /* initialize colors */
    attr = 0x0F;
    fmt_attr = 0x0F;
    scan_attr = 0x0E;
    /* show cursor by default */
    cursor_shown = 1;
    /* clear screen */
    clear_screen();
}

void scroll() {
    int i = 160*24;
    if (row_base == 24) {
        row_base = 0;
    } else {
        row_base++;
    }
    write_to_vga(0xFFD, row_base);
    while (i < 160*25) {
        write_to_vga(i++, 0);
        write_to_vga(i++, attr);
    }
}

void print_char(char c, char attr) {
    if (c == '\n') {
        row++;
        col = 0;
    } else if (c == '\b') {
        col -= 1;
        if (col < 0) {
            col += 80;
            row--;
            if (row < 0) {
                row = 0;
                col = 0;
            }
        }
    } else {
        write_to_vga(row*160+col*2, c);
        write_to_vga(row*160+col*2+1, attr);
        col++;
        if (col == 80) {
            col = 0;
            row++;
        }
    }
    if (row == 25) {
        scroll();
        row = 24;
    }
    if (cursor_shown) {
        write_to_vga(0xFFE, row);
        write_to_vga(0xFFF, col);
    }
}

void print_int(unsigned int num, char attr) {

    char digits[10];
    int i = 0;
    if (!num) {
        digits[i++] = 0;
    } else {
        while (num) {
            digits[i++] = num%10;
            num /= 10;
        }
    }
    while (--i >= 0)
        print_char("0123456789"[digits[i]], attr);

}

void print_hex(unsigned int num, char attr) {
    int i;
    for (i = 28; i >= 0; i-=4)
        print_char("0123456789ABCDEF"[(num>>i)&0xF], attr);
}

void print_str(char *str, char attr) {
    int i = 0;
    while (str[i])
        print_char(str[i++], attr);
}

void print_hf(int line, char *str, char attr) {
    int i;
    int j = line*160;
    int spaces = (80-str_len(str))/2;
    for (i = 0; i < spaces; i++) {
        write_to_vga(j++, ' ');
        write_to_vga(j++, attr);
    }
    for (i = 0; i < str_len(str); i++) {
        write_to_vga(j++, str[i]);
        write_to_vga(j++, attr);
    }
    for (i = 0; i < 80-spaces-str_len(str); i++) {
        write_to_vga(j++, ' ');
        write_to_vga(j++, attr);
    }
}

void print_fmt(char *fmt, ...) {
    int arg_id = 0, i;
    void *addr = &fmt;
    for (i = 0; fmt[i] != 0; i++) {
        if (fmt[i] == '%') {
            switch (fmt[++i]) {
                case 'a':
                    addr = (void *)(((int) addr)+4);
                    fmt_attr = *((char *) addr);
                    break;

                case 'c':
                    addr = (void *)(((int) addr)+4);
                    print_char(*((char *) addr), fmt_attr);
                    break;

                case 'd':
                    addr = (void *)(((int) addr)+4);
                    print_int(*((int *) addr), fmt_attr);
                    break;

                case 'x':
                    addr = (void *)(((int) addr)+4);
                    print_hex(*((int *) addr), fmt_attr);
                    break;

                case 's':
                    addr = (void *)(((int) addr)+4);
                    print_str(*((char **) addr), fmt_attr);
                    break;

                default:
                    break;
            }
        } else {
            print_char(fmt[i], fmt_attr);
        }
    }
}

__asm__(".section .rodata         ");
__asm__("font:                    ");
__asm__(".incbin \"font8x16.fon\" ");
