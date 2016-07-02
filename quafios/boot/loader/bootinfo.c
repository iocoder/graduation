/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios MIPS Boot-Loader.                           | |
 *        | |  -> bootinfo structure.                              | |
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

#include <arch/type.h>
#include <sys/bootinfo.h>
#include "../../../firmware/bios.h"

bootinfo_t *bootinfo = (bootinfo_t *) 0x8000C000;

void bootinfo_init() {

    uint32_t cont = 0;
    
    /* read memory layout: */
    bootinfo->mem_ents = 1;
    bootinfo->mem_ent[0].base         = 0;
    bootinfo->mem_ent[0].end          = 16*1024*1024;

    /* determine RAM regions that should be reserved: */
    bootinfo->res[BI_BOOTLOADER].base = 0x08000;
    bootinfo->res[BI_BOOTLOADER].end  = 0x0C000;

    bootinfo->res[BI_BOOTINFO].base   = 0x0C000;
    bootinfo->res[BI_BOOTINFO].end    = 0x10000;

    bootinfo->res[BI_KERNEL].base     = 0x10000;
    bootinfo->res[BI_KERNEL].end      = 0x10000; /* temp value */

    bootinfo->res[BI_RAMDISK].base    = 0x1F000000;
    bootinfo->res[BI_RAMDISK].end     = 0x1FC00000;

    bootinfo->res[BI_ARCH0].base      = 0x00000;
    bootinfo->res[BI_ARCH0].end       = 0x08000; /* BIOS */

    bootinfo->res[BI_ARCH1].base      = 0x00000;
    bootinfo->res[BI_ARCH1].end       = 0x00000;

    bootinfo->res[BI_ARCH2].base      = 0x00000;
    bootinfo->res[BI_ARCH2].end       = 0x00000;

    /* live? */
    bootinfo->live = 1;
    bios.diskfs.getuuid(bootinfo->uuid);


}
