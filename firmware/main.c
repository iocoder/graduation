#include "vga.h"
#include "kbd.h"
#include "pit.h"
#include "pic.h"
#include "isr.h"

int main() {

    /* initialize PIC */
    pic_init();

    /* initialize ISR */
    isr_init();

    /* initialize PIT */
    pit_init();

    /* initialize VGA... */
    vga_init();

    /* initialize keyboard */
    kbd_init();

    /* draw faculty logo */
    draw_logo();

    /* print computer card */
    card();

    /* perform PoST */
    post();

    /* boot the machine */
    boot();

    /* return 0 */
    return 0;

}
