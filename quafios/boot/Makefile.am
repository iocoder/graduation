CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

OBJECT_NAME    = loader
OBJECT_PREFIX  = $(BOOT_DIR)
LOADER_LD      = $(CSD)/loader/loader.ld
LOADER_LFLAGS  = $(QLFLAGS) -Wl,-T$(LOADER_LD)
LOADER_SRC     = $(LOADER_OBJ) $(COMMON_OBJ)
LIBS           =
DEPS           = $(ALLHFILES) Makefile \
		 $(KERNEL_INCLUDE)

LOADER_OBJ = \
$(shell cd $(CSD) && find ./loader -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')

%.o: %.c $(DEPS)
	mkdir -p loader
	$(QCC) $(QCFLAGS) -c -o $@ $<

loader.bin: $(LOADER_SRC) $(LOADER_LD)
	$(QCC) $(QCFLAGS) $(LOADER_LFLAGS) -o loader.elf $(LOADER_SRC) $(LIBS)
	$(QOC) -O binary loader.elf $@

diskboot/mbr.o: diskboot/mbr.s Makefile
	mkdir -p diskboot
	$(QAS) --32 $< -o $@

mbr.bin: diskboot/mbr.o
	$(QLD) -m elf_i386 --oformat=binary -Ttext 0x0600 -e start $< -o $@

diskboot/vbr.o: diskboot/vbr.s Makefile
	mkdir -p diskboot
	$(QAS) --32 $< -o $@

vbr.bin: diskboot/vbr.o
	$(QLD) -m elf_i386 --oformat=binary -Ttext 0x7C00 -e start $< -o $@

install-exec-local:
	$(INSTALL) -D loader.bin $(OBJECT_PREFIX)/loader.bin

uninstall-local:
	rm -f $(OBJECT_PREFIX)/loader.bin
	- $(call REMOVE_EMPTY_DIR, $(prefix))

all-local: loader.bin # mbr.bin vbr.bin

clean-local:
	rm -f diskboot/mbr.o mbr.bin
	rm -f diskboot/vbr.o vbr.bin
	rm -f loader.elf
	rm -f loader.bin
	rm -f $(LOADER_OBJ)
