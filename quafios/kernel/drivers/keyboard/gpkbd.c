/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> CS-401 Keyboard Device Driver.                   | |
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
#include <tty/vtty.h>
#include <keyboard/generic.h>
#include <sys/scheduler.h>

/* Prototypes: */
uint32_t gpkbd_probe(device_t *, void *);
uint32_t gpkbd_read (device_t *, uint64_t, uint32_t, char *);
uint32_t gpkbd_write(device_t *, uint64_t, uint32_t, char *);
uint32_t gpkbd_ioctl(device_t *, uint32_t, void *);
uint32_t gpkbd_irq  (device_t *, uint32_t);

/* Classes supported: */
static class_t classes[] = {
    {BUS_GP, BASE_GP_KBD, SUB_GP_KBD, IF_ANY}
};

/* driver_t structure that identifies this driver: */
driver_t gpkbd_driver = {
    /* cls_count: */ sizeof(classes)/sizeof(class_t),
    /* cls:       */ classes,
    /* alias:     */ "gpkbd",
    /* probe:     */ gpkbd_probe,
    /* read:      */ gpkbd_read,
    /* write:     */ gpkbd_write,
    /* ioctl:     */ gpkbd_ioctl,
    /* irq:       */ gpkbd_irq
};

typedef struct {
    uint32_t *kbdreg;

    uint32_t escaped;
    uint32_t breaked;

    uint32_t num_lock;
    uint32_t caps_lock;
    uint32_t scroll_lock;

    uint32_t control;
    uint32_t altkey;
    uint32_t shift;

    device_t *dev;
} info_t;


/*****************************************************************************/
/*                                 MAPS                                      */
/*****************************************************************************/

#define NON     0x00 /* none         */
#define KEY     0x01 /* normal key   */
#define NPD     0x02 /* number pad   */
#define CTR     0x03 /* control key  */
#define ALT     0x04 /* alt key      */
#define LSH     0x05 /* left shift   */
#define RSH     0x06 /* right shift  */
#define NUM     0x07 /* num lock     */
#define CPS     0x08 /* caps lock    */
#define SCR     0x09 /* scroll lock  */
#define FUN     0x0A /* function key */
#define ESC     0x0B /* escaped key  */

