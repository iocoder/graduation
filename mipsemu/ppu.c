#include <SDL2/SDL.h>

#include "mem.h"
#include "ppu.h"
#include "pic.h"

static SDL_Window* window = NULL;
static SDL_Renderer* renderer;
static SDL_Texture* texture;
static Uint32 pixels[256*3*240*3];

/****************************************************************************/
/*                      PPU Internal Memory Cells                           */
/****************************************************************************/

unsigned char sprites[256];
static unsigned char palette[32];
extern unsigned char rgb_palette[64][3];
unsigned char namtab1[0x400];
unsigned char namtab2[0x400];
unsigned char vram[8*1024];
unsigned char vrom[8*1024];

/****************************************************************************/
/*                        PPU Internal Registers                            */
/****************************************************************************/

/* sprite settings */
unsigned char SP = 0; /* sprite pattab select */
unsigned char SS = 0; /* sprite size */

/* screen pattern table address */
unsigned char S = 0; /* screen pattab select */

/* address increment type */
unsigned char VW = 0; /* 0: horizontal write, 1: vertical write */

/* generate NMIs on VBlank? */
unsigned char VBE = 0; /* vblank enable */

/* status bits */
unsigned char VBlank = 0; /* reached vblank? */

/* sprite 0 hit flag */
unsigned char HIT = 0; /* 1: sprite refresh has hit sprite #0 */

/* name table select / VRAM access (all are counters) */
unsigned short V  = 0; /* vertical name table selection   | 1 bit  */
unsigned short H  = 0; /* horizontal name table selection | 1 bit  */
unsigned short VT = 0; /* vertical tile index             | 5 bits */
unsigned short HT = 0; /* horizontal tile index           | 5 bits */
unsigned short FV = 0; /* fine vertical scroll            | 3 bits */
unsigned short FH = 0; /* fine horizontal scroll          | 3 bits */

/* 1-st/2-nd write flip flop */
unsigned char FF = 0;

/* Sprite Memory Access */
unsigned char SMA = 0; /* Sprite memory address */

/* temporary registers (used during rendering) */
unsigned char PAR = 0; /* current pattern number         | 8 bits */
unsigned char AR  = 0; /* current attribute value        | 2 bits */
unsigned char CC  = 0; /* current pixel color            | 2 bits */

/* debugging */
char hflg = 0;
int mapper = 2;

unsigned char get_bit(unsigned short latch, unsigned short bit) {
    return (latch & (1<<bit)) ? 1 : 0;
}

void set_bit(unsigned short *latch, unsigned short bit, unsigned char val) {
     *latch = (*latch & (~(1<<bit))) | (val<<bit);
}

unsigned char cart_ppu_read(unsigned short addr) {

    unsigned char ret = 0;

    if (mapper == 0) {
        if (addr < 0x2000) {
            ret = vrom[addr];
        }
    } else if (mapper == 2) {
        if (addr < 0x2000) {
            ret = vram[addr];
        }
    }

    return ret;

}

void cart_ppu_write(unsigned short addr, unsigned char data) {

    if (mapper == 0) {
        if (addr < 0x2000) {
            /*vrom[addr] = data;*/
        }
    } else if (mapper == 2) {
        if (addr < 0x2000) {
            vram[addr] = data;
        }
    }

}

unsigned char ppu_mem_read(unsigned short addr) {

    unsigned char ret = 0;
    addr &= 0x3FFF;
    if (addr < 0x2000) {
        /* do nothing */
    } else if (addr & 0x0400) {
        /* nametable 2 */
        ret = namtab2[addr&0x3FF];
    } else {
        /* nametable 1 */
        ret = namtab1[addr&0x3FF];
        /*if (hflg)
            printf("name table read! %04X:%02X\n", addr, ret);*/
    }
    return ret | cart_ppu_read(addr);

}

void ppu_mem_write(unsigned short addr, unsigned char data) {
    addr &= 0x3FFF;

    if (addr < 0x2000) {
        /* do nothing */
    } else if (addr & 0x0400) {
        /* nametable 2 */
        namtab2[addr&0x3FF] = data;
    } else {
        /* nametable 1 */
        namtab1[addr&0x3FF] = data;
        /*fprintf(stderr, " <ppu write %04X:%02X>\n", addr, data);*/
        hflg = 1;
    }

    cart_ppu_write(addr, data);
}

