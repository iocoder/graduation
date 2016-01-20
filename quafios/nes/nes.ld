ENTRY(main)

SECTIONS {

	. = 0x80010000;
        base1 = .;
	.text   : {*(.entry) *(.text)}
	.rodata : {*(.rodata        )}
	.data   : {*(.data          )}
	base2 = .;
	.bss    : {*(.bss COMMON    )}

	__instr           = instr           - base1;
	__read_routines   = read_routines   - base1;
        __read2_routines  = read2_routines  - base1;
        __instr_routines  = instr_routines  - base1;
        __write_routines  = write_routines  - base1;
        __write2_routines = write2_routines - base1;
        __rom             = rom             - base1;
        __ram             = ram             - base2;
}
