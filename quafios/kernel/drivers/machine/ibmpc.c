/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> IBM PC host device driver.                       | |
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

#ifdef SUBARCH_IBMPC

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
#include <i386/asm.h>
#include <timer/8253.h>
#include <pic/8259A.h>
#include <video/generic.h>

/* Prototypes: */
uint32_t ibmpc_probe(device_t *, void *);
uint32_t ibmpc_read (device_t *, uint64_t, uint32_t, char *);
uint32_t ibmpc_write(device_t *, uint64_t, uint32_t, char *);
uint32_t ibmpc_ioctl(device_t *, uint32_t, void *);
uint32_t ibmpc_irq  (device_t *, uint32_t);

/* Classes supported: */
static class_t classes[] = {
    {BUS_GENESIS, BASE_GENESIS_MACHINE, SUB_GENESIS_MACHINE_IBMPC, IF_ANY}
};

/* driver_t structure that identifies this driver: */
driver_t ibmpc_driver = {
    /* cls_count: */ sizeof(classes)/sizeof(class_t),
    /* cls:       */ classes,
    /* alias:     */ "ibmpc",
    /* probe:     */ ibmpc_probe,
    /* read:      */ ibmpc_read,
    /* write:     */ ibmpc_write,
    /* ioctl:     */ ibmpc_ioctl,
    /* irq:       */ ibmpc_irq
};

/* ================================================================= */
/*                       Legacy Video Routines                       */
/* ================================================================= */

/* Generic VGA characteristics of IBM PC: */
#define VGA_MEMORY_BASE         0xB8000 /* all IBM PCs support this */

#define VGA_MAX_ROWS            25
#define VGA_MAX_COLS            80

void legacy_video_newline();
void legacy_video_putc(char);
void legacy_video_attr(char);
void legacy_video_clear(char);
void legacy_video_init();

/*static char vga[PAGE_SIZE] __attribute__((aligned(PAGE_SIZE))); */
bootinfo_t *bootinfo = (bootinfo_t *) 0x10000;

/* fonts */
extern uint8_t _font8x16_start[256][16];
extern uint8_t _font10x24_start[256][24][2];

/* initialization info */
static uint32_t vga_initialized = 0;
static uint32_t vga_vmem = 0;

/* enable/disable access to VGA LFB in graphics mode */
uint32_t legacy_lfb_enabled = 1;

/* vga info (text mode) */
static char *vga;
char *legacy_vga;
static char ibuf[VGA_MAX_ROWS*VGA_MAX_COLS*2]; /*used for graphics mode text*/
static uint32_t vga_row, vga_col;
static uint32_t vga_row_old, vga_col_old;
static uint32_t vga_attrib;
uint8_t bg_attrib = 0x0F;

/* vga info (graphics mode) */
static uint32_t vga_width;
static uint32_t vga_height;
static uint32_t vga_depth;
static uint8_t* vga_fbuf;
static uint32_t vga_scanline;
uint8_t* legacy_vga_fbuf;

/* vga mode */
static uint32_t vga_mode;
uint32_t legacy_vga_mode;

/* info about initialization process */
extern int32_t page_initialized;
extern int32_t kmem_initialized;

/* color palette */
static uint32_t color_palette[] = {
     0x000000,
     0x0000AA,
     0x00AA00,
     0x00AAAA,
     0xAA0000,
     0xAA00AA,
     0xAA5500,
     0xAAAAAA,
     0x555555,
     0x5555FF,
     0x55FF55,
     0x55FFFF,
     0xFF5555,
     0xFF55FF,
     0xFFFF55,
     0xFFFFFF
};

void legacy_reboot() {
    while (inb(0x64) & 0x02);
    outb(0xFE, 0x64); /* send RESET pulse. */
}

void legacy_draw_pixel(uint32_t x, uint32_t y, uint32_t rgb) {

    /* the offset in the frame buffer to draw the pixel at */
    uint32_t offset = y*vga_scanline+x*((vga_depth+1)/8);

    /* within boundaries? */
    if (x >= vga_width || y >= vga_height)
        return;

    /* access to LFB is disabled? */
    if (!legacy_lfb_enabled)
        return;

    /* insert colors */
    vga_fbuf[offset + 0] = (rgb>> 0) & 0xFF; /* b */
    vga_fbuf[offset + 1] = (rgb>> 8) & 0xFF; /* g */
    vga_fbuf[offset + 2] = (rgb>>16) & 0xFF; /* r */

}