/* Translation map (from AT to old XT) */
const unsigned char trans[] = {
    /* 00 */ 0xff, /* 01 */ 0x43, /* 02 */ 0x41, /* 03 */ 0x3f,
    /* 04 */ 0x3d, /* 05 */ 0x3b, /* 06 */ 0x3c, /* 07 */ 0x58,
    /* 08 */ 0x64, /* 09 */ 0x44, /* 0A */ 0x42, /* 0B */ 0x40,
    /* 0C */ 0x3e, /* 0D */ 0x0f, /* 0E */ 0x29, /* 0F */ 0x59,
    /* 10 */ 0x65, /* 11 */ 0x38, /* 12 */ 0x2a, /* 13 */ 0x70,
    /* 14 */ 0x1d, /* 15 */ 0x10, /* 16 */ 0x02, /* 17 */ 0x5a,
    /* 18 */ 0x66, /* 19 */ 0x71, /* 1A */ 0x2c, /* 1B */ 0x1f,
    /* 1C */ 0x1e, /* 1D */ 0x11, /* 1E */ 0x03, /* 1F */ 0x5b,
    /* 20 */ 0x67, /* 21 */ 0x2e, /* 22 */ 0x2d, /* 23 */ 0x20,
    /* 24 */ 0x12, /* 25 */ 0x05, /* 26 */ 0x04, /* 27 */ 0x5c,
    /* 28 */ 0x68, /* 29 */ 0x39, /* 2A */ 0x2f, /* 2B */ 0x21,
    /* 2C */ 0x14, /* 2D */ 0x13, /* 2E */ 0x06, /* 2F */ 0x5d,
    /* 30 */ 0x69, /* 31 */ 0x31, /* 32 */ 0x30, /* 33 */ 0x23,
    /* 34 */ 0x22, /* 35 */ 0x15, /* 36 */ 0x07, /* 37 */ 0x5e,
    /* 38 */ 0x6a, /* 39 */ 0x72, /* 3A */ 0x32, /* 3B */ 0x24,
    /* 3C */ 0x16, /* 3D */ 0x08, /* 3E */ 0x09, /* 3F */ 0x5f,
    /* 40 */ 0x6b, /* 41 */ 0x33, /* 42 */ 0x25, /* 43 */ 0x17,
    /* 44 */ 0x18, /* 45 */ 0x0b, /* 46 */ 0x0a, /* 47 */ 0x60,
    /* 48 */ 0x6c, /* 49 */ 0x34, /* 4A */ 0x35, /* 4B */ 0x26,
    /* 4C */ 0x27, /* 4D */ 0x19, /* 4E */ 0x0c, /* 4F */ 0x61,
    /* 50 */ 0x6d, /* 51 */ 0x73, /* 52 */ 0x28, /* 53 */ 0x74,
    /* 54 */ 0x1a, /* 55 */ 0x0d, /* 56 */ 0x62, /* 57 */ 0x6e,
    /* 58 */ 0x3a, /* 59 */ 0x36, /* 5A */ 0x1c, /* 5B */ 0x1b,
    /* 5C */ 0x75, /* 5D */ 0x2b, /* 5E */ 0x63, /* 5F */ 0x76,
    /* 60 */ 0x55, /* 61 */ 0x56, /* 62 */ 0x77, /* 63 */ 0x78,
    /* 64 */ 0x79, /* 65 */ 0x7a, /* 66 */ 0x0e, /* 67 */ 0x7b,
    /* 68 */ 0x7c, /* 69 */ 0x4f, /* 6A */ 0x7d, /* 6B */ 0x4b,
    /* 6C */ 0x47, /* 6D */ 0x7e, /* 6E */ 0x7f, /* 6F */ 0x6f,
    /* 70 */ 0x52, /* 71 */ 0x53, /* 72 */ 0x50, /* 73 */ 0x4c,
    /* 74 */ 0x4d, /* 75 */ 0x48, /* 76 */ 0x01, /* 77 */ 0x45,
    /* 78 */ 0x57, /* 79 */ 0x4e, /* 7A */ 0x51, /* 7B */ 0x4a,
    /* 7C */ 0x37, /* 7D */ 0x49, /* 7E */ 0x46, /* 7F */ 0x54,
    /* 80 */ 0x00, /* 81 */ 0x00, /* 82 */ 0x00, /* 83 */ 0x41,
    /* 84 */ 0x7F, /* 85 */ 0x00, /* 86 */ 0x00, /* 87 */ 0x00,
    /* 88 */ 0x00, /* 89 */ 0x00, /* 8A */ 0x00, /* 8B */ 0x00,
    /* 8C */ 0x00, /* 8D */ 0x00, /* 8E */ 0x00, /* 8F */ 0x00,
    /* 90 */ 0x00, /* 91 */ 0x00, /* 92 */ 0x00, /* 93 */ 0x00,
    /* 94 */ 0x00, /* 95 */ 0x00, /* 96 */ 0x00, /* 97 */ 0x00,
    /* 98 */ 0x00, /* 99 */ 0x00, /* 9A */ 0x00, /* 9B */ 0x00,
    /* 9C */ 0x00, /* 9D */ 0x00, /* 9E */ 0x00, /* 9F */ 0x00,
    /* A0 */ 0x00, /* A1 */ 0x00, /* A2 */ 0x00, /* A3 */ 0x00,
    /* A4 */ 0x00, /* A5 */ 0x00, /* A6 */ 0x00, /* A7 */ 0x00,
    /* A8 */ 0x00, /* A9 */ 0x00, /* AA */ 0x00, /* AB */ 0x00,
    /* AC */ 0x00, /* AD */ 0x00, /* AE */ 0x00, /* AF */ 0x00,
    /* B0 */ 0x00, /* B1 */ 0x00, /* B2 */ 0x00, /* B3 */ 0x00,
    /* B4 */ 0x00, /* B5 */ 0x00, /* B6 */ 0x00, /* B7 */ 0x00,
    /* B8 */ 0x00, /* B9 */ 0x00, /* BA */ 0x00, /* BB */ 0x00,
    /* BC */ 0x00, /* BD */ 0x00, /* BE */ 0x00, /* BF */ 0x00,
    /* C0 */ 0x00, /* C1 */ 0x00, /* C2 */ 0x00, /* C3 */ 0x00,
    /* C4 */ 0x00, /* C5 */ 0x00, /* C6 */ 0x00, /* C7 */ 0x00,
    /* C8 */ 0x00, /* C9 */ 0x00, /* CA */ 0x00, /* CB */ 0x00,
    /* CC */ 0x00, /* CD */ 0x00, /* CE */ 0x00, /* CF */ 0x00,
    /* D0 */ 0x00, /* D1 */ 0x00, /* D2 */ 0x00, /* D3 */ 0x00,
    /* D4 */ 0x00, /* D5 */ 0x00, /* D6 */ 0x00, /* D7 */ 0x00,
    /* D8 */ 0x00, /* D9 */ 0x00, /* DA */ 0x00, /* DB */ 0x00,
    /* DC */ 0x00, /* DD */ 0x00, /* DE */ 0x00, /* DF */ 0x00,
    /* E0 */ 0xE0, /* E1 */ 0xE1, /* E2 */ 0x00, /* E3 */ 0x00,
    /* E4 */ 0x00, /* E5 */ 0x00, /* E6 */ 0x00, /* E7 */ 0x00,
    /* E8 */ 0x00, /* E9 */ 0x00, /* EA */ 0x00, /* EB */ 0x00,
    /* EC */ 0x00, /* ED */ 0x00, /* EE */ 0x00, /* EF */ 0x00,
    /* F0 */ 0xF0, /* F1 */ 0x00, /* F2 */ 0x00, /* F3 */ 0x00,
    /* F4 */ 0x00, /* F5 */ 0x00, /* F6 */ 0x00, /* F7 */ 0x00,
    /* F8 */ 0x00, /* F9 */ 0x00, /* FA */ 0x00, /* FB */ 0x00,
    /* FC */ 0x00, /* FD */ 0x00, /* FE */ 0x00, /* FF */ 0x00
};

