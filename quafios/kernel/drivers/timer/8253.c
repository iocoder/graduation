/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> i8253 Timer Device Driver.                       | |
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

/* x86 Programmable Interval Timer */

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
#include <timer/8253.h>
#include <timer/generic.h>
#include <sys/semaphore.h>

/* Prototypes: */
uint32_t i8253_probe(device_t *, void *);
uint32_t i8253_read (device_t *, uint64_t, uint32_t, char *);
uint32_t i8253_write(device_t *, uint64_t, uint32_t, char *);
uint32_t i8253_ioctl(device_t *, uint32_t, void *);
uint32_t i8253_irq  (device_t *, uint32_t);

/* Classes supported: */
static class_t classes[] = {
    {BUS_ISA, BASE_ISA_INTEL, SUB_ISA_INTEL_8253, IF_ANY}
};

/* driver_t structure that identifies this driver: */
driver_t i8253_driver = {
    /* cls_count: */ sizeof(classes)/sizeof(class_t),
    /* cls:       */ classes,
    /* alias:     */ "i8253_timer",
    /* probe:     */ i8253_probe,
    /* read:      */ i8253_read,
    /* write:     */ i8253_write,
    /* ioctl:     */ i8253_ioctl,
    /* irq:       */ i8253_irq
};

#define CLK0    0 /* Clock 0 Count Register / Output Latch */
#define CLK1    1 /* Clock 0 Count Register / Output Latch */
#define CLK2    2 /* Clock 0 Count Register / Output Latch */

#define CWR     3 /* Control Word Register */

/* Control Word Format: */
typedef union {
    struct {
        unsigned bcd  :1; /* 0: 16-bit binary counter.
                           * 1: Binary Coded Decimal Counter.
                           */
        unsigned mode :3; /* 0..5: from mode 0 -> mode 5. */
        unsigned rw   :2; /* R/W mode:
                           * 00: Counter Latch Command.
                           * 01: Read/Write LSB only.
                           * 10: Read/Write MSB only.
                           * 11: LSB first, then MSB.
                           */
        unsigned sc   :2; /* Select Counter:
                           * 00: Counter 0.
                           * 01: Counter 1.
                           * 10: Counter 2.
                           * 11: Read-back command.
                           */
    } __attribute__ ((packed)) data;
    uint8_t val;          /* CWR as one character */
} cwr_t;

typedef struct {
    uint32_t iotype;
    uint32_t iobase;
    struct {
        uint64_t counter;
        uint64_t ticks;
        uint8_t  mode;
        uint8_t  catch_irq;
        uint32_t irqn;
    } clock[3]; /* 3 clocks are embedded in the 8253. */
} info_t;

/* ================================================================= */
/*                             Chip I/O                              */
/* ================================================================= */

static void set_cr(device_t *dev, uint8_t val, uint32_t clock) {
    /* set initial counter value */
    info_t *info = (info_t *) dev->drvreg;
    iowrite(1, info->iotype, val, info->iobase, clock);
}

static void set_cw(device_t *dev, cwr_t word) {
    /* set control word register */
    info_t *info = (info_t *) dev->drvreg;
    iowrite(1, info->iotype, word.val, info->iobase, CWR);
}

/* ================================================================= */
/*                            Interface                              */
/* ================================================================= */

