SUBDIRS=hardware firmware mipsemu

emu: all
	cd mipsemu && ./mipsemu ../firmware/firmware.bin

sim:
	make -C hardware simulation

dump:
	make -C firmware dump

clean-local:
	for i in $(SUBDIRS); do \
		rmdir --ignore-fail-on-non-empty $$i; \
	done;
