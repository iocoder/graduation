/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |                 Quafios Kernel 2.0.1                 | |
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

#include "../../../firmware/bios.h"

bios_t bios __attribute__((section(".bss")));

void bios_init() {
    int i;
    char *ptr;
    /* get ptr to BIOS structure */
    __asm__("or %0, $0, $gp":"=r"(ptr));
    /* copy into bios variable */
    for (i = 0; i < sizeof(bios_t); i++)
        ((char *) &bios)[i] = ptr[i];
}

int main() {
    /* This is the main() function of Quafios kernel :D */
    bios_init();
    bios.vga.print_fmt("Hello from Quafios kernel!\n");
    while(1);
    /*init();*/
    return 0;
}
