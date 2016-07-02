CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

OBJECT_NAME   = edit
OBJECT_PREFIX = $(BIN_DIR)
LIBS          = -lc -lgcc
DEPS          = $(ALLHFILES) Makefile \
                $(KERNEL_INCLUDE) \
		$(LIBC_INCLUDE) \
		$(LIBC_LIB)

%.o: %.c $(DEPS)
	$(QCC) $(QCFLAGS) -c -o $@ $<

edit: $(OBJ)
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $^ $(LIBS)

view: $(OBJ)
	$(QCC) $(QCFLAGS) $(QLFLAGS) -o $@ $^ $(LIBS)

install-exec-local:
	$(INSTALL) -D edit $(OBJECT_PREFIX)/edit
	$(INSTALL) -D view $(OBJECT_PREFIX)/view

uninstall-local:
	rm -f $(OBJECT_PREFIX)/edit
	rm -f $(OBJECT_PREFIX)/view
	- $(call REMOVE_EMPTY_DIR, $(prefix))

all-local: edit view

clean-local:
	rm -f $(OBJ) edit view
