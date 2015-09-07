SUBDIRS=hardware firmware mipsemu vhdsim

emu:
	make -C firmware
	make -C mipsemu
	cd mipsemu && ./mipsemu ../firmware/firmware.bin

sim:
	make -C vhdsim
	make -C firmware
	make -C hardware nvcsim

dump:
	make -C firmware dump

clean-local:
	for i in $(SUBDIRS); do \
		rmdir --ignore-fail-on-non-empty $$i; \
	done;
