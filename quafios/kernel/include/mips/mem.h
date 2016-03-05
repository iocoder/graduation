/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: memory header.                             | |
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

#ifndef ARCH_MEM_H
#define ARCH_MEM_H

#define MEMORY_LIMIT        __extension__ 0x100000000ULL    /* 4GB. */
#define MEMORY_PAGES        ((uint32_t)(MEMORY_LIMIT/PAGE_SIZE))

extern uint32_t kernel_physical_start;
extern uint32_t kernel_physical_end;

#define MIPS_KMEM_BASE          0x80000000

#define KERNEL_PHYSICAL_START   (((uint32_t) &kernel_physical_start) - \
                                 MIPS_KMEM_BASE)
#define KERNEL_PHYSICAL_END     (((uint32_t) &kernel_physical_end) - \
                                 MIPS_KMEM_BASE)

#define KERNEL_SIZE             (KERNEL_PHYSICAL_END-KERNEL_PHYSICAL_START)

#define KTEXT_MEMORY_BASE       0x00000000
#define KTEXT_MEMORY_END        0x08000000
#define KTEXT_MEMORY_SIZE       (KTEXT_MEMORY_END-KTEXT_MEMORY_BASE)
#define KTEXT_MEMORY_PAGES      (KTEXT_MEMORY_SIZE/PAGE_SIZE)
#define KTEXT_MEMORY_PTABLES    (KTEXT_MEMORY_PAGES/PAGE_TABLE_ENTRY_COUNT)

#define USER_MEMORY_BASE        KTEXT_MEMORY_END
#define USER_MEMORY_END         0xC0000000
#define USER_MEMORY_SIZE        (USER_MEMORY_END-USER_MEMORY_BASE)
#define USER_MEMORY_PAGES       (USER_MEMORY_SIZE/PAGE_SIZE)
#define USER_MEMORY_PTABLES     (USER_MEMORY_PAGES/PAGE_TABLE_ENTRY_COUNT)

#define KERNEL_MEMORY_BASE      USER_MEMORY_END
#define KERNEL_MEMORY_END       MEMORY_LIMIT
#define KERNEL_MEMORY_SIZE      ((uint32_t)(\
                                    KERNEL_MEMORY_END-KERNEL_MEMORY_BASE))
#define KERNEL_MEMORY_PAGES     (KERNEL_MEMORY_SIZE/PAGE_SIZE)
#define KERNEL_MEMORY_PTABLES   (KERNEL_MEMORY_PAGES/PAGE_TABLE_ENTRY_COUNT)

#endif
