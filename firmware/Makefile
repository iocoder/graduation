CC=mipsel-linux-gnu-gcc
AS=mipsel-linux-gnu-as
LD=mipsel-linux-gnu-ld
OD=mipsel-linux-gnu-objdump
OC=mipsel-linux-gnu-objcopy
CFLAGS=-mno-abicalls -fno-builtin -nostartfiles -nostdlib -nodefaultlibs
CFLAGS+=-mno-check-zero-division -mips1
AFLAGS=
LFLAGS=-Wl,-T$(OBJECT).ld
OBJECT=firmware
CFILES=$(shell find ./       -name "*.c"   2>/dev/null)
HFILES=$(shell find ./       -name "*.h"   2>/dev/null)
SFILES=$(shell find ./       -name "*.s"   2>/dev/null)
IFILES=$(shell find ./       -name "*.si"  2>/dev/null)
OFILES=$(shell find ./       -name "*.o"   2>/dev/null)
BFILES=$(shell find ./       -name "*.bin" 2>/dev/null)
COBJ  =$(shell echo $(CFILES) | sed 's/\.c/\.o/g')
SOBJ  =$(shell echo $(SFILES) | sed 's/\.s/\.o/g')

all: $(OBJECT).bin

%.o:%.s Makefile
	$(CC) $(CFLAGS) $(AFLAGS) -c -o $@ $<

%.o:%.c $(HFILES) Makefile
	$(CC) $(CFLAGS) -S -o $(shell echo $< | sed 's/\.c/\.si/g') $<
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJECT).bin: $(COBJ) $(SOBJ) Makefile
	$(CC) $(CFLAGS) $(LFLAGS) -o $(OBJECT).elf $(COBJ) $(SOBJ)
	$(OC) -O binary $(OBJECT).elf $@

dump:
	$(OD) -D -m mips $(OBJECT).bin

clean:
	rm -rf $(OFILES) $(IFILES) $(BFILES) $(OBJECT).bin $(OBJECT).elf