/* key lookup map */
static const char cmap[][3] = {
    /*00*/{  0 ,  0 , NON},/*01*/{ 27 , 27 , KEY},/*02*/{ '1', '!', KEY},
    /*03*/{ '2', '@', KEY},/*04*/{ '3', '#', KEY},/*05*/{ '4', '$', KEY},
    /*06*/{ '5', '%', KEY},/*07*/{ '6', '^', KEY},/*08*/{ '7', '&', KEY},
    /*09*/{ '8', '*', KEY},/*0A*/{ '9', '(', KEY},/*0B*/{ '0', ')', KEY},
    /*0C*/{ '-', '_', KEY},/*0D*/{ '=', '+', KEY},/*0E*/{  8 ,  8 , KEY},
    /*0F*/{  9 ,  9 , KEY},/*10*/{ 'q', 'Q', KEY},/*11*/{ 'w', 'W', KEY},
    /*12*/{ 'e', 'E', KEY},/*13*/{ 'r', 'R', KEY},/*14*/{ 't', 'T', KEY},
    /*15*/{ 'y', 'Y', KEY},/*16*/{ 'u', 'U', KEY},/*17*/{ 'i', 'I', KEY},
    /*18*/{ 'o', 'O', KEY},/*19*/{ 'p', 'P', KEY},/*1A*/{ '[', '{', KEY},
    /*1B*/{ ']', '}', KEY},/*1C*/{'\n','\n', KEY},/*1D*/{  0 ,  0 , CTR},
    /*1E*/{ 'a', 'A', KEY},/*1F*/{ 's', 'S', KEY},/*20*/{ 'd', 'D', KEY},
    /*21*/{ 'f', 'F', KEY},/*22*/{ 'g', 'G', KEY},/*23*/{ 'h', 'H', KEY},
    /*24*/{ 'j', 'J', KEY},/*25*/{ 'k', 'K', KEY},/*26*/{ 'l', 'L', KEY},
    /*27*/{ ';', ':', KEY},/*28*/{ 39 , '"', KEY},/*29*/{ '`', '~', KEY},
    /*2A*/{  0 ,  0 , LSH},/*2B*/{ 92 , '|', KEY},/*2C*/{ 'z', 'Z', KEY},
    /*2D*/{ 'x', 'X', KEY},/*2E*/{ 'c', 'C', KEY},/*2F*/{ 'v', 'V', KEY},
    /*30*/{ 'b', 'B', KEY},/*31*/{ 'n', 'N', KEY},/*32*/{ 'm', 'M', KEY},
    /*33*/{ ',', '<', KEY},/*34*/{ '.', '>', KEY},/*35*/{ '/', '?', KEY},
    /*36*/{  0 ,  0 , RSH},/*37*/{ '*', '*', KEY},/*38*/{  0 ,  0 , ALT},
    /*39*/{ ' ', ' ', KEY},/*3A*/{  0 ,  0 , CPS},/*3B*/{  0 ,  0 , FUN},
    /*3C*/{  0 ,  0 , FUN},/*3D*/{  0 ,  0 , FUN},/*3E*/{  0 ,  0 , FUN},
    /*3F*/{  0 ,  0 , FUN},/*40*/{  0 ,  0 , FUN},/*41*/{  0 ,  0 , FUN},
    /*42*/{  0 ,  0 , FUN},/*43*/{  0 ,  0 , FUN},/*44*/{  0 ,  0 , FUN},
    /*45*/{  0 ,  0 , NUM},/*46*/{  0 ,  0 , SCR},/*47*/{ 18 , '7', NPD},
    /*48*/{ 23 , '8', NPD},/*49*/{ 20 , '9', NPD},/*4A*/{ '-', '-', KEY},
    /*4B*/{ 26 , '4', NPD},/*4C*/{ 22 , '5', NPD},/*4D*/{ 25 , '6', NPD},
    /*4E*/{ '+', '+', KEY},/*4F*/{ 19 , '1', NPD},/*50*/{ 24 , '2', NPD},
    /*51*/{ 21 , '3', NPD},/*52*/{ 16 , '0', NPD},/*53*/{ 17 , '.', NPD},
    /*54*/{  0 ,  0 , NON},/*55*/{  0 ,  0 , NON},/*56*/{ '<', '>', KEY},
    /*57*/{  0 ,  0 , FUN},/*58*/{  0 ,  0 , FUN},/*59*/{  0 ,  0 , FUN},
    /*5A*/{  0 ,  0 , FUN},/*5B*/{0x0E,0x0E, NON},/*5C*/{0x0E,0x0E, NON},
    /*5D*/{0x0F,0x0F, NON},/*5E*/{  0 ,  0 , NON},/*5F*/{  0 ,  0 , NON},
    /*60*/{  0 ,  0 , NON},/*61*/{  0 ,  0 , NON},/*62*/{  0 ,  0 , NON},
    /*63*/{  0 ,  0 , NON},/*64*/{  0 ,  0 , NON},/*65*/{  0 ,  0 , NON},
    /*66*/{  0 ,  0 , NON},/*67*/{  0 ,  0 , NON},/*68*/{  0 ,  0 , NON},
    /*69*/{  0 ,  0 , NON},/*6A*/{  0 ,  0 , NON},/*6B*/{  0 ,  0 , NON},
    /*6C*/{  0 ,  0 , NON},/*6D*/{  0 ,  0 , NON},/*6E*/{  0 ,  0 , NON},
    /*6F*/{  0 ,  0 , NON},/*70*/{  0 ,  0 , NON},/*71*/{  0 ,  0 , NON},
    /*72*/{  0 ,  0 , NON},/*73*/{  0 ,  0 , NON},/*74*/{  0 ,  0 , NON},
    /*75*/{  0 ,  0 , NON},/*76*/{  0 ,  0 , NON},/*77*/{  0 ,  0 , NON},
    /*78*/{  0 ,  0 , NON},/*79*/{  0 ,  0 , NON},/*7A*/{  0 ,  0 , NON},
    /*7B*/{  0 ,  0 , NON},/*7C*/{  0 ,  0 , NON},/*7D*/{  0 ,  0 , NON},
    /*7E*/{  0 ,  0 , NON},/*7F*/{  0 ,  0 , NON}
};

