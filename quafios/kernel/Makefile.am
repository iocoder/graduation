CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

OBJECT_NAME   = kernel
OBJECT_PREFIX = $(BOOT_DIR)
LDSCRIPT      = $(CSD)/ld/arch32.ld
KLFLAGS       = $(QLFLAGS) -Wl,-T$(LDSCRIPT) -Wl,--build-id=none
BLFLAGS       = $(KLFLAGS) -Wl,--oformat=binary
LIBS          = -lgcc
DEPS          = $(ALLHFILES) Makefile
SDIRS         = $(shell cd $(CSD) && find . -type d 2>/dev/null)

%.o:%.c $(DEPS)
	$(CC) $(QCFLAGS) -Xassembler -I$(CSD) -D QUAFIOS_KERNEL -c -o $@ $<

$(OBJECT_NAME).bin: $(OBJ) $(LDSCRIPT)
	$(CC) $(BLFLAGS) -o $@ $(OBJ) $(LIBS)

$(OBJECT_NAME).elf: $(OBJ) $(LDSCRIPT)
	$(CC) $(KLFLAGS) -o $(OBJECT_NAME).elf $(OBJ) $(LIBS)

$(OBJECT_NAME).dump: $(OBJECT_NAME).elf
	objdump -D $< > $@

install-exec-local:
	$(INSTALL) -D $(OBJECT_NAME).bin $(OBJECT_PREFIX)/$(OBJECT_NAME).bin

uninstall-local:
	rm -f $(OBJECT_PREFIX)/$(OBJECT_NAME)
	- $(call REMOVE_EMPTY_DIR, $(prefix))

all-local: make-dirs $(OBJECT_NAME).bin $(OBJECT_NAME).dump

clean-local:
	rm -f $(OBJ) fonts/*.o $(OBJECT_NAME).*

make-dirs: $(SDIRS)
	@for i in $(SDIRS); do mkdir -p $$i; done
