all:
	make -C firmware
	make -C mipsemu

emu: all
	cd mipsemu && ./mipsemu ../firmware/firmware.bin

dump:
	make -C firmware dump

clean:
	make -C firmware clean
	make -C mipsemu  clean