/*****************************************************************************/
/*                            KEY HANDLING                                   */
/*****************************************************************************/

static unsigned char key(info_t *info, unsigned char scancode){
    /* a character key is pressed.. */
    char chr;

    /* if released, ignore */
    if (scancode & 0x80) return 0;

    /* See if the latin keys are capitalized or not:
     * Shift = 0 && Caps = 0 ; Small
     * Shift = 1 && Caps = 0 ; Capital
     * Shift = 0 && Caps = 1 ; Capital
     * Shift = 1 && Caps = 1 ; Small
     */
    if (((scancode > 0x0F) && (scancode < 0x1A)) ||
        ((scancode > 0x1D) && (scancode < 0x27)) ||
        ((scancode > 0x2B) && (scancode < 0x33)))
            chr = cmap[scancode][(info->caps_lock != info->shift)];
    else
            chr = cmap[scancode][info->shift];

    /* return the ascii character */
    return chr;
}

static unsigned char npd(info_t *info, unsigned char scancode){
    /* num pad key... */
    char chr;

    /* if released, ignore... */
    if (scancode & 0x80) return 0;

    /* See if the keys of the num pad are numbers or
     * arrows & gray Controls
     * Num_Lock = 0 && Shift = 0; arrows
     * Num_Lock = 1 && Shift = 0; numbers
     * Num_Lock = 0 && Shift = 1; numbers
     * Num_Lock = 1 && Shift = 1; arrows
     */
    chr = cmap[scancode][info->num_lock != info->shift];

    /* return the ascii character */
    return chr;
}

