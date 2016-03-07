/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> Quafios Alarm.                                   | |
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

#include <sys/scheduler.h>
#include <timer/generic.h>

typedef struct internal_alert {

    struct internal_alert *next;
    int32_t  pid;
    int8_t   prefix;
    uint64_t when;

} internal_alert_t;

internal_alert_t *first_alert = NULL;

uint64_t alarm_ticks = 0;

void alarm_reg(timer_alert_t * req) {
    internal_alert_t *alert = kmalloc(sizeof(internal_alert_t));
    alert->pid    = curproc->pid;
    alert->prefix = req->prefix;
    alert->when   = req->time/10 + alarm_ticks;
    alert->next   = first_alert;
    first_alert   = alert;
    /*printk("ticks: %d\n", (int) alarm_ticks);*/
}

void alert() {

    /* local vars */
    uint32_t status, tt;
    char buf[10] = {0};
    msg_t msg;
    internal_alert_t *ptr, *prev = NULL, *next;

    /* increase tick counter. */
    alarm_ticks++;

    /* alert all the processes that need to be alerted */
    ptr = first_alert;
    while (ptr != NULL) {
        internal_alert_t *next = ptr->next;
        if (alarm_ticks >= ptr->when) {
            next = ptr->next;
            msg.buf = buf;
            msg.size = 10;
            buf[0] = ptr->prefix;
            /*printk("ticks: %d\n", (int) alarm_ticks);*/
            send(ptr->pid, &msg);
            kfree(ptr);
            if (prev == NULL) {
                first_alert = next;
            } else {
                prev->next = next;
            }
            ptr = next;
        }
    }

    /* i sometimes enjoy watching this: */
#if 0
    tt = (uint32_t) alarm_ticks;
    if (!(tt % 100))
        printk("second: %d\n", tt/100);
#endif

}
