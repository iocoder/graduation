#include "pit.h"

int *counter_reg = (int *) PIT_BASE;

int pit_read() {

    return *counter_reg;

}

void pit_write(int count) {

    *counter_reg = count;

}
