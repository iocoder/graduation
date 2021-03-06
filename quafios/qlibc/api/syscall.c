/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios C Standard Library.                         | |
 *        | |  -> API: syscall() routine.                          | |
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

#include <api/syscall.h>

uint32_t svc_entry;

void syscall_init() {
    __asm__("move %0, $gp":"=r"(svc_entry));
}

int syscall(int number, ...) {

    int *arg = &number;
    int ret;

    __asm__("move $s0, %0"::"r"(arg[0]));
    __asm__("move $s1, %0"::"r"(arg[1]));
    __asm__("move $s2, %0"::"r"(arg[2]));
    __asm__("move $s3, %0"::"r"(arg[3]));
    __asm__("move $s4, %0"::"r"(arg[4]));
    __asm__("move $s5, %0"::"r"(arg[5]));
    __asm__("move $s6, $ra");
    __asm__("jal  %0"::"r"(svc_entry));
    __asm__("move $ra, $s6");
    __asm__("move %0, $s0":"=r"(ret));

    return ret;

}