unsigned char p2007access(char dir, unsigned char data) {
    unsigned short addr = 0;
    unsigned char ret = 0;
    set_bit(&addr,  0, get_bit(HT, 0)); /* tile column */
    set_bit(&addr,  1, get_bit(HT, 1)); /* tile column */
    set_bit(&addr,  2, get_bit(HT, 2)); /* tile column */
    set_bit(&addr,  3, get_bit(HT, 3)); /* tile column */
    set_bit(&addr,  4, get_bit(HT, 4)); /* tile column */
    set_bit(&addr,  5, get_bit(VT, 0)); /* tile row */
    set_bit(&addr,  6, get_bit(VT, 1)); /* tile row */
    set_bit(&addr,  7, get_bit(VT, 2)); /* tile row */
    set_bit(&addr,  8, get_bit(VT, 3)); /* tile row */
    set_bit(&addr,  9, get_bit(VT, 4)); /* tile row */
    set_bit(&addr, 10, get_bit(H,  0)); /* which nametable (H)? */
    set_bit(&addr, 11, get_bit(V,  0)); /* which nametable (V)? */
    set_bit(&addr, 12, get_bit(FV, 0)); /* fineY is used as addr */
    set_bit(&addr, 13, get_bit(FV, 1)); /* fineY is used as addr */
    if (dir == 0) {
        /* read */
        if (addr >= 0x3F00) {
            if ((addr & 0x0F) == 0) {
                ret = palette[0];
            } else {
                ret = palette[addr & 0x1F];
            }
        } else {
            ret = ppu_mem_read(addr);
        }
    } else {
        /* write */
        if (addr >= 0x3F00) {
            if ((addr & 0x0F) == 0) {
                palette[0] = data;
            } else {
                palette[addr & 0x1F] = data;
            }
        } else {
            ppu_mem_write(addr, data);
        }
    }
    if (VW == 0) {
        /* increment by 1 */
        HT++;
        if (HT == 32) {
            HT = 0;
            VT++;
            if (VT == 32) {
                VT = 0;
                H++;
                if (H == 2) {
                    H = 0;
                    V++;
                    if (V == 2) {
                        V = 0;
                        FV++;
                        if (FV == 8)
                            FV = 0;
                    }
                }
            }
        }
    } else {
        /* increment by 32 */
        VT++;
        if (VT == 32) {
            VT = 0;
            H++;
            if (H == 2) {
                H = 0;
                V++;
                if (V == 2) {
                    V = 0;
                    FV++;
                    if (FV == 8)
                        FV = 0;
                }
            }
        }
    }
    return ret;
}

unsigned char ppu_reg_read(int reg) {
    unsigned char ret;
    if (!window)
        ppu_init();
    switch (reg) {
        case 0:
            fprintf(stderr, "Illegal read!\n");
            return 0;
        case 1:
            fprintf(stderr, "Illegal read!\n");
            return 0;
        case 2:
            ret = (VBlank<<7) | (HIT << 6);
            VBlank = 0;
            FF = 0;
            return ret;
        case 3: /* sprite memory address */
            fprintf(stderr, "Illegal read!\n");
            return 0;
        case 4: /* sprite memory data */
            printf("sprite read: $%04X $%02X\n", SMA, sprites[SMA]);
            return sprites[SMA++];
        case 5: /* screen scroll offsets */
            fprintf(stderr, "Illegal read!\n");
            return 0;
        case 6: /* PPU memory address */
            fprintf(stderr, "Illegal read!\n");
            return 0;
        case 7: /* PPU memory data */
            return p2007access(0 /* read */, 0);
        default:
            return 0;
    }
}