void legacy_draw_char(char chr, char attr, int x, int y) {

    uint32_t chr_width = 10;
    uint32_t chr_height = 24;
    uint32_t chr_pos_x = (chr_width)*x;
    uint32_t chr_pos_y = (chr_height)*y;
    uint32_t bg = color_palette[(attr >> 4) & 0xF];
    uint32_t fg = color_palette[(attr >> 0) & 0xF];
    int32_t i, j, k;

    if (chr == 0)
        chr = ' ';

    /* write to text buffer */
    vga[y*VGA_MAX_COLS*2+x*2+0] = chr;
    vga[y*VGA_MAX_COLS*2+x*2+1] = attr;

    /* if text mode, we are done... */
    if (vga_mode == 0)
        return;

    /* vga linear frame buffer controversy */
    if (page_initialized) {
        if (!kmem_initialized) {
            /* we can't access the framebuffer at that time */
            return;
        } else if (!vga_vmem) {
            /* we need direct access to VGA frame buffer */
            uint32_t vga_size = vga_scanline*vga_height;
            uint32_t vga_pages = vga_size/PAGE_SIZE +
                                 (vga_size%PAGE_SIZE ? 1:0);
            legacy_vga_fbuf = vga_fbuf = kmalloc(vga_pages*PAGE_SIZE);
            for (i = 0; i < vga_pages; i++)
                arch_set_page(NULL, vga_fbuf+(i*PAGE_SIZE),
                              bootinfo->vga_phys+(i*PAGE_SIZE));
            vga_vmem = 1;
        }

    }

    /* draw using the font */
    for (j = 0; j < chr_width; j++)
        for (k = 0; k < chr_height; k++) {
            if (chr_width == 9) {
                /* 8x16 */
                if (j < 8 && (_font8x16_start[chr][k]&(1<<(7-j)))) {
                    legacy_draw_pixel(chr_pos_x+j, chr_pos_y+k, fg);
                } else {
                    legacy_draw_pixel(chr_pos_x+j, chr_pos_y+k, bg);
                }
            } else if (chr_width == 10) {
                /* 10x24 */
                int bit;
                if (j < 8) {
                    bit = _font10x24_start[chr][k][0]&(1<<(7-j));
                } else {
                    bit = _font10x24_start[chr][k][1]&(1<<(15-j));
                }
                legacy_draw_pixel(chr_pos_x+j, chr_pos_y+k, bit?fg:bg);
            }
        }

    /* draw cursor if any */
    for (j = 0; j < chr_width && x == vga_col && y == vga_row; j++) {
        legacy_draw_pixel(chr_pos_x+j,chr_pos_y+chr_height-1, fg);
        legacy_draw_pixel(chr_pos_x+j,chr_pos_y+chr_height-2, fg);
    }

}

int32_t legacy_get_cursor(char *x, char *y) {
    *x = vga_col;
    *y = vga_row;
    return ESUCCESS;
}

int32_t legacy_set_attr_at_off(char x, char y, char attr) {
    legacy_draw_char(vga[y*VGA_MAX_COLS*2+x*2], attr, x, y);
    return ESUCCESS;
}

int32_t legacy_set_char_at_off(char x, char y, char c) {
    legacy_draw_char(c, vga[y*VGA_MAX_COLS*2+x*2+1], x, y);
    return ESUCCESS;
}

void legacy_update_cursor() {
    int32_t loc;

    if (!vga_initialized)
        legacy_video_init();

    if (vga_mode == 1) {
        legacy_draw_char(ibuf[vga_row_old*160+vga_col_old*2+0],
                         ibuf[vga_row_old*160+vga_col_old*2+1],
                         vga_col_old, vga_row_old);
        vga_row_old = vga_row;
        vga_col_old = vga_col;
        legacy_draw_char(ibuf[vga_row_old*160+vga_col_old*2+0],
                         ibuf[vga_row_old*160+vga_col_old*2+1],
                         vga_col_old, vga_row_old);
        return;
    }

    loc = vga_row*VGA_MAX_COLS + vga_col;

    outb(0x0E, 0x03D4);
    outb((loc>>8) & 0xFF, 0x03D5);

    outb(0x0F, 0x03D4);
    outb((loc>>0) & 0xFF, 0x03D5);
}

