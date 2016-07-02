CSD=$(shell realpath $(top_srcdir)/$(subdir))
OBJ=$(shell cd $(CSD) && find ./ -name "*.c" 2>/dev/null | sed 's/\.c/\.o/g')
CFILES         = $(shell find $(CSD)/         -name "*.c" 2>/dev/null)
ALLHFILES      = $(shell find $(CSD)/         -name "*.h" 2>/dev/null)
HFILES         = $(shell find $(CSD)/include/ -name "*.h" 2>/dev/null)
AFILES         = $(shell find $(CSD)/lib/     -name "*.a" 2>/dev/null)
SFILES         = $(shell find $(CSD)/         -name "*.s" 2>/dev/null)

install-exec-local:
	##mkdir -p $(USR_DIR)/share
	##cp -r $(CSD)/fonts $(USR_DIR)/share/
	##cp -r $(CSD)/icons $(USR_DIR)/share/
	##cp -r $(CSD)/wallpapers $(USR_DIR)/share/
	mkdir -p $(HOME_DIR)
	cp $(CSD)/home/* $(HOME_DIR)/

uninstall-local:
	rm -rf $(USR_DIR)/share/
	rm -rf $(HOME_DIR)/

all-local: $(OBJECT_NAME)

clean-local:
	rm -f $(OBJ) $(OBJECT_NAME)
