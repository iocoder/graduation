/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS host device driver.                         | |
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

#ifdef SUBARCH_MIPS

#include <arch/type.h>
#include <lib/linkedlist.h>
#include <sys/error.h>
#include <sys/printk.h>
#include <sys/class.h>
#include <sys/mm.h>
#include <sys/resource.h>
#include <sys/device.h>
#include <sys/scheduler.h>
#include <sys/bootinfo.h>
#include <arch/page.h>

/* Prototypes: */
uint32_t mips_probe(device_t *, void *);
uint32_t mips_read (device_t *, uint64_t, uint32_t, char *);
uint32_t mips_write(device_t *, uint64_t, uint32_t, char *);
uint32_t mips_ioctl(device_t *, uint32_t, void *);
uint32_t mips_irq  (device_t *, uint32_t);

/* Classes supported: */
static class_t classes[] = {
    {BUS_GENESIS, BASE_GENESIS_MACHINE, SUB_GENESIS_MACHINE_MIPS, IF_ANY}
};

/* driver_t structure that identifies this driver: */
driver_t mips_driver = {
    /* cls_count: */ sizeof(classes)/sizeof(class_t),
    /* cls:       */ classes,
    /* alias:     */ "mips",
    /* probe:     */ mips_probe,
    /* read:      */ mips_read,
    /* write:     */ mips_write,
    /* ioctl:     */ mips_ioctl,
    /* irq:       */ mips_irq
};

/* ================================================================= */
/*                          Console I/O                              */
/* ================================================================= */

#include "../../../../firmware/bios.h"

bootinfo_t *bootinfo = (bootinfo_t *) 0x8000C000;

void legacy_video_putc(char chr) {
    bios_t *ptr;
    /* get ptr to BIOS structure */
    __asm__("or %0, $0, $gp":"=r"(ptr));
    /* call function */
    ptr->vga.print_fmt("%c", chr);
}

void legacy_video_attr(char attr) {
    bios_t *ptr;
    /* get ptr to BIOS structure */
    __asm__("or %0, $0, $gp":"=r"(ptr));
    /* call function */
    ptr->vga.print_fmt("%a", attr);
}

void legacy_set_isr_loc(void *loc) {
    bios_t *ptr;
    /* get ptr to BIOS structure */
    __asm__("or %0, $0, $gp":"=r"(ptr));
    /* call function */
    ptr->isr.set_isr_loc(loc);
}

/* ================================================================= */
/*                           Interface                               */
/* ================================================================= */

uint32_t mips_probe(device_t* dev, void* config) {
    return ESUCCESS;
}

uint32_t mips_read(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t mips_write(device_t *dev, uint64_t off, uint32_t size, char *buff){
    return ESUCCESS;
}

uint32_t mips_ioctl(device_t *dev, uint32_t cmd, void *data) {
    return ESUCCESS;
}

uint32_t mips_irq(device_t *dev, uint32_t irqn) {
    return ESUCCESS;
}

#else

typedef int dummy;

#endif