int32_t legacy_set_cursor(char x, char y) {
    vga_col = x;
    vga_row = y;
    legacy_update_cursor();
    return ESUCCESS;
}

void legacy_redraw() {

    int32_t i, j;

    if (vga_mode == 0)
        return;

    /* background */
    for (i = 0; i < vga_height; i++)
        for (j = 0; j < vga_width; j++)
            legacy_draw_pixel(j, i, color_palette[(bg_attrib>>4)&0xF]);

    /* redraw all lines */
    for (i = 0; i < VGA_MAX_ROWS; i++)
        for (j = 0; j < VGA_MAX_COLS; j++)
            legacy_draw_char(vga[i*VGA_MAX_COLS*2+j*2+0],
                             vga[i*VGA_MAX_COLS*2+j*2+1],j,i);

}

void legacy_scroll() {
    uint32_t i, j;

    if (!vga_initialized)
        legacy_video_init();

    for (i=0; i< 80 * 24 * 2; i++)
        vga[i] = vga[i + 80 * 2];

    /* clean last row: */
    for (; i < 80 * 25 * 2; i+=2)
        vga[i] = ' ';

    /* if text mode, we are done */
    if (vga_mode == 0)
        return;

    /* redraw all lines */
    for (i = 0; i < VGA_MAX_ROWS; i++)
        for (j = 0; j < VGA_MAX_COLS; j++)
            legacy_draw_char(vga[i*VGA_MAX_COLS*2+j*2+0],
                             vga[i*VGA_MAX_COLS*2+j*2+1],j,i);
}

void legacy_video_newline() {
    if (!vga_initialized)
        legacy_video_init();

    vga_col = 0;

    if (vga_row != VGA_MAX_ROWS - 1) {
        vga_row++;
    } else {
        legacy_scroll();
    }

    legacy_update_cursor();
}

void legacy_video_putc(char chr) {
    char new_col = 0, new_row = 0;

    if (!vga_initialized) legacy_video_init();

    switch (chr) {
        case '\n':
            legacy_video_newline();
            break;

        case '\t':
            do legacy_video_putc(' '); while(vga_col%8);
            break;

        case '\b':
            if (vga_col == 0 && vga_row) {
                vga_row--;
                vga_col = VGA_MAX_COLS - 1;
            } else if (vga_row == 0 && vga_col == 0) {
                /* Do nothing... */
            } else {
                vga_col = vga_col - 1;
            }
            legacy_update_cursor();
            break;

        default:
            legacy_draw_char (chr, vga_attrib, vga_col, vga_row);
            if (vga_col != VGA_MAX_COLS-1) {
                vga_col = vga_col+1;
                legacy_update_cursor();
            } else {
                legacy_video_newline();
            }
    }
}

void legacy_video_attr(char attr) {
    if (!vga_initialized)
        legacy_video_init();
    vga_attrib = attr;
}

void legacy_video_clear (char attr) {
    int32_t i = 0, j = 0;
    if (!vga_initialized)
        legacy_video_init();
    vga_attrib = attr;
    vga_col = vga_row = 0;
    vga_col_old = vga_row_old = 0;
    for (i = 0; i < VGA_MAX_ROWS; i++)
        for (j = 0; j < VGA_MAX_COLS; j++)
            legacy_draw_char(0, vga_attrib, j, i);
}

