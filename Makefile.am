SUBDIRS=hardware firmware mipsemu vhdsim

emu:
	make -C firmware
	make -C mipsemu
	cd mipsemu && ./mipsemu ../firmware/firmware.bin

sim:
	make -C vhdsim
	make -C firmware
	make -C hardware nvcsim

prog:
	make -C firmware
	make -C hardware
	make -C ../upload prog FILE=../build/firmware/firmware.bin \
		ADDR=0xC00000 SIZE=0x8000
	make -C hardware prog

dump:
	make -C firmware dump

clean-local:
	for i in $(SUBDIRS); do \
		rmdir --ignore-fail-on-non-empty $$i; \
	done;
