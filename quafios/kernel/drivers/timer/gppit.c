/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> CS-401 Timer Device Driver.                      | |
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
#include <arch/irq.h>
#include <lib/linkedlist.h>
#include <sys/error.h>
#include <sys/printk.h>
#include <sys/mm.h>
#include <sys/class.h>
#include <sys/resource.h>
#include <sys/device.h>
#include <sys/scheduler.h>
#include <sys/ipc.h>
#include <timer/generic.h>
#include <arch/irq.h>

/* Prototypes: */
uint32_t gppit_probe(device_t *, void *);
uint32_t gppit_read (device_t *, uint64_t, uint32_t, char *);
uint32_t gppit_write(device_t *, uint64_t, uint32_t, char *);
uint32_t gppit_ioctl(device_t *, uint32_t, void *);
uint32_t gppit_irq  (device_t *, uint32_t);

/* Classes supported: */
static class_t classes[] = {
    {BUS_GP, BASE_GP_PIT, SUB_GP_PIT, IF_ANY}
};

/* driver_t structure that identifies this driver: */
driver_t gppit_driver = {
    /* cls_count: */ sizeof(classes)/sizeof(class_t),
    /* cls:       */ classes,
    /* alias:     */ "gppit",
    /* probe:     */ gppit_probe,
    /* read:      */ gppit_read,
    /* write:     */ gppit_write,
    /* ioctl:     */ gppit_ioctl,
    /* irq:       */ gppit_irq
};

/* ================================================================= */
/*                            Interface                              */
/* ================================================================= */

uint32_t gppit_probe(device_t *dev, void *config) {

    /* local vars */
    uint32_t *pitreg;
    irq_reserve_t *reserve;

    /* get ptr to pit memory-mapped register */
    pitreg = (uint32_t *) dev->resources.list[0].data.mem.base;

    /* enable interrupt every 10ms */
    *pitreg = 500000; /* 50MHz / 500000 = 100Hz */

    /* register the driver at IRQ center */
    reserve = kmalloc(sizeof(irq_reserve_t));
    reserve->dev     = dev;
    reserve->expires = 0;
    reserve->data    = NULL;
    irq_reserve(dev->resources.list[1].data.irq.number, reserve);

    /* add to devfs */
    devfs_reg("timer", dev->devid);

    /* print into */
    printk("Programmable interval timer driver has loaded.\n");

    /* done */
    return ESUCCESS;

}

uint32_t gppit_read(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t gppit_write(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t gppit_ioctl(device_t *dev, uint32_t cmd, void *data) {
    if (cmd == TIMER_ALERT)
        alarm_reg(data);
    return ESUCCESS;
}

uint32_t gppit_irq(device_t *dev, uint32_t irqn) {
    alert();
    return ESUCCESS;
}
