#ifndef _MIPSCOMP_ISR_H
#define _MIPSCOMP_ISR_H

extern void (*isr[8])();

void handle_interrupt();
void set_isr_loc(void *loc);
void isr_init();

#endif
