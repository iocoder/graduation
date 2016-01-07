#ifndef VM_PIC_H
#define VM_PIC_H

void pic_write(unsigned int data);
unsigned int pic_read();
void pic_irq(int irqno);
void pic_iak();
void pic_init();

#endif