void ppu_reg_write(unsigned short reg, unsigned char data) {
    if (!window)
        ppu_init();
    switch (reg) {
        case 0:
            H   = get_bit(data, 0); /* name table select (horizontal) */
            V   = get_bit(data, 1); /* name table select (vertical) */
            VW  = get_bit(data, 2); /* vertical write */
            SP  = get_bit(data, 3); /* sprite pattab */
            S   = get_bit(data, 4); /* screen pattab */
            SS  = get_bit(data, 5); /* sprite size */
            VBE = get_bit(data, 7); /* vblank enable */
            break;
        case 1:
            /* TODO */
            break;
        case 2:
            /* no effect */
            break;
        case 3: /* sprite memory address */
            SMA = data;
            break;
        case 4: /* sprite memory data */
            //printf("sprite write: $%04X $%02X\n", SMA, data);
            sprites[SMA++] = data;
            break;
        case 5: /* screen scroll offsets */
            if (FF == 0) {
                /* first write:
                 * --horizontal scroll--
                 * data represents the X ordinate of the first
                 * pixel to be rendered. X/8 is the tile column
                 * of the first pixel (inside the name table
                 * specified by H & V latches), X%8 is the
                 * pixel column inside the tile.
                 * copy the lower 3 bits of data into FH
                 * copy the upper 5 bits of data into HT
                 */
                FH = data & 7;
                HT = data>>3;
            } else {
                /* second write:
                 * -- vertical scroll --
                 * data represents the Y ordinate of the first
                 * pixel to be rendered. Y/8 is the tile row
                 * of the first pixel (inside the name table
                 * specified by H & V latches), Y%8 is the
                 * pixel row inside the tile.
                 * copy the lower 3 bits of data into FV
                 * copy the upper 5 bits of data into VT
                 */
                FV = data & 7;
                VT = data>>3;
            }
            FF = !FF;
            break;
        case 6: /* PPU memory address */
            if (FF == 0) {
                /* first write */
                set_bit(&VT, 3, get_bit(data, 0));
                set_bit(&VT, 4, get_bit(data, 1));
                set_bit(&H,  0, get_bit(data, 2));
                set_bit(&V,  0, get_bit(data, 3));
                set_bit(&FV, 0, get_bit(data, 4));
                set_bit(&FV, 1, get_bit(data, 5));
                set_bit(&FV, 2, 0);
            } else {
                /* second write: */
                set_bit(&HT, 0, get_bit(data, 0));
                set_bit(&HT, 1, get_bit(data, 1));
                set_bit(&HT, 2, get_bit(data, 2));
                set_bit(&HT, 3, get_bit(data, 3));
                set_bit(&HT, 4, get_bit(data, 4));
                set_bit(&VT, 0, get_bit(data, 5));
                set_bit(&VT, 1, get_bit(data, 6));
                set_bit(&VT, 2, get_bit(data, 7));
            }
            FF = !FF;
            break;
        case 7: /* PPU memory data */
            p2007access(1 /* write */, data);
            break;
        default:
            break;
    }
}

/****************************************************************************/
/*                              Debugging                                   */
/****************************************************************************/

unsigned char pixbuf[600][300][3];

void draw_pattern(int tab, int i, int x, int y, double colors[][3]) {

    int j, k;
    for (j = 0; j < 8; j++) {
        unsigned char c1 = ppu_mem_read((tab?0x1000:0)+i*16+j);
        unsigned char c2 = ppu_mem_read((tab?0x1000:0)+i*16+8+j);
        for (k = 0; k < 8; k++) {
            int indx = ((c1&(1<<k))?1:0)+((c2&(1<<k))?2:0);
            pixbuf[x+7-k][y+j][0] = colors[indx][0];
            pixbuf[x+7-k][y+j][1] = colors[indx][1];
            pixbuf[x+7-k][y+j][2] = colors[indx][2];
        }
    }

}

void draw_pattabs() {

    /* draw pattern tables */
    int i;
    double colors[][3] = {{0,0,0},{0,0.3,0},{0,0.6,0},{0,1,0}};
    for (i = 0; i < 256; i++) {
        int x = (i%16)*8;
        int y = (i/16)*8;
        draw_pattern(0, i, x,      y, colors);
        draw_pattern(1, i, x+16*8, y, colors);
    }

}

