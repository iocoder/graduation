/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: stack header.                              | |
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

#ifndef STACK_H
#define STACK_H

#include <i386/protect.h>
#include <arch/type.h>

/* Registers & Stacks:  */
/* -------------------- */
#define store_reg()     printk("stack.h: store_reg() stub!\n")
#define restore_reg()   printk("stack.h: restore_reg() stub!\n")

typedef struct {
    int x;
} Regs;

#define get_regs()      printk("stack.h: get_regs() stub!")

/* Stack: */
#define USER_STACK_SIZE         0x1000000 /* 16MB       */
#define KERNEL_STACK_SIZE       4*1024    /* 4KB Stack. */
extern uint8_t kernel_stack[];

#define stack_switch()  printk("stack.h: stack_switch() stub!")

#endif
