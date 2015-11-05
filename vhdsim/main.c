#include <SDL/SDL.h>
#include "vhpi_user.h"

#if 0
#define DEBUG
#endif

static vhpiHandleT handle_clk;
static vhpiHandleT handle_r0;
static vhpiHandleT handle_r1;
static vhpiHandleT handle_r2;
static vhpiHandleT handle_g0;
static vhpiHandleT handle_g1;
static vhpiHandleT handle_g2;
static vhpiHandleT handle_b0;
static vhpiHandleT handle_b1;
static vhpiHandleT handle_hs;
static vhpiHandleT handle_vs;
static vhpiHandleT handle_addr[24];
static vhpiHandleT handle_datain[16];
static vhpiHandleT handle_dataout[16];
static vhpiHandleT handle_oe;
static vhpiHandleT handle_we;
static vhpiHandleT handle_mt_adv;
static vhpiHandleT handle_mt_clk;
static vhpiHandleT handle_mt_ub;
static vhpiHandleT handle_mt_lb;
static vhpiHandleT handle_mt_ce;
static vhpiHandleT handle_mt_cre;
static vhpiHandleT handle_mt_wait;
static vhpiHandleT handle_st_sts;
static vhpiHandleT handle_rp;
static vhpiHandleT handle_st_ce;

static void __trigger(const vhpiCbDataT *cb_data);
static int  getsigvalLogic(vhpiHandleT handle);
static void setsigvalLogic(vhpiHandleT handle, int val);

static int clk = 0;

static int last_hs = 0;
static int line_counter = -1;
static int pixel_counter = 0;

static SDL_Surface* screen = NULL;

static unsigned short ram[1<<23];
static unsigned short rom[1<<23];

static unsigned char get_r() {
    return ((unsigned char[]){0x00,0x24,0x48,0x6C,0x90,0xB4,0xD8,0xFF})[
                (getsigvalLogic(handle_r2)<<2)|
                (getsigvalLogic(handle_r1)<<1)|
                (getsigvalLogic(handle_r0)<<0)];
}

static unsigned char get_g() {
    return ((unsigned char[]){0x00,0x24,0x48,0x6C,0x90,0xB4,0xD8,0xFF})[
                (getsigvalLogic(handle_g2)<<2)|
                (getsigvalLogic(handle_g1)<<1)|
                (getsigvalLogic(handle_g0)<<0)];
}

static unsigned char get_b() {
    return ((unsigned char[]){0x00,0x55,0xAA,0xFF})[
                (getsigvalLogic(handle_b1)<<1)|
                (getsigvalLogic(handle_b0)<<0)];
}

static unsigned int get_rgb() {
    return (get_r()<<16)|(get_g()<<8)|get_b();
}

static unsigned int get_hs() {
    return getsigvalLogic(handle_hs);
}

static unsigned int get_vs() {
    return getsigvalLogic(handle_vs);
}

static void set_fpx(int x, int y, Uint32 color) {
    Uint32 *pixels = (Uint32 *) screen->pixels;
    pixels[(y*screen->w)+x] = color;
}

static int vga_update() {
     while(1)
        SDL_Flip(screen);
//     thread_closed = 1;
    return 1;
}

static void vga_clk() {
    int cur_hs = get_hs();
    int cur_pixel = pixel_counter;
    if (cur_hs && !last_hs) {
        /* new line */
        line_counter++;
        if (line_counter == 449)
            line_counter = 0;
        pixel_counter = 0;
        /*vhpi_printf("line: %d", line_counter);*/
    }
    if (line_counter >= 35 && line_counter < 435) {
        if (cur_pixel >= 51 && cur_pixel < 771) {
            set_fpx(cur_pixel-51, line_counter-35, get_rgb());
        }
    }
    pixel_counter++;
    last_hs = cur_hs;
}

static unsigned int get_addr() {
    unsigned int addr = 0;
    int i;
    for (i = 0; i < 23; i++) {
        addr |= getsigvalLogic(handle_addr[i])<<i;
    }
    return addr;
}

static unsigned int get_dataout() {
    unsigned int data = 0;
    int i;
    for (i = 0; i < 16; i++) {
        data |= getsigvalLogic(handle_dataout[i])<<i;
    }
    return data;
}

static void set_datain(unsigned int data) {
    int i;
    for (i = 0; i < 16; i++) {
        setsigvalLogic(handle_datain[i], (data>>i)&1);
    }
}

static void tri_datain() {
    int i;
    for (i = 0; i < 16; i++) {
        setsigvalLogic(handle_datain[i], 2);
    }
}

static int get_oe() {
    return getsigvalLogic(handle_oe);
}

static int get_we() {
    return getsigvalLogic(handle_we);
}

static int get_mt_lb() {
    return getsigvalLogic(handle_mt_lb);
}

static int get_mt_ub() {
    return getsigvalLogic(handle_mt_ub);
}

static int get_mt_ce() {
    return getsigvalLogic(handle_mt_ce);
}

static int get_st_ce() {
    return getsigvalLogic(handle_st_ce);
}