static unsigned char ctr(info_t *info, unsigned char scancode){
    if (scancode & 0x80)
        info->control = 0;
    else
        info->control = 1;
    return 0;
}

static unsigned char alt(info_t *info, unsigned char scancode){
    if (scancode & 0x80)
        info->altkey = 1;
    else
        info->altkey = 0;
    return 0;
}

static unsigned char lsh(info_t *info, unsigned char scancode){
    if (scancode & 0x80)
        info->shift = 0;
    else
        info->shift = 1;
    return 0;
}

static unsigned char rsh(info_t *info, unsigned char scancode){
    if (scancode & 0x80)
        info->shift = 0;
    else
        info->shift = 1;
    return 0;
}

static unsigned char num(info_t *info) {
    /* do nothing */
    return 0;
}

static unsigned char cps(info_t *info) {
    /* do nothing */
    return 0;
}

static unsigned char scr(info_t *info) {
    /* do nothing */
    return 0;
}

static unsigned char fun(info_t *info) {
    /* do nothing */
    return 0;
}

static unsigned char esc(info_t *info, unsigned char scancode){
    /* escape buttons */
    unsigned char code = scancode & 0x7F;
    info->escaped = 0;

    if (code == 0x1D)
            return ctr(info, scancode); /* right control */
    if (code == 0x2A)
            return lsh(info, scancode); /* fake shift left */
    if (code == 0x36)
            return rsh(info, scancode); /* fake shift right */
    if (code == 0x38)
            return alt(info, scancode); /* right alt */

    /* FIXME: this needs to be revised */
    if (code > 0x46 && code < 0x54)
        return npd(info, scancode); /* Grey Controls,Arrows */

    if (code == 0x1C || code == 0x35 || (code > 0x5A && code < 0x5E))
        return key(info, scancode); /* Enter, /, Windows, Menu. */

    if ((scancode & 0x80) == 1) return 0;

    /* if (scancode == 0x37); */ /* print screen */
    /* if (scancode == 0x46); */ /* control - break */

    if (code == 0x5E) {
        /* kbd_reboot(); */
    }

    if (scancode == 0x5F) {
        /* sleep */
    }

    if (scancode == 0x63); {
        /* wake up */
    }

    return 0;
}

