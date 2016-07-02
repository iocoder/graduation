CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c"   2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h"   2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h"   2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a"   2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s"   2>/dev/null)
IFILES         = $(shell find $(CSD)/         -name "*.inc" 2>/dev/null)

OBJECT_NAME    = nes
OBJECT_PREFIX  = $(BOOT_DIR)
LINKER_SCRIPT  = $(CSD)/nes.ld
LFLAGS         = $(QLFLAGS) -Wl,-T$(LINKER_SCRIPT)
LIBS           =
DEPS           = $(ALLHFILES) $(IFILES) Makefile

OBJ = \
$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g') \
$(shell cd $(CSD) && find ./ -name "*.s" 2>/dev/null | sed 's/\.s/\.o/g')

%.o: %.c $(DEPS)
	$(QCC) $(QCFLAGS) -c -o $@ $<

%.o: %.s $(DEPS)
	$(QAS) -I$(CSD) --32 $< -o $@

nes.bin: $(OBJ) $(LINKER_SCRIPT)
	$(QCC) $(QCFLAGS) $(LFLAGS) -o nes.elf $(OBJ) $(LIBS)
	$(QOC) -O binary nes.elf $@

install-exec-local:
	$(INSTALL) -D nes.bin $(OBJECT_PREFIX)/nes.bin
	$(INSTALL) -D $(CSD)/contra.nes $(OBJECT_PREFIX)/../nes/contra.nes

uninstall-local:
	rm -f $(OBJECT_PREFIX)/nes.bin
	- $(call REMOVE_EMPTY_DIR, $(prefix))

all-local: nes.bin

clean-local:
	rm -f nes.bin
	rm -f $(OBJ)