void draw_namtabs() {

    /* draw name tables  */
    int i /*row*/, j /*col*/;
    for (i = 0; i < 30; i++) {
        for (j = 0; j < 32; j++) {
            int x = j*8;
            int y = i*8;
            int pattab = S;
            unsigned char pattern, attrib;
            int attr_bits[4][4] = { /* col0, col1, col2, col3 */
                /* row 0 */          {  0,    0,    2,    2   },
                /* row 1 */          {  0,    0,    2,    2   },
                /* row 2 */          {  4,    4,    6,    6   },
                /* row 3 */          {  4,    4,    6,    6   }
            };
            int which_attr = (i/4)*8+j/4;
            int color_bits, color_base, color_indx;
            double colors[4][3];

            /* namtab1:
             * ---------
             */
            /* read the pattern index */
            pattern = ppu_mem_read(0x2000+i*32+j);

            /* get the attribute */
            attrib = ppu_mem_read(0x23C0+which_attr);

            /* get 2 most signficant bits of the color: */
            color_bits = attr_bits[i%4][j%4];
            color_base = ((attrib>>color_bits)&0x3)*4;

            /* get colors */
            color_indx = palette[0] & 0x3F;
            colors[0][0] = rgb_palette[color_indx][2];
            colors[0][1] = rgb_palette[color_indx][1];
            colors[0][2] = rgb_palette[color_indx][0];
            while (1) {
                color_base++;
                color_indx = palette[color_base] & 0x3F;
                colors[color_base&3][0] = rgb_palette[color_indx][2];
                colors[color_base&3][1] = rgb_palette[color_indx][1];
                colors[color_base&3][2] = rgb_palette[color_indx][0];
                if ((color_base & 3) == 3)
                    break;
            }

            /* draw the pattern */
            draw_pattern(pattab, pattern, x, y, colors);

            /* namtab2:
             * ---------
             */
            /* read the pattern index */
            pattern = ppu_mem_read(0x2400+i*32+j);

            /* get the attribute */
            attrib = ppu_mem_read(0x27C0+which_attr);

            /* get 2 most signficant bits of the color: */
            color_bits = attr_bits[i%4][j%4];
            color_base = ((attrib>>color_bits)&0x3)*4;

            /* get colors */
            color_indx = palette[0] & 0x3F;
            colors[0][0] = rgb_palette[color_indx][2];
            colors[0][1] = rgb_palette[color_indx][1];
            colors[0][2] = rgb_palette[color_indx][0];
            while (1) {
                color_base++;
                color_indx = palette[color_base] & 0x3F;
                colors[color_base&3][0] = rgb_palette[color_indx][2];
                colors[color_base&3][1] = rgb_palette[color_indx][1];
                colors[color_base&3][2] = rgb_palette[color_indx][0];
                if ((color_base & 3) == 3)
                    break;
            }

            /* draw the pattern */
            draw_pattern(pattab, pattern, x+32*8, y, colors);

        }
    }

}

/****************************************************************************/
/*                               Refresh                                    */
/****************************************************************************/

static void set_fpx(int x, int y, Uint32 color) {
    if (x < 256*3 && y < 240*3)
        pixels[(y*256*3)+x] = color;
}

void set_pixel(int x, int y, unsigned char r,
                             unsigned char g,
                             unsigned char b) {
    Uint32 color = (b<<16) | (g<<8) | (r<<0);
    set_fpx(x*3+0, y*3+0, color);
    set_fpx(x*3+0, y*3+1, color);
    set_fpx(x*3+0, y*3+2, color);
    set_fpx(x*3+1, y*3+0, color);
    set_fpx(x*3+1, y*3+1, color);
    set_fpx(x*3+1, y*3+2, color);
    set_fpx(x*3+2, y*3+0, color);
    set_fpx(x*3+2, y*3+1, color);
    set_fpx(x*3+2, y*3+2, color);
}

int done = 1;

void ppu_render() {

    if (!window)
        return;

    /* update the screen */
    SDL_UpdateTexture(texture, NULL, &pixels[0], 1);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);

    /* we are done */
    done = 1;

}

