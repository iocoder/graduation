/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: assembly header                            | |
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

#ifndef ASM_H
#define ASM_H

#include <arch/type.h>

/* coprocessor registers */
#define INDEX     "0"
#define ENTRY_LO  "2"
#define BADVADDR  "8"
#define ENTRY_HI  "10"
#define SR        "12"
#define CAUSE     "13"
#define EPC       "14"

/* coprocessor instructions */
#define mtc0(rs, nn) __asm__("mtc0 %0, $" nn::"r"(rs))
#define mfc0(rs, nn) __asm__("mfc0 %0, $" nn:"=r"(rs))
#define rfe()        __asm__("rfe")
#define tlbr()       __asm__("tlbr")
#define tlbwi()      __asm__("tlbwi")

/* coprocessor register I/O */
#define get_index()    __extension__ \
                       (({uint32_t __reg; mfc0(__reg, INDEX); __reg;}))
#define get_entrylo()  __extension__ \
                       (({uint32_t __reg; mfc0(__reg, ENTRY_LO); __reg;}))
#define get_badvaddr() __extension__ \
                       (({uint32_t __reg; mfc0(__reg, BADVADDR); __reg;}))
#define get_entryhi()  __extension__ \
                       (({uint32_t __reg; mfc0(__reg, ENTRY_HI); __reg;}))
#define get_status()   __extension__ \
                       (({uint32_t __reg; mfc0(__reg, SR); __reg;}))
#define get_cause()   __extension__ \
                       (({uint32_t __reg; mfc0(__reg, CAUSE); __reg;}))
#define get_epc()     __extension__ \
                       (({uint32_t __reg; mfc0(__reg, EPC); __reg;}))

#define set_index(val)    __extension__ (({mtc0(val, INDEX);}))
#define set_entrylo(val)  __extension__ (({mtc0(val, ENTRY_LO);}))
#define set_entryhi(val)  __extension__ (({mtc0(val, ENTRY_HI);}))
#define set_status(val)   __extension__ (({mtc0(val, SR);}))

#endif
