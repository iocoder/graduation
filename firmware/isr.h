#ifndef _MIPSCOMP_ISR_H
#define _MIPSCOMP_ISR_H

extern void (*isr[8])();

void handle_interrupt();
void isr_init();

#endif
