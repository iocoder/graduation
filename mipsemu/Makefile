CFILES=$(shell find ./       -name "*.c"   2>/dev/null)
HFILES=$(shell find ./       -name "*.h"   2>/dev/null)
CFLAGS=
OBJECT=mipsemu

all: $(OBJECT)

$(OBJECT): $(CFILES) $(HFILES)
	gcc  -o $@ $(CFLAGS) *.c -lSDL

clean:
	rm -rf $(OBJECT) mem.img