static void refresh() {

    /* draw a new frame to the pixel buffer
     */

    /* take a copy of name table select counters */
    unsigned short cV  = V;  /* vertical name table selection   | 1 bit  */
    unsigned short cH  = H;  /* horizontal name table selection | 1 bit  */
    unsigned short cVT = VT; /* vertical tile index             | 5 bits */
    unsigned short cHT = HT; /* horizontal tile index           | 5 bits */
    unsigned short cFV = FV; /* fine vertical scroll            | 3 bits */
    unsigned short cFH = FH; /* fine horizontal scroll          | 3 bits */

    /* pixel counters */
    int x, y;

    /* attribute shift */
    int ashift;

    /* color index */
    int color_indx;

    /* address used to access memory */
    unsigned short addr;

    /* loop counters */
    int i, j;

    /* reset hit flag */
    HIT = 0;

    /* loop */
    for (y = 0; y < 240; y++) {
        /* new row (new horizon) */
        cFH = FH; /* reset fineX */
        cHT = HT; /* reset horizontal tile */
        cH  = H;  /* reset horizontal name table */
        for (x = 0; x < 256; x++) {
            /* load the appropriate tile */
            addr = 0;
            set_bit(&addr,  0, get_bit(cHT, 0)); /* tile column */
            set_bit(&addr,  1, get_bit(cHT, 1)); /* tile column */
            set_bit(&addr,  2, get_bit(cHT, 2)); /* tile column */
            set_bit(&addr,  3, get_bit(cHT, 3)); /* tile column */
            set_bit(&addr,  4, get_bit(cHT, 4)); /* tile column */
            set_bit(&addr,  5, get_bit(cVT, 0)); /* tile row */
            set_bit(&addr,  6, get_bit(cVT, 1)); /* tile row */
            set_bit(&addr,  7, get_bit(cVT, 2)); /* tile row */
            set_bit(&addr,  8, get_bit(cVT, 3)); /* tile row */
            set_bit(&addr,  9, get_bit(cVT, 4)); /* tile row */
            set_bit(&addr, 10, get_bit(cH,  0)); /* which nametable (H)? */
            set_bit(&addr, 11, get_bit(cV,  0)); /* which nametable (V)? */
            set_bit(&addr, 12, 0);
            set_bit(&addr, 13, 1);
            PAR = ppu_mem_read(addr); /* pattern number */
            /* load the attribute */
            set_bit(&addr,  0, get_bit(cHT, 2)); /* tile column */
            set_bit(&addr,  1, get_bit(cHT, 3)); /* tile column */
            set_bit(&addr,  2, get_bit(cHT, 4)); /* tile column */
            set_bit(&addr,  3, get_bit(cVT, 2)); /* tile row */
            set_bit(&addr,  4, get_bit(cVT, 3)); /* tile row */
            set_bit(&addr,  5, get_bit(cVT, 4)); /* tile row */
            set_bit(&addr,  6, 1);
            set_bit(&addr,  7, 1);
            set_bit(&addr,  8, 1);
            set_bit(&addr,  9, 1);
            set_bit(&addr, 10, get_bit(cH,  0)); /* which nametable (H)? */
            set_bit(&addr, 11, get_bit(cV,  0)); /* which nametable (V)? */
            set_bit(&addr, 12, 0);
            set_bit(&addr, 13, 1);
            ashift = (get_bit(cVT, 1)*4) | (get_bit(cHT, 1)*2);
            AR = (ppu_mem_read(addr)>>ashift)&3; /* attribute */
            /* get bit 0 and 1 of the color */
            CC = ((ppu_mem_read((S?0x1000:0)+PAR*16+cFV)>>(7-cFH))&1) |
                 (((ppu_mem_read((S?0x1000:0)+PAR*16+cFV+8)>>(7-cFH))&1)<<1);
            /* now draw the pixel */
            if (CC == 0)
                color_indx = palette[0] & 0x3F;
            else
                color_indx = palette[AR*4+CC] & 0x3F;
            set_pixel(x, y, rgb_palette[color_indx][2], /* b */
                            rgb_palette[color_indx][1], /* g */
                            rgb_palette[color_indx][0]  /* r */);
            /* update the counters */
            cFH++;
            if (cFH == 8) {
                cFH = 0;
                cHT++;
                if (cHT == 32) {
                    cHT = 0;
                    cH = !cH;
                }
            }
        }
        /* move to next row */
        cFV++;
        if (cFV == 8) {
            cFV = 0;
            cVT++;
            if (cVT == 30) {
                cVT = 0;
                cV = !cV;
            }
        }
    }

    /* draw sprites */
    printf("sprite size: %d\n", SS);
    for (i = 63; i >= 0; i--) {
        AR  = sprites[i*4+2] & 3; /* attribute */
        if (SS == 0) {
            /* 8x8 sprites */
            unsigned short pat = SP ? 0x1000:0;
            PAR = sprites[i*4+1];
            for (y = 0; y < 8; y++) {
                for (x = 0; x < 8; x++) {
                    int act_x, act_y;
                    if (sprites[i*4+2]&0x40) {
                        /* flip horizontally */
                        act_x = sprites[i*4+3]+7-x;
                    } else {
                        act_x = sprites[i*4+3]+x;
                    }
                    if (sprites[i*4+2]&0x80) {
                        /* flip vertically */
                        act_y = sprites[i*4+0]+1+7-y;
                    } else {
                        act_y = sprites[i*4+0]+1+y;
                    }
                    if (act_x >= 256 || act_y > 240)
                        continue;
                    CC=(((ppu_mem_read(pat+PAR*16+0+y)>>(7-x))&1)<<0)|
                        (((ppu_mem_read(pat+PAR*16+8+y)>>(7-x))&1)<<1);
                    if (CC != 0) {
                        int indx = palette[0x10+AR*4+CC] & 0x3F;
                        set_pixel(act_x, act_y, rgb_palette[indx][2],
                                                rgb_palette[indx][1],
                                                rgb_palette[indx][0]);
                    }
                }
            }
        } else {
            /* 8x16 sprites */
            unsigned short pat = (sprites[i*4+1] & 1) ? 0x1000:0;
            PAR = sprites[i*4+1] & 0xFE;
            for (j = 0; j < 2; j++) {
                for (y = 0; y < 8; y++) {
                    for (x = 0; x < 8; x++) {
                        int act_x, act_y;
                        if (sprites[i*4+2]&0x40) {
                            /* flip horizontally */
                            act_x = sprites[i*4+3]+7-x;
                        } else {
                            act_x = sprites[i*4+3]+x;
                        }
                        if (sprites[i*4+2]&0x80) {
                            /* flip vertically */
                            act_y = sprites[i*4+0]+1+15-(y+j*8);
                        } else {
                            act_y = sprites[i*4+0]+1+y+j*8;
                        }
                        if (act_x >= 256 || act_y > 240)
                            continue;
                        CC=(((ppu_mem_read(pat+(PAR+j)*16+0+y)>>(7-x))&1)<<0)|
                           (((ppu_mem_read(pat+(PAR+j)*16+8+y)>>(7-x))&1)<<1);
                        if (CC != 0) {
                            int indx = palette[0x10+AR*4+CC] & 0x3F;
                            set_pixel(act_x, act_y, rgb_palette[indx][2],
                                                    rgb_palette[indx][1],
                                                    rgb_palette[indx][0]);
                        }
                    }
                }
            }
        }
    }
}

