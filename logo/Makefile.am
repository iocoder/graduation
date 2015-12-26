SCRIPT=$(abs_srcdir)/generate.py
CFLAGS=-shared -fPIC -I$(abs_srcdir)
PNGFILE=$(abs_srcdir)/logo.png
TXTFILE=logo.txt
BINFILE=logo.bin

all: $(BINFILE)

$(BINFILE): $(SCRIPT) $(PNGFILE)
	$(SCRIPT) $(PNGFILE) $(TXTFILE) $(BINFILE)

clean-local:
	rm -rf $(TXTFILE) $(BINFILE)
