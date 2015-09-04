SUBDIRS=hardware firmware mipsemu

emu: all
	cd mipsemu && ./mipsemu ../firmware/firmware.bin

sim:
	make -C hardware simulation

simcpu:
	make -C firmware
	make -C mipsemu
	mkdir -p hardware/_sim
	rm -f hardware/_sim/rom.bin
	printf "\xD6" >> hardware/_sim/rom.bin
	printf "\xC9" >> hardware/_sim/rom.bin
	printf "\xCA" >> hardware/_sim/rom.bin
	printf "\xD3" >> hardware/_sim/rom.bin
	printf "\xAB" >> hardware/_sim/rom.bin
	printf "\xA7" >> hardware/_sim/rom.bin
	printf "\xA8" >> hardware/_sim/rom.bin
	printf "\x0A" >> hardware/_sim/rom.bin
	cat firmware/firmware.bin >> hardware/_sim/rom.bin
	make -C hardware simulation TB=dtlc
	dd if=hardware/_sim/ram.bin of=hardware/_sim/ram.tr bs=8 skip=1
	mv hardware/_sim/ram.tr hardware/_sim/ram.bin
	mipsel-linux-gnu-as -mips1 hardware/_sim/vga.s -o hardware/_sim/vga.o
	mipsel-linux-gnu-ld -o hardware/_sim/vga.elf -Ttext 0 \
	    hardware/_sim/vga.o
	mipsel-linux-gnu-objcopy -O binary hardware/_sim/vga.elf \
	    hardware/_sim/vga.bin
	mipsemu/mipsemu hardware/_sim/vga.bin

dump:
	make -C firmware dump

clean-local:
	for i in $(SUBDIRS); do \
		rmdir --ignore-fail-on-non-empty $$i; \
	done;
