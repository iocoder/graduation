CC=mipsel-linux-gnu-gcc
AS=mipsel-linux-gnu-as
LD=mipsel-linux-gnu-ld
OD=mipsel-linux-gnu-objdump
OC=mipsel-linux-gnu-objcopy
CFLAGS=-mno-abicalls -fno-builtin -nostartfiles -nostdlib -nodefaultlibs
CFLAGS+=-mno-check-zero-division -mips1 -I$(abs_srcdir)
AFLAGS=
LSCRIPT=$(abs_srcdir)/$(OBJECT).ld
LFLAGS=-Wl,-T$(LSCRIPT)
OBJECT=firmware
CFILES=$(shell find $(abs_srcdir)   -name "*.c"   -printf "%f\n" 2>/dev/null)
HFILES=$(shell find $(abs_srcdir)   -name "*.h"   -printf "%f\n" 2>/dev/null)
SFILES=$(shell find $(abs_srcdir)   -name "*.s"   -printf "%f\n" 2>/dev/null)
IFILES=$(shell find $(abs_builddir) -name "*.si"  -printf "%f\n" 2>/dev/null)
OFILES=$(shell find $(abs_builddir) -name "*.o"   -printf "%f\n" 2>/dev/null)
BFILES=$(shell find $(abs_builddir) -name "*.bin" -printf "%f\n" 2>/dev/null)
COBJ  =$(shell echo $(CFILES) | sed 's/\.c/\.o/g')
SOBJ  =$(shell echo $(SFILES) | sed 's/\.s/\.o/g')

all: $(OBJECT).bin

%.o:%.s Makefile
	$(CC) $(CFLAGS) $(AFLAGS) -c -o $@ $<

%.o:%.c $(HFILES) Makefile
	$(CC) $(CFLAGS) -S -o $(shell basename $< | sed 's/\.c/\.si/g') $<
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJECT).bin: $(COBJ) $(SOBJ) $(LSCRIPT) Makefile
	$(CC) $(CFLAGS) $(LFLAGS) -o $(OBJECT).elf $(COBJ) $(SOBJ)
	$(OC) -O binary $(OBJECT).elf $@
	dd oflag=append conv=notrunc if=/dev/zero of=$@ bs=1 \
		count=$$((32768-`stat -c%s $@`))

dump:
	$(OD) -D -m mips $(OBJECT).elf

clean-local:
	rm -rf $(OFILES) $(IFILES) $(BFILES) $(OBJECT).bin $(OBJECT).elf
