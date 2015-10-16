CC = gcc
INC = /usr/local/include/digilent/adept
LIBDIR = /usr/local/lib64/digilent/adept
CFLAGS = -O0 -I $(INC) -L $(LIBDIR) -ldmgr -ldepp

all: upload Makefile

upload: upload.c
	$(CC) -o upload $(CFLAGS) upload.c

prog: upload
	djtgcfg enum
	djtgcfg init -d Nexys2
	djtgcfg prog -d Nexys2 -i 0 -f nexys2bist.bit
	echo idle for 3 seconds...
	sleep 3
	./upload $(FILE) $(ADDR) $(SIZE)
	echo idle for 2 seconds...
	sleep 2

clean:
	rm -f upload
