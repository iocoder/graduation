#include "mem.h"
#include "vga.h"
#include "kbd.h"
#include "string.h"

char op[256];

void mem() {
    int addr;
    int data;
    print_fmt("Choose operation (r,w): ");
    scan_str(op);
    if (!str_cmp(op, "r")) {
        print_fmt("Insert memory addess: ");
        if (scan_int(&addr)) {
            print_fmt("Invalid address!\n");
            return;
        }
        print_fmt("Data @0x%x is: %x\n", addr, *((unsigned int *) addr));
    } else if (!str_cmp(op, "w")) {
        print_fmt("Insert memory addess: ");
        if (scan_int(&addr)) {
            print_fmt("Invalid address!\n");
        }
        print_fmt("Insert data: ");
        if (scan_int(&data)) {
            print_fmt("Invalid number!\n");
            return;
        }
        *((unsigned int *) addr) = data;
    } else {
        print_fmt("Invalid operation!\n");
    }
}
