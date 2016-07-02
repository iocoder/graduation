CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

OBJECT_NAME   = libc
DEPS          = $(ALLHFILES) Makefile \
		$(KERNEL_INCLUDE)
SDIRS         = $(shell cd $(CSD) && find . -type d 2>/dev/null)

%.o:%.c $(DEPS)
	$(QCC) $(QCFLAGS) -c -o $@ $<

lib/$(OBJECT_NAME).a: $(OBJ)
	mkdir -p lib
	ar rcs $@ $^

install-exec-local:

uninstall-local:

all-local: make-dirs lib/$(OBJECT_NAME).a

clean-local:
	rm -f $(OBJ) lib/$(OBJECT_NAME).a
	rm -rf lib

make-dirs: $(SDIRS)
	@for i in $(SDIRS); do mkdir -p $$i; done
