/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> i386: hardware resources.                        | |
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

#ifdef ARCH_I386

#include <arch/type.h>
#include <sys/resource.h>

#include <i386/asm.h>

void iowrite(uint32_t size, uint32_t type, uint32_t val,
             uint32_t base, uint32_t offset) {
    if (size == 1 && type == RESOURCE_TYPE_MEM) {
        *((uint8_t  *) (base + offset)) = (uint8_t ) val;
    } else if (size == 2 && type == RESOURCE_TYPE_MEM) {
        *((uint16_t *) (base + offset)) = (uint16_t) val;
    } else if (size == 4 && type == RESOURCE_TYPE_MEM) {
        *((uint32_t *) (base + offset)) = (uint32_t) val;
    } else if (size == 1 && type == RESOURCE_TYPE_PORT) {
        outb((uint8_t ) val, base + offset);
    } else if (size == 2 && type == RESOURCE_TYPE_PORT) {
        outw((uint16_t) val, base + offset);
    } else if (size == 4 && type == RESOURCE_TYPE_PORT) {
        outl((uint32_t) val, base + offset);
    }
}

uint32_t ioread(uint32_t size, uint32_t type, uint32_t base, uint32_t offset) {
    if (size == 1 && type == RESOURCE_TYPE_MEM) {
        return *((uint8_t  *) (base + offset));
    } else if (size == 2 && type == RESOURCE_TYPE_MEM) {
        return *((uint32_t *) (base + offset));
    } else if (size == 4 && type == RESOURCE_TYPE_MEM) {
        return *((uint32_t *) (base + offset));
    } else if (size == 1 && type == RESOURCE_TYPE_PORT) {
        return inb(base + offset);
    } else if (size == 2 && type == RESOURCE_TYPE_PORT) {
        return inw(base + offset);
    } else if (size == 4 && type == RESOURCE_TYPE_PORT) {
        return inl(base + offset);
    }
}

#else

typedef int dummy;

#endif
