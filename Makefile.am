SUBDIRS=logo quafios hardware firmware mipsemu vhdsim upload

prog:
	make -C quafios
	make -C logo
	make -C firmware
	make -C hardware
	make -C upload
	make -C quafios diskimg
	make -C upload prog
	make -C hardware prog

emu:
	make -C quafios diskimg
	make -C logo
	make -C firmware
	make -C mipsemu
	cd mipsemu && ./mipsemu ../firmware/firmware.bin ../quafios/disk.img

sim:
	make -C vhdsim
	make -C logo
	make -C firmware
	make -C hardware nvcsim

dump:
	make -C logo
	make -C firmware dump

clean-local:
	for i in $(SUBDIRS); do \
		rmdir --ignore-fail-on-non-empty $$i; \
	done;
