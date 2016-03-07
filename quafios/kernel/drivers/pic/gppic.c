/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> CS-401 PIC Device Driver                         | |
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
#include <lib/linkedlist.h>
#include <sys/error.h>
#include <sys/printk.h>
#include <sys/mm.h>
#include <sys/class.h>
#include <sys/resource.h>
#include <sys/device.h>

/* Prototypes: */
uint32_t gppic_probe(device_t *, void *);
uint32_t gppic_read (device_t *, uint64_t, uint32_t, char *);
uint32_t gppic_write(device_t *, uint64_t, uint32_t, char *);
uint32_t gppic_ioctl(device_t *, uint32_t, void *);
uint32_t gppic_irq  (device_t *, uint32_t);

/* Classes supported: */
static class_t classes[] = {
    {BUS_GP, BASE_GP_PIC, SUB_GP_PIC, IF_ANY}
};

/* driver_t structure that identifies this driver: */
driver_t gppic_driver = {
    /* cls_count: */ sizeof(classes)/sizeof(class_t),
    /* cls:       */ classes,
    /* alias:     */ "gppic",
    /* probe:     */ gppic_probe,
    /* read:      */ gppic_read,
    /* write:     */ gppic_write,
    /* ioctl:     */ gppic_ioctl,
    /* irq:       */ gppic_irq
};

typedef struct {
    uint32_t *picreg;
} info_t;

/* ================================================================= */
/*                            Interface                              */
/* ================================================================= */

uint32_t gppic_probe(device_t *dev, void *config) {

    /* local vars */
    int i;

    /* create info_t structure: */
    info_t *info = (info_t *) kmalloc(sizeof(info_t));
    dev->drvreg = (uint32_t) info;
    if (info == NULL)
        return ENOMEM;

    /* print something */
    printk("PIC device driver is loading...\n");

    /* store data: */
    info->picreg = (uint32_t *) dev->resources.list[0].data.mem.base;

    /* Initialize IRQs: */
    for (i = 0; i < 8; i++)
        irq_setup(i, dev);

    /* Enable IRQ system: */
    enable_irq_system();

    /* finally enable PIC */
    *info->picreg = 1;

    /* done */
    return ESUCCESS;

}

uint32_t gppic_read(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t gppic_write(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t gppic_ioctl(device_t* dev, uint32_t c, void *data) {
    /* get info_t structure: */
    info_t *info = (info_t *) dev->drvreg;
    if (info == NULL)
            return ENOMEM;
    switch (c) {
        case 0:
            /* EOI */
            *info->picreg = 1;
            return ESUCCESS;
        case 1:
            /* query */
            *((uint32_t *) data) = *info->picreg;
            return ESUCCESS;
        default:
            return EBUSY;
    }
}

uint32_t gppic_irq(device_t *dev, uint32_t irqn) {
    return ESUCCESS;
}