void scproc(info_t *info, unsigned char scancode) {
    /* process the scancode. */
    unsigned char t = trans[scancode];
    unsigned char ascii;

    /* escape prefix? */
    if (t == 0xE0 || t == 0xE1) {
        info->escaped = 1;
        return;
    }

    /* break prefix? */
    if (t == 0xF0) {
        info->breaked = 1;
        return;
    }

    /* check if already breaked */
    t = (info->breaked<<7) | t;
    info->breaked = 0;

    /* handle the key */
    if (info->escaped == 1) {
        /* escaped buttons are special */
        ascii = esc(info, t);
    } else {
        /* call the appropriate key handler */
        switch (cmap[t & 0x7F][2]) {
            case KEY:
                ascii = key(info, t);
                break;
            case NPD:
                ascii = npd(info, t);
                break;
            case CTR:
                ascii = ctr(info, t);
                break;
            case ALT:
                ascii = alt(info, t);
                break;
            case LSH:
                ascii = lsh(info, t);
                break;
            case RSH:
                ascii = rsh(info, t);
                break;
            case NUM:
                ascii = num(info);
                break;
            case CPS:
                ascii = cps(info);
                break;
            case SCR:
                ascii = scr(info);
                break;
            case FUN:
                ascii = fun(info);
                break;
            default:
                break;
        }
    }

    /* add to buffer */
    if (ascii) {
        if (system_console != (void *) 0)
            dev_ioctl((device_t *) system_console, TTY_PRESS, &ascii);
    }

}

/* ================================================================= */
/*                             Interface                             */
/* ================================================================= */

uint32_t gpkbd_probe(device_t *dev, void *config) {

    irq_reserve_t *reserve;

    /* allocate info_t */
    info_t *info = (info_t *) kmalloc(sizeof(info_t));
    dev->drvreg = (uint32_t) info;
    if (info == NULL)
        return ENOMEM;

    /* initialize info structure */
    info->kbdreg = (uint32_t *) dev->resources.list[0].data.mem.base;
    info->escaped = 0;
    info->breaked = 0;
    info->num_lock = 0;
    info->caps_lock = 0;
    info->scroll_lock = 0;
    info->control = 0;
    info->altkey = 0;
    info->shift = 0;
    info->dev = dev;

    /* print some info */
    printk("Keyboard driver is initializing...\n");

    /* catch the IRQs: */
    reserve = kmalloc(sizeof(irq_reserve_t));
    reserve->dev     = dev;
    reserve->expires = 0;
    reserve->data    = NULL;
    irq_reserve(dev->resources.list[1].data.irq.number, reserve);

    /* flush buffer */
    while (*info->kbdreg);

    /* add to devfs */
    devfs_reg("keyboard", dev->devid);

    /* done */
    return ESUCCESS;
}

uint32_t gpkbd_read(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t gpkbd_write(device_t *dev, uint64_t off, uint32_t size, char *buff) {
    return ESUCCESS;
}

uint32_t gpkbd_ioctl(device_t *dev, uint32_t cmd, void *data) {
    return ESUCCESS;
}

uint32_t gpkbd_irq(device_t *dev, uint32_t irqn) {

    uint32_t data;

    /* get info_t: */
    info_t *info = (info_t *) dev->drvreg;
    if (info == NULL)
            return ENOMEM;

    /* Read & handle the scan code immediately: */
    while (data = *info->kbdreg)
        scproc(info, data);

    return ESUCCESS;
}
