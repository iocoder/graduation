/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> i386 - ISR - system call handler.                | |
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

/* System Call Handler is actually the interface between running applications
 * and kernel. Applications do invoke system calls via interrupt gate 0x80.
 */

#ifdef ARCH_MIPS

#include <arch/type.h>
#include <arch/irq.h>
#include <sys/error.h>
#include <sys/mm.h>
#include <sys/device.h>
#include <sys/scheduler.h>
#include <sys/semaphore.h>

int syscall(int32_t number, ...);

void svc(uint32_t *regs) {

    /* a system call signal recieved...
     * please refer to include/syscall.h...
     */

    regs[16]=syscall(regs[16],regs[17],regs[18],regs[19],regs[20],regs[21]);

}

#endif
