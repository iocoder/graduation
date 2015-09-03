#include "shell.h"
#include "vga.h"
#include "kbd.h"
#include "string.h"
#include "calc.h"
#include "mem.h"

static char str[256];

void test();

void help() {
    print_fmt("Available commands:\n");
    print_fmt("- help\n");
    print_fmt("- version\n");
    print_fmt("- calc\n");
    print_fmt("- mem\n");
    print_fmt("- test\n");
    print_fmt("- clear\n");
    print_fmt("- reboot\n");
    print_fmt("- shutdown\n");
}

void version() {
    print_fmt("6502 FPGA Computer OS ported to MIPS, version 1.2 %s",
              "(Feb 2015)\n");
}

void reboot() {
    __asm__("j start");
}

void shutdown() {
    print_fmt("You can now safely power off your computer.\n");
    while(1);
}

void shell() {
    print_fmt("Welcome to MIPS computer shell. ");
    print_fmt("Type `help' for command listing.\n");
    while(1) {
        print_fmt("> ");
        scan_str(str);
        if (!str_cmp(str, "help")) {
            help();
        } else if (!str_cmp(str, "version")) {
            version();
        } else if (!str_cmp(str, "calc")) {
            calc();
        } else if (!str_cmp(str, "mem")) {
            mem();
        } else if (!str_cmp(str, "test")) {
            test();
        } else if (!str_cmp(str, "clear")) {
            clear_screen(attr, fmt_attr, scan_attr);
        } else if (!str_cmp(str, "reboot")) {
            reboot();
        } else if (!str_cmp(str, "shutdown")) {
            shutdown();
        } else if (!str_cmp(str, "")) {
            /* do nothing */
        } else {
            print_fmt("Error: command not found.\n");
        }
    }
}
