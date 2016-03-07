/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: spinlocks.                                 | |
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
#include <arch/spinlock.h>
#include <sys/mm.h>
#include <sys/scheduler.h>

void spinlock_init(spinlock_t *spinlock) {
    /* initialize spinlock to 0 (currently not acquired) */
    *spinlock = 0;
}

void spinlock_acquire(spinlock_t *spinlock) {
    /* stub */
}

void spinlock_release(spinlock_t *spinlock) {
    /* set spinlock to zero to let other processes
     * be able to hold it by spinlock_acquire().
     */
    *spinlock = 0;
}

#else

typedef int dummy;

#endif
