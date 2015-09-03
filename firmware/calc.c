#include "calc.h"
#include "vga.h"
#include "kbd.h"
#include "string.h"

char op[256];

void calc() {
    int op1, op2;
    print_fmt("Insert 1st operand: ");
    if (scan_int(&op1)) {
        print_fmt("Invalid number!\n");
        return;
    }
    print_fmt("Enter op (+,-,*,/): ");
    scan_str(op);
    print_fmt("Insert 2nd operand: ");
    if (scan_int(&op2)) {
        print_fmt("Invalid number!\n");
        return;
    }
    if (!str_cmp(op, "+")) {
        print_fmt("    %d\n", op1+op2);
    } else if (!str_cmp(op, "-")) {
        print_fmt("    %d\n", op1-op2);
    } else if (!str_cmp(op, "*")) {
        print_fmt("    %d\n", op1*op2);
    } else if (!str_cmp(op, "/")) {
        print_fmt("    %d\n", op1/op2);
    } else {
        print_fmt("Invalid operation!\n");
    }
}
