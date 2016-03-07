CC = gcc
INC = /usr/local/include/digilent/adept
LIBDIR = /usr/local/lib64/digilent/adept
CFLAGS = -O0 -I $(INC) -L $(LIBDIR) -ldmgr -ldepp
CFILES = $(top_srcdir)/upload/upload.c
BITFILE = $(top_srcdir)/upload/nexys2bist.bit

all: upload Makefile

upload: $(CFILES)
	$(CC) -o upload $(CFLAGS) $(CFILES)

prog: upload
	djtgcfg enum
	djtgcfg init -d Nexys2
	djtgcfg prog -d Nexys2 -i 0 -f $(BITFILE)
	echo idle for 3 seconds...
	sleep 1
	./upload erase
	./upload ../firmware/firmware.bin 0xC00000 0x8000
	./upload ../quafios/disk.img 0x000000 0x80000

clean:
	rm -f upload
