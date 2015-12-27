#include "vga.h"

void card() {
    /* print machine card */
    fmt_attr = 0x0F;
    print_fmt("\n");
    print_fmt(" Alexandria University,\n");
    print_fmt(" Faculty of Engineering,\n");
    print_fmt(" Computer and Systems Eng. Dept.\n");
    print_fmt("\n");
    print_fmt("     *************************************\n");
    print_fmt("     * ");
    fmt_attr = 0x0A;
    print_fmt(       "MIPS Microcomputer System on FPGA");
    fmt_attr = 0x0F;
    print_fmt(" *\n");
    print_fmt("     *************************************\n");
    print_fmt("\n");
}