/****************************************************************************/
/*                            Clock Handling                                */
/****************************************************************************/

int display_enabled = 1;
int refreshing = 0;
int ppu_counter = 0;

void ppu_clk() {
    if (ppu_counter == 833333) {
        refresh();
        ppu_counter = 0;
    } else {
        ppu_counter++;
    }
    if (ppu_counter < 100000 && !VBlank) {
        VBlank = 1;
        /* trigger an interrupt */
        if (VBE)
            pic_irq(3);
    } else {
        VBlank = 0;
    }
}

/****************************************************************************/
/*                            Initialization                                */
/****************************************************************************/

void ppu_init() {

    SDL_Window* win;
    int i, j;

    /* create vga window */
    window = SDL_CreateWindow("Nintendo PPU",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        256*3, 240*3, 0);

    /* create renderer */
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    /* create texture */
    texture = SDL_CreateTexture(renderer,
        SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        256*3, 240*3);

    /* initialize pallette */
    /*for (i = 0; i < 64; i++) {
        palette[i&0x1F] = (i&0x1F)*2;
    }*/

    /* output 8-bit palette */
    for (i = 0; i < 64; i++) {
        int r, g, b, color;
        r = rgb_palette[i][0];
        g = rgb_palette[i][1];
        b = rgb_palette[i][2];
        r = r*8/256;
        g = g*8/256;
        b = b*4/256;
        color = ((r&7)<<5)|((g&7)<<2)|(b&3);
        printf("\"");
        for (j = 0; j < 8; j++)
            printf("%d", (color>>(7-j))&1);
        printf("\",\n");
    }


}

__asm__("rgb_palette: .incbin \"fceux.pal\";");
