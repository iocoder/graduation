CFILES=$(shell find $(abs_srcdir)/ -name "*.c"   2>/dev/null)
HFILES=$(shell find $(abs_srcdir)/ -name "*.h"   2>/dev/null)
CFLAGS=-I$(abs_srcdir)
OBJECT=mipsemu

all: $(OBJECT)

$(OBJECT): $(CFILES) $(HFILES)
	gcc -o $@ $(CFLAGS) $(CFILES) -lSDL

clean-local:
	rm -rf $(OBJECT) mem.img
