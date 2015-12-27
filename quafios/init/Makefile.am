CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

OBJECT_NAME   = init
OBJECT_PREFIX = $(BIN_DIR)
LIBS          = -lc -lgcc
DEPS          = $(ALLHFILES) Makefile \
                $(GEN_INC_DIR)/kernel \
		$(GEN_INC_DIR)/libc \
		$(GEN_LIB_DIR)/libc

install-exec-local:
	$(INSTALL) -D $(CSD)/$(OBJECT_NAME) $(OBJECT_PREFIX)/$(OBJECT_NAME)

uninstall-local:
	rm -f $(OBJECT_PREFIX)/$(OBJECT_NAME)
	- $(call REMOVE_EMPTY_DIR, $(prefix))

all-local:

clean-local:
	rm -f $(OBJ)