uint32_t i8253_probe(device_t *dev, void *config) {

    /* counters and variables */
    uint32_t i, j = 1;
    i8253_init_t *cfg = config;
    cwr_t cwr;

    /* create info_t structure: */
    info_t *info = (info_t *) kmalloc(sizeof(info_t));
    dev->drvreg = (uint32_t) info;
    if (info == NULL)
        return ENOMEM; /* i am sorry :D */

    /* Read I/O info: */
    info->iotype = dev->resources.list[0].type;
    info->iobase = dev->resources.list[0].data.port.base;

    /* PIT - Programmable interval timer is a chip that
     * consists of an oscillator, a prescaler, and 3
     * independent frequency dividers.
     * Basically, the oscillator runs at a frequency of
     * 1.193181666666 MHz (666666 is recurring) in IBM PC.
     * The frequency should be passed through config->frequency.
     *
     * We can calculate the periodic time of making one full
     * oscillation from the equation:
     * T = 1 / f
     * while f is the frequency of PIT.
     *
     * PIT has 3 separate programmable frequency dividers (aka
     * channels). The idea of the divider is the "counter".
     * The divider will decrease the counter after each full
     * pulse, until the counter is zero, the divider then takes
     * a specific action (like invoking an IRQ).
     *
     * For example, if counter of channel 0 is set to 2, then
     * PIT's oscillator will make 2 full oscillations, then
     * channel 0 triggers an IRQ. After then, the oscillator
     * makes 2 other oscillations, then channel 0 invokes an
     * IRQ, and so on...
     *
     * Quafios will use channel 0 to generate IRQ 0 each 1ms.
     *
     * the counter of channel 0 can be caluclated from that
     * interval using the formula:
     * counter = required_interval / T
     * while T is the periodic time of one oscillation. but
     * T = 1 / f; Then:
     * counter = required_interval * f
     */

    for (i = 0; i < 3; i++) {
        /* Program the clock (i): */
        info->clock[i].counter   = cfg->clock[i].count;
        info->clock[i].ticks     = 0;
        info->clock[i].mode      = cfg->clock[i].mode;
        info->clock[i].catch_irq = cfg->clock[i].catch_irq;

        if (info->clock[i].catch_irq) {
            /* catch irq. */
            irq_reserve_t *reserve = kmalloc(sizeof(irq_reserve_t));
            info->clock[i].irqn = dev->resources.list[j++].data.irq.number;
            reserve->dev     = dev;
            reserve->expires = 0;
            reserve->data    = NULL;
            irq_reserve(info->clock[i].irqn, reserve);
        }

        if (!(info->clock[i].counter)) continue; /* ignored clock. */

        /* Prepare Control Word Register: */
        cwr.data.bcd  = 0;                    /* binary mode.       */
        cwr.data.mode = info->clock[i].mode;  /* clock mode.        */
        cwr.data.rw   = 3;                    /* send LSB then MSB. */
        cwr.data.sc   = i;                    /* Select Clock i.    */

        /* Send Control Word Register: */
        set_cw(dev, cwr);

        /* set the counter value of CLOCK i: */
        set_cr(dev, ((info->clock[i].counter)>>0)&0xFF, i);
        set_cr(dev, ((info->clock[i].counter)>>8)&0xFF, i);

    }

    /* add to devfs */
    devfs_reg("timer", dev->devid);

    /* done: */
    printk("i8253 interval timer driver loaded.\n");
    return ESUCCESS;
}

uint32_t i8253_read(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t i8253_write(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t i8253_ioctl(device_t *dev, uint32_t cmd, void *data) {

    /* get info_t structure: */
    info_t *info = (info_t *) dev->drvreg;
    if (info == NULL)
        return ENOMEM; /* i am sorry :D */
    /* handle request */
    if (cmd == TIMER_ALERT) {
        alarm_reg(data);
    }
    /* done */
    return ESUCCESS;
}

uint32_t i8253_irq(device_t *dev, uint32_t irqn) {

    /* respond to timer IRQ. */
    uint32_t i;

    /* get info_t structure: */
    info_t *info = (info_t *) dev->drvreg;
    if (info == NULL)
        return ENOMEM; /* i am sorry :D */

    /* get the interrupting clock: */
    for(i = 0; i < 3; i++)
        if (info->clock[i].catch_irq && info->clock[i].irqn == irqn)
            break;
    if (i == 3)
        return ENOENT;

    /* call alarm */
    alert();

    /* done */
    return ESUCCESS;

}