void legacy_video_init() {

    int i;

    /* read vga mode */
    legacy_vga_mode = vga_mode = bootinfo->vga_mode;

    /* mode specific settings */
    if (bootinfo->vga_mode == 1) {

        /* graphics mode */
        vga_width    = bootinfo->vga_width;
        vga_height   = bootinfo->vga_height;
        vga_depth    = bootinfo->vga_depth;
        legacy_vga_fbuf = vga_fbuf = (uint8_t *) bootinfo->vga_phys;
        vga_scanline = bootinfo->vga_scanline;
        legacy_vga = vga = ibuf;

        /* zeroise cursor offsets */
        vga_row = vga_row_old = 0;
        vga_col = vga_col_old = 0;

        /* initialize the internal text frame buffer */
        for (i = 0; i < sizeof(ibuf); i+=2) {
            ibuf[i+0] = 0x00;
            ibuf[i+1] = 0x0F;
        }

    } else {

        /* text mode */
        legacy_vga = vga = (char *) VGA_MEMORY_BASE;

        /* read cursor offsets from bios data area: */
        vga_row = ((char *) 0x450)[1];
        vga_col = ((char *) 0x450)[0];

#if 0
        /* Hide Cursor: */
        outw(0x200A /* Start Line Register Index + (Hide code * 0x100) */,
             0x03D4);
        outw(0x000B /* End   Line Register Index + (Hide code * 0x100) */,
             0x03D4);
#endif

        /* Diable Blinking: */
        inb(0x3DA);        /* let 0x3C0 go to "index" state. */
        outb(0x30, 0x3C0); /* select "Mode Control" register (index 0x10). */
        outb(inb(0x3C1) & 0xF7, 0x3C0);

    }

    /* initialize attribute: */
    vga_attrib = VGA_BG_BLACK + VGA_FG_WHITE;

    /* done */
    vga_initialized = 1;

}

/* ================================================================= */
/*                           Interface                               */
/* ================================================================= */

