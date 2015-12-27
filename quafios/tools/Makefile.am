CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

MKDISKFS_OBJ  = mkdiskfs
DEPS          = $(CFILES) $(ALLHFILES) Makefile \
                $(KERNEL_INCLUDE)

$(MKDISKFS_OBJ): $(DEPS)
	$(CC) -pedantic -o $@ $(CFILES)

install-exec-local:

uninstall-local:

all-local: $(MKDISKFS_OBJ)

clean-local:
	rm -f $(MKDISKFS_OBJ)