static void mem_clk() {
    unsigned int data;
    unsigned char *word;
    vhpiTimeT now;
    long cycles;
    vhpi_get_time(&now, &cycles);
    if (get_st_ce()==0 && get_oe()==0) {
        /* ROM READ */
        data = rom[(get_addr()&0xFFFFFF)>>1];
#ifdef DEBUG
        vhpi_printf("at %dns: ROM RD ADDR: 0x%08X, DATA: 0x%08X",
                    now.high*4295+now.low/1000000, get_addr(), data);
#endif
        set_datain(data);
    } else if (get_mt_ce()==0 && get_oe()==0) {
        /* RAM READ */
        data = ram[(get_addr()&0xFFFFFF)>>1];
#ifdef DEBUG
        vhpi_printf("at %dns: RAM RD ADDR: 0x%08X, DATA: 0x%08X",
                    now.high*4295+now.low/1000000, get_addr(), data);
#endif
        set_datain(data);
    } else if (get_mt_ce()==0 && get_we()==0) {
        /* RAM WRITE */
        word = (unsigned char *) &ram[(get_addr()&0xFFFFFF)>>1];
        if (get_mt_lb()==0) {
            word[0] = get_dataout()&0xFF;
        }
        if (get_mt_ub()==0) {
            word[1] = get_dataout()>>8;
        }
#ifdef DEBUG
        vhpi_printf("at %dns: RAM WR ADDR: 0x%08X, DATA: 0x%08X",
                    now.high*4295+now.low/1000000, get_addr(), word);
#endif
    } else {
        tri_datain();
    }
}

static void trigger() {
    mem_clk();
    vga_clk();
}

static void reg_trigger() {
    vhpiTimeT time_40ns = {
    .   low = 40000000
    };
    vhpiCbDataT cb_data2 = {
        .reason = vhpiCbAfterDelay,
        .cb_rtn = __trigger,
        .time   = &time_40ns
    };
    vhpi_register_cb(&cb_data2, 0);
}

static void __trigger(const vhpiCbDataT *cb_data) {
    trigger();
    /* call __trigger back after 10ns */
    reg_trigger();
}

static int getsigvalLogic(vhpiHandleT handle) {
    vhpiValueT valstr = {
       .format = vhpiLogicVal
    };
    vhpi_get_value(handle, &valstr);
    return valstr.value.intg-vhpi0;
}

static void setsigvalLogic(vhpiHandleT handle, int val) {
    vhpiValueT valstr = {
       .format = vhpiLogicVal
    };
    valstr.value.intg = val+vhpi0;
    vhpi_put_value(handle, &valstr, vhpiForcePropagate);
}

static void start_of_sim(const vhpiCbDataT *cb_data) {
    vhpi_printf("Simulation started!\n");
    /* call trigger */
    __trigger(cb_data);
}

static void startup() {
    int i;
    char signame[100];
    FILE *romf;
    /* set start_of_sim listener */
    vhpiCbDataT cb_data1 = {
        .reason    = vhpiCbStartOfSimulation,
        .cb_rtn    = start_of_sim,
        .user_data = (char *)"some user data",
    };
    vhpi_register_cb(&cb_data1, vhpiReturnCb);
    /* print splash */
    vhpi_printf("***************************************");
    vhpi_printf("*  MIPS FPGA COMPUTER VHDL SIMULATOR  *");
    vhpi_printf("***************************************");
    vhpi_printf("");
    /* initialize SDL */
    SDL_Init(SDL_INIT_EVERYTHING);
    /* Set up screen */
    screen = SDL_SetVideoMode(720, 400, 32, SDL_SWSURFACE);
    /* Set title */
    SDL_WM_SetCaption("MIPS FPGA Computer VHDL Simulator", NULL);
    /* instantiate a thread for updating the screen */
    SDL_CreateThread(&vga_update, NULL);
    /* initialize rom */
    romf = fopen("../firmware/firmware.bin", "r");
    fread(rom, sizeof(rom), 1, romf);
    fclose(romf);
    /* get root entity */
    vhpiHandleT root = vhpi_handle(vhpiRootInst, NULL);
    /* get handlers */
    handle_clk = vhpi_handle_by_name("clk", root);
    handle_r0  = vhpi_handle_by_name("r0",  root);
    handle_r1  = vhpi_handle_by_name("r1",  root);
    handle_r2  = vhpi_handle_by_name("r2",  root);
    handle_g0  = vhpi_handle_by_name("g0",  root);
    handle_g1  = vhpi_handle_by_name("g1",  root);
    handle_g2  = vhpi_handle_by_name("g2",  root);
    handle_b0  = vhpi_handle_by_name("b0",  root);
    handle_b1  = vhpi_handle_by_name("b1",  root);
    handle_vs  = vhpi_handle_by_name("vs",  root);
    handle_hs  = vhpi_handle_by_name("hs",  root);
    for (i = 0; i < 24; i++) {
        sprintf(signame, "addr%d", i);
        handle_addr[i] = vhpi_handle_by_name(signame, root);
    }
    for (i = 0; i < 16; i++) {
        sprintf(signame, "datain%d", i);
        handle_datain[i] = vhpi_handle_by_name(signame, root);
    }
    for (i = 0; i < 16; i++) {
        sprintf(signame, "dataout%d", i);
        handle_dataout[i] = vhpi_handle_by_name(signame, root);
    }
    handle_oe      = vhpi_handle_by_name("oe",      root);
    handle_we      = vhpi_handle_by_name("we",      root);
    handle_mt_adv  = vhpi_handle_by_name("mt_adv",  root);
    handle_mt_clk  = vhpi_handle_by_name("mt_clk",  root);
    handle_mt_ub   = vhpi_handle_by_name("mt_ub",   root);
    handle_mt_lb   = vhpi_handle_by_name("mt_lb",   root);
    handle_mt_ce   = vhpi_handle_by_name("mt_ce",   root);
    handle_mt_cre  = vhpi_handle_by_name("mt_cre",  root);
    handle_mt_wait = vhpi_handle_by_name("mt_wait", root);
    handle_st_sts  = vhpi_handle_by_name("st_sts",  root);
    handle_rp      = vhpi_handle_by_name("rp",      root);
    handle_st_ce   = vhpi_handle_by_name("st_ce",   root);

}

void (*vhpi_startup_routines[])() = {
   startup,
   NULL
};
