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

#include <mips/asm.h>
#include <mips/stack.h>

void svc_entry();
extern uint32_t cur_stack_top;

void umode_jmp(int32_t vaddr, int32_t sp) {

    /* clear TLB */
    arch_vmswitch(&(curproc->umem));

    /* far jump */
    __asm__("move $s1, %0"::"r"(sp));
    __asm__("move $a0, %0"::"r"(((int *) sp)[0]));
    __asm__("move $a1, %0"::"r"(((int *) sp)[1]));
    __asm__("move $a2, %0"::"r"(((int *) sp)[2]));
    __asm__("move $gp, %0"::"r"(svc_entry));
    __asm__("move $sp, $s1; jr %0"::"r"(vaddr));

}

void copy_context(proc_t *child) {

}

void arch_proc_switch(proc_t *oldproc, proc_t *newproc) {

    /* switch between two processes! */

    /* update Task Segment: */
    /* ... */

    /* update CR3 and TLB */
    arch_vmswitch(&(newproc->umem));

    /*cur_stack_top=((uint32_t)&newproc->kstack[KERNEL_STACK_SIZE])|0x80000000;*/

    /* store stack parameters: */
    /*__asm__("mov %%ebp, %%eax":"=a"(oldproc->reg1));
    __asm__("mov %%esp, %%eax":"=a"(oldproc->reg2));*/

    /* retrieve stack parameters of the new process: */
    if (!(newproc->after_fork)) {
        /* get stack parameters: */
        /*int32_t ebp = newproc->reg1;
        int32_t esp = newproc->reg2;
        __asm__("mov %%eax, %%ebp; \n\
                 mov %%ebx, %%esp;"::"a"(ebp), "b"(esp));*/
        return;
    }

    /* clear after fork flag */
    newproc->after_fork = 0;

    /* store context of current process */
    /* ... */

    /* done */

}

void arch_yield() {

}

int32_t arch_get_int_status() {
    return get_status() & 1;
}

void arch_set_int_status(int32_t status) {
    set_status((get_status() & 0xFFFFFFFE)|(status&1));
}

void arch_disable_interrupts() {
    arch_set_int_status(0);
}

void arch_enable_interrupts() {
    arch_set_int_status(1);
}

void print_sp() {
    uint32_t reg;
    __asm__("move %0, $sp":"=r"(reg));
    printk("sp: %x\n", reg);
}

#else

typedef int dummy;

#endif
