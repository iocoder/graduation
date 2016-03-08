/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: IRQ handler.                               | |
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
#include <arch/irq.h>
#include <sys/error.h>
#include <sys/mm.h>
#include <sys/device.h>
#include <sys/scheduler.h>
#include <sys/semaphore.h>

#define IRQ_COUNT 0x10

typedef struct {
    uint32_t    usable;      /* can be used?              */
    device_t   *pic_device;  /* Reservation Queue.        */
    linkedlist  requeue;     /* reservation queue (FCFS). */
} irq_t;

irq_t irq[IRQ_COUNT] = {0};

unsigned char chr;

semaphore_t irqsema = {1};

int32_t irq_setup(uint32_t n, device_t *pic_device) {

    if (n >= IRQ_COUNT)
        return ENOENT;

    /* setup an IRQ entry: */
    sema_down(&irqsema);
    irq[n].pic_device = pic_device;
    irq[n].usable     = 1;
    sema_up(&irqsema);

    /* return: */
    return ESUCCESS;

}

uint32_t irq_reserve(uint32_t n, irq_reserve_t *reserve) {

    int32_t status;

    if (n >= IRQ_COUNT || !irq[n].usable)
        return ENOENT;

    /* enter critical region */
    status = arch_get_int_status();
    arch_disable_interrupts();

    /* add the request to the tail of the queue: */
    linkedlist_addlast(&(irq[n].requeue), reserve);

    /* exit critical region */
    arch_set_int_status(status);

    /* done. */
    return ESUCCESS;

}

void irq_handler(uint32_t n) {

    int32_t status;

    if (n >= IRQ_COUNT || !irq[n].usable)
        return; /* nothing to do here. */

    /* enter critical region */
    status = arch_get_int_status();
    arch_disable_interrupts();

    if (irq[n].requeue.count) {
        /* The IRQ is to be served (apply FIRST COME FIRST SERVED). */
        irq_reserve_t *req     = (irq_reserve_t *) irq[n].requeue.first;
        device_t      *dev     = req->dev;
        uint32_t       expires = req->expires;
        void          *data    = req->data;
        if (expires) {
            /* delete the request from the queue */
            linkedlist_aremove(&(irq[n].requeue), (linknode *) req);
        }
        /* now serve it! */
        dev_irq(dev, n, data);
    }

    /* exit critical region */
    arch_set_int_status(status);

    /* Send End of Interrupt Command: */
    dev_ioctl(irq[n].pic_device, 0, NULL);

    /* call scheduler? */
    if (n == scheduler_irq) {
        ticks++;
        scheduler();
    }

}

int32_t irq_to_vector(uint32_t n) {
    return n;
}

void enable_irq_system() {
    arch_enable_interrupts();
}

void irq_entry() {

    int n = 0;

    /* for debugging */
    *((unsigned short *) 0xBE000000) = chr++;

    /* ask for interrupt number */
    dev_ioctl(irq[0].pic_device, 1, &n);

    /* handle interrupt */
    irq_handler(n);

}

void test() {
    int n;
    dev_ioctl(irq[0].pic_device, 1, &n);
    printk("n: %d\n", n);
}

#else

typedef int dummy;

#endif
