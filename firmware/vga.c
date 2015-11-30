#include "vga.h"
#include "string.h"

char *vga       = (char *) VGA_BASE;
char attr;
char fmt_attr;
char scan_attr;
int  row;
int  col;
int  row_base;

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

void clear_screen(char _attr, char _fmt_attr, char _scan_attr) {
    int i = row = col = row_base = 0;
    attr = _attr;
    fmt_attr = _fmt_attr;
    scan_attr = _scan_attr;
    write_to_vga(0xFFD, row_base);
    write_to_vga(0xFFE, row);
    write_to_vga(0xFFF, col);
    while (i < 160*25) {
        write_to_vga(i++, 0);
        write_to_vga(i++, attr);
    }
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
    write_to_vga(0xFFE, row);
    write_to_vga(0xFFF, col);
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
