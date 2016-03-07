/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: panic() procedure.                         | |
 *        | +------------------------------------------------------+ |
 *        +----------------------------------------------------------+
 *
 * This file is part of Quafios 2.0.1 source code.
 * Copyright (C) 2015  Mostafa Abd El-Aziz Mohamed.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Quafios.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Visit http://www.quafios.com/ for contact information.
 *
 */

#ifdef ARCH_MIPS

#include <arch/type.h>
#include <sys/scheduler.h>
#include <sys/printk.h>
#include <tty/vtty.h>

typedef struct {
    int hey;
} Regs;


void print_status() {
    int reg;
    __asm__("mfc0 %0, $12":"=r"(reg):"r"(0xFFFFFFFF));
    printk("STATUS: %x\n", reg);
}

void print_cause() {
    int reg;
    __asm__("mfc0 %0, $13":"=r"(reg):"r"(0xFFFFFFFF));
    printk("CAUSE: %x\n", reg);
}

void print_epc() {
    int reg;
    __asm__("mfc0 %0, $14;":"=r"(reg):"r"(0xFFFFFFFF));
    printk("EPC: %x\n", reg);
}

void print_badvaddr() {
    int reg;
    __asm__("mfc0 %0, $8;":"=r"(reg):"r"(0xFFFFFFFF));
    printk("BadVaddr: %x\n", reg);
}


void panic(Regs *regs, const char *fmt, ...) {
    printk("KERNEL PANIC! %s\n", fmt);
    print_cause();
    print_status();
    print_epc();
    print_badvaddr();
    idle();
}

#else

typedef int dummy;

#endif
