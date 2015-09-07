CFILES=$(shell find $(abs_srcdir)/ -name "*.c"   2>/dev/null)
HFILES=$(shell find $(abs_srcdir)/ -name "*.h"   2>/dev/null)
CFLAGS=-shared -fPIC -I$(abs_srcdir)
OBJECT=vhdsim.so

all: $(OBJECT)

$(OBJECT): $(CFILES) $(HFILES)
	gcc $(CFILES) -o $@ $(CFLAGS) -lSDL

clean-local:
	rm -rf $(OBJECT)
