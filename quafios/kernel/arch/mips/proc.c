/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: process operations.                        | |
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
#include <sys/proc.h>
#include <sys/scheduler.h>
#include <sys/error.h>

void umode_jmp(int32_t vaddr, int32_t sp) {

}

void copy_context(proc_t *child) {

}

void arch_proc_switch(proc_t *oldproc, proc_t *newproc) {

}

void arch_yield() {

}

int32_t arch_get_int_status() {

}

void arch_set_int_status(int32_t status) {

}

void arch_disable_interrupts() {

}

void arch_enable_interrupts() {

}

#else

typedef int dummy;

#endif