uint32_t ibmpc_probe(device_t* dev, void* config) {

    bus_t *hostbus;
    device_t *t;
    class_t cls;
    reslist_t reslist = {0, NULL};
    resource_t *resv;
    i8259_init_t pic1_config, pic2_config;
    i8253_init_t timer_config;

    /* Inform the user of our progress: */
    printk("Quafios is running on an IBM PC/AT Compatible Machine.\n");

    /* Create host bus: */
    dev_mkbus(&hostbus, BUS_HOST, dev);

    /*        Genesis
     *         | | |
     *   Mem---+ | +---VTTY
     *           |
     *       Host Machine
     *         | | |
     *  8259---+ | +---PCI
     *           |
     *          8253
     *
     */

    /* I) Intel's 8259A PIC:
     * ----------------------
     * The default interrupt controller used in the original
     * IBM personal computer.
     * In IBM PC/AT, they were actually two PICs, one was master
     * and the other was slave.
     */
    /* class of the PIC device: */
    cls.bus    = BUS_ISA;
    cls.base   = BASE_ISA_INTEL;
    cls.sub    = SUB_ISA_INTEL_8259A;
    cls.progif = IF_ANY;
    /* resources of the master pic: */
    resv = (resource_t *) kmalloc(sizeof(resource_t)*1);
    if (resv == NULL) return ENOMEM;
    resv[0].type = RESOURCE_TYPE_PORT;
    resv[0].data.port.base = 0x20; /* standard. */
    resv[0].data.port.size = 2;    /* 2 bytes. */
    /* resource list: */
    reslist.count = 1;
    reslist.list  = resv;
    /* config structure: */
    pic1_config.baseirq   = 0;
    pic1_config.cascade   = CASCADE_MASTER;
    pic1_config.casirq    = 2;
    pic1_config.master    = NULL;
    pic1_config.irqenable = 0;
    /* now add pic1: */
    dev_add(&t, hostbus, cls, reslist, &pic1_config);

    /* resources of secondary pic: */
    resv = (resource_t *) kmalloc(sizeof(resource_t)*1);
    if (resv == NULL) return ENOMEM;
    resv[0].type = RESOURCE_TYPE_PORT;
    resv[0].data.port.base = 0xA0; /* standard. */
    resv[0].data.port.size = 2;    /* 2 bytes.  */
    /* resource list: */
    reslist.count = 1;
    reslist.list  = resv;
    /* config: */
    pic2_config.baseirq   = 8;
    pic2_config.cascade   = CASCADE_SLAVE;
    pic2_config.casirq    = 2;
    pic2_config.master    = t;
    pic2_config.irqenable = 1;
    /* now add pic2: */
    dev_add(&t, hostbus, cls, reslist, &pic2_config);

    /* II) Intel's 8253 Timer:
     * ------------------------
     * The default programmable interval timer used in the original
     * IBM personal computer.
     * We are gonna use it to execute the scheduler each specific
     * interval of time.
     */
    /* class for the 8253 chip: */
    cls.bus    = BUS_ISA;
    cls.base   = BASE_ISA_INTEL;
    cls.sub    = SUB_ISA_INTEL_8253;
    cls.progif = IF_ANY;
    /* resources: */
    resv = (resource_t *) kmalloc(sizeof(resource_t)*2);
    if (resv == NULL) return ENOMEM;
    resv[0].type = RESOURCE_TYPE_PORT;
    resv[0].data.port.base = 0x40; /* standard. */
    resv[0].data.port.size = 4;    /* 4 bytes. */
    resv[1].type = RESOURCE_TYPE_IRQ;
    resv[1].data.irq.number = 0;   /* 8253 is connected to IRQ0 line. */
    /* resource list: */
    reslist.count = 2;
    reslist.list  = resv;
    /* config:
     * i8253 contains 3 clocks, they are used in IBM PC as follows:
     * CLK 0 -> connected to IRQ0.
     * CLK 1 -> almost not used
     * CLK 2 -> connected to PC speaker.
     * The oscillator of i8253 runs at a frequency of
     * 1.193181666666 MHz (666666 is recurring) in IBM PC.
     * We will make use of it to generate IRQ0 each 10ms, so that
     * Quafios task scheduler is called every 10ms.
     * According to physics:
     * T = 1 / f; < periodic time >
     * counter = required_interval / T
     * therefore: counter = required_interval * f
     *                    = 0.01 * 1193181 = 11931
     */
    timer_config.clock[0].count = 1193181 * SCHEDULER_INTERVAL;
    timer_config.clock[0].mode  = 3;     /* CLK 0 should operate in mode 3. */
    timer_config.clock[0].catch_irq = 1; /* catch. */

    timer_config.clock[1].count = 0;     /* ignore it. */
    timer_config.clock[1].mode  = 0;     /* ignored. */
    timer_config.clock[1].catch_irq = 0; /* no irq. */

    timer_config.clock[2].count = 0;     /* ignore it. */
    timer_config.clock[2].mode  = 0;     /* ignored. */
    timer_config.clock[2].catch_irq = 0; /* ignored. */

    /* now add the timer: */
    dev_add(&t, hostbus, cls, reslist, &timer_config);

    /* configure the scheduler: */
    scheduler_irq = 0; /* IRQ0. */

    /* III) Video Graphics Array (VGA):
     * ---------------------------------
     * VGA is a piece of hardware that's responsible for
     * adapting graphics on screen.
     */
    cls.bus    = BUS_ISA;
    cls.base   = BASE_ISA_IBM;
    cls.sub    = SUB_ISA_IBM_VGA;
    cls.progif = IF_ANY;
    /* resources: */
    resv = (resource_t *) kmalloc(sizeof(resource_t)*4);
    if (resv == NULL) return ENOMEM;
    resv[0].type = RESOURCE_TYPE_PORT;
    resv[0].data.port.base = 0x0;
    resv[0].data.port.size = 1;
    /* resource list: */
    reslist.count = 4;
    reslist.list  = resv;
    /* now add the VGA: */
    dev_add(&t, hostbus, cls, reslist, NULL);

    /* IV) PCI System:
     * ----------------
     */
    cls.bus    = BUS_HOST;
    cls.base   = BASE_HOST_SUBSYSTEM;
    cls.sub    = SUB_HOST_SUBSYSTEM_PCI;
    cls.progif = IF_ANY;
    /* resources: */
    resv = (resource_t *) kmalloc(sizeof(resource_t)*1);
    if (resv == NULL)
        return ENOMEM;
    resv[0].type = RESOURCE_TYPE_PORT;
    resv[0].data.port.base = 0xCF8;      /* standard in IBM PC. */
    resv[0].data.port.size = 8;          /* 2 doublewords. */
    /* resource list: */
    reslist.count = 1;
    reslist.list  = resv;
    /* now add the device: */
    dev_add(&t, hostbus, cls, reslist, NULL);

    /* done */
    return ESUCCESS;
}

uint32_t ibmpc_read(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t ibmpc_write(device_t *dev, uint64_t off, uint32_t size, char *buff){
    return ESUCCESS;
}

uint32_t ibmpc_ioctl(device_t *dev, uint32_t cmd, void *data) {
    return ESUCCESS;
}

uint32_t ibmpc_irq(device_t *dev, uint32_t irqn) {
    return ESUCCESS;
}

#else

typedef int dummy;

#endif
